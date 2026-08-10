import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/analytics/ga4_parameters.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// `earn_virtual_currency` 중복 발송을 막기 위한 **영속** 마커.
///
/// ## 왜 프로세스 메모리로는 부족한가
///
/// `AdRewardDialogHost` 는 적립 확정(`AdRewardState.granted`)을 확인한 시점에
/// 이벤트를 보내고, 그 뒤에 다이얼로그 표시 → 첫 프레임 ACK 를 시도한다.
/// ACK 가 실패하면 `AdRewardRecovery.discardDialog` 가 큐에서만 빼고
/// **영속 레코드는 남긴다** (의도된 동작 — 스스로 "a genuinely un-acknowledged
/// reward is re-polled and re-queued by the next recovery attempt" 라고 적고
/// 있다). 앱을 껐다 켜면 `recover()` 가 서버의 `listUnacknowledged` 와 로컬
/// `pendingDisplay` 레코드에서 같은 reference 를 다시 큐에 넣고, 위젯 메모리의
/// `Set` 은 새 프로세스에서 비어 있으므로 같은 적립이 두 번 집계된다.
/// ACK 완료 직전에 앱이 죽는 경로도 결과가 같다.
///
/// ## production은 durable outbox가 전송 수명을 소유한다
///
/// 예전 `markIfFirst` 는 **보내기 전에** 마커를 영속화했다. sink 가 조용히
/// no-op 하거나 던지면 "보내지 않았는데 보냈다고 기록"이 성립하고, 그 적립은
/// 다음 실행에서 영구히 차단됐다. production은 reference와 완성 payload를
/// outbox에 먼저 저장하고, 실제 전송은 위젯/ACK/프로세스 수명과 분리한다.
/// 아래 reserve/commit API는 rollout 중의 legacy 마커와 focused test seam을
/// 위한 호환 경로다.
///
/// 예약·마커 상태는 저장소 키 단위 전역이라 `AdRewardDialogHost` 가 두 개 떠
/// 있어도(위젯 재삽입, 중첩 네비게이터) 서로를 막는다. 갱신은
/// [AnalyticsMarkerMutex] 로 직렬화되어 서로 다른 적립 건이 동시에 들어와도
/// 한쪽 마커가 사라지지 않는다.
///
/// 저장소 읽기 실패와 sink 실패는 logger에 드러나며, outbox 저장이 확인되지
/// 않으면 성공을 반환하지 않는다.
class EarnAnalyticsStore {
  EarnAnalyticsStore({LocalStorage? storage, AnalyticsOutbox? outbox})
    : _markers = AnalyticsSendMarkerStore(
        storageKey: loggedKeysKey,
        maxTrackedEntries: maxTrackedKeys,
        storage: storage,
      ),
      _outbox = outbox ?? (storage == null ? AnalyticsOutbox.instance : null);

  final AnalyticsSendMarkerStore _markers;
  final AnalyticsOutbox? _outbox;

  static const String loggedKeysKey = 'analytics_earn_logged_reward_keys';

  /// 기록해두는 적립 **건** 수 상한. 오래된 것부터 버린다.
  ///
  /// 광고 리워드는 사용자당 하루 몇 건 수준이고, 재큐잉은 ACK 실패 직후의
  /// 실행에서 일어난다. 100건이면 실사용 창을 충분히 덮으면서 키가 무한히
  /// 커지지 않는다. 적립 1건은 키 1개만 쓰므로 실효 추적 폭도 100건이다.
  static const int maxTrackedKeys = 100;

  /// 보내도 되면 예약을, 이미 보냈거나 다른 시도가 진행 중이면 `null` 을
  /// 돌려준다. 호출부는 전송 성공 뒤 `commit()`, 실패 시 `release()` 한다.
  Future<AnalyticsSendReservation?> reserve(String key) =>
      _markers.reserve(<String>[key]);

  /// 서버가 확정한 reward reference 기준으로 payload를 durable outbox에 넣는다.
  ///
  /// production은 outbox 저장까지만 기다리고 실제 Firebase 전송은 분리한다.
  /// 명시적 [storage]로 만든 인스턴스는 기존 widget 테스트 호환용으로만 marker
  /// 계약을 수행하며, 그 경로도 sink timeout과 finally release를 지킨다.
  Future<bool> enqueueEarn({
    required String reference,
    required String? virtualCurrencyName,
    required num? rewardAmount,
    required String? earnMethod,
    required String? sectionName,
    required String? adCategory,
    Duration sendTimeout = const Duration(seconds: 5),
  }) async {
    final parameters = Ga4Parameters.build(
      strings: <String, String?>{
        Ga4Param.virtualCurrencyName: virtualCurrencyName,
        Ga4Param.earnMethod: earnMethod,
        Ga4Param.sectionName: sectionName,
        Ga4Param.adCategory: adCategory,
      },
      numbers: <String, num?>{Ga4Param.rewardAmount: rewardAmount},
      eventNameForLog: Ga4Event.earnVirtualCurrency,
    );
    final outbox = _outbox;
    if (outbox != null) {
      final legacyReservation = await reserve(reference);
      if (legacyReservation == null) return true;
      try {
        final stored = await outbox.enqueue(
          AnalyticsOutboxEntry.event(
            kind: AnalyticsOutboxEventKind.earnVirtualCurrency,
            id: reference,
            parameters: parameters,
          ),
        );
        if (stored) unawaited(outbox.flush());
        return stored;
      } finally {
        legacyReservation.release();
      }
    }

    final reservation = await reserve(reference);
    if (reservation == null) return true;
    var delivered = false;
    try {
      delivered = await PicnicAnalytics.instance
          .logEarnVirtualCurrency(
            virtualCurrencyName: virtualCurrencyName,
            rewardAmount: rewardAmount,
            earnMethod: earnMethod,
            sectionName: sectionName,
            adCategory: adCategory,
          )
          .timeout(sendTimeout);
      if (!delivered) return false;
      return await reservation.commit();
    } on TimeoutException catch (e, s) {
      logger.e(
        'earn_virtual_currency sink timeout: $reference',
        error: e,
        stackTrace: s,
      );
      return false;
    } catch (e, s) {
      logger.e(
        'earn_virtual_currency sink 실패: $reference',
        error: e,
        stackTrace: s,
      );
      return false;
    } finally {
      if (!delivered) reservation.release();
    }
  }

  @visibleForTesting
  static void resetProcessCacheForTest() =>
      AnalyticsSendMarkerStore.resetProcessCacheForTest();
}
