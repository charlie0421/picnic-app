import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;

import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// GA4 전송 계층 추상화.
///
/// 이벤트 조립(파라미터 이름/대체값/길이 제한)과 실제 전송을 분리해, 테스트가
/// Firebase 없이도 "무엇이 어떤 이름으로 나갔는지"를 그대로 단언할 수 있게 한다.
///
/// ## 전송 성공 계약
///
/// 모든 메서드는 **실제로 전송됐을 때만 `true`** 를 돌려준다. no-op(Firebase
/// 미초기화)과 예외는 **실패다.** 성공을 참칭하면 안 된다.
///
/// 이 계약이 없던 동안 `no-op → false 아님 → 호출부가 '보냈다'로 기록` 이
/// 성립했고, 중복 방어 마커가 **보내지도 않은 거래를 영구히 차단**했다.
/// 매출 이벤트에서 이것은 곧 영구 누락이다. 호출부는 이 bool 을 반드시 보고
/// 마커를 남길지 결정한다 ([AnalyticsSendReservation]).
abstract class Ga4Sink {
  Future<bool> logEvent(String name, Map<String, Object> parameters);

  /// `purchase` 는 items 배열 때문에 일반 logEvent 로 보낼 수 없다.
  /// (GA4 파라미터 맵 값은 String/num 만 허용)
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  });

  Future<bool> setUserId(String? id);

  Future<bool> setUserProperty(String name, String? value);
}

/// Firebase Analytics 로 실제 전송하는 구현.
///
/// Firebase 미초기화 환경(단위 테스트, 초기화 실패 빌드)에서는 전송하지 않고
/// **`false`** 를 돌려준다 — 조용한 no-op 이 성공으로 읽히면 안 된다.
/// 예외는 앱을 죽이지 않도록 삼키되 **반드시 logger 로 남기고 `false`** 다.
class FirebaseGa4Sink implements Ga4Sink {
  const FirebaseGa4Sink();

  bool get _isReady {
    try {
      return firebase_core.Firebase.apps.isNotEmpty;
    } catch (e) {
      // Firebase 플러그인이 등록조차 되지 않은 환경.
      logger.w('Firebase 초기화 상태 확인 실패 — analytics no-op: $e');
      return false;
    }
  }

  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) async {
    if (!_isReady) return _notReady(name);
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
      return true;
    } catch (e, s) {
      logger.e('GA4 이벤트 전송 실패: $name $parameters',
          error: e, stackTrace: s);
      return false;
    }
  }

  /// 미초기화는 "보내지 않았다"다. 조용히 넘기지 않고 남긴다 — 이벤트가 왜
  /// 안 들어오는지 추적할 수 있어야 하고, 호출부는 마커를 남기면 안 된다.
  bool _notReady(String what) {
    logger.w('Firebase 미초기화 — GA4 전송하지 않음(실패로 취급): $what');
    return false;
  }

  @override
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) async {
    if (!_isReady) return _notReady('purchase(transactionId=$transactionId)');
    try {
      await FirebaseAnalytics.instance.logPurchase(
        transactionId: transactionId,
        currency: currency,
        value: value?.toDouble(),
        items: items
            .map(
              (item) => AnalyticsEventItem(
                itemId: item.resolvedItemId,
                itemName: item.resolvedItemName,
                parameters: item.toCustomParameters(),
              ),
            )
            .toList(),
      );
      return true;
    } catch (e, s) {
      logger.e('GA4 purchase 전송 실패: transactionId=$transactionId',
          error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<bool> setUserId(String? id) async {
    if (!_isReady) return _notReady('setUserId');
    try {
      await FirebaseAnalytics.instance.setUserId(id: id);
      return true;
    } catch (e, s) {
      logger.e('GA4 user_id 설정 실패', error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<bool> setUserProperty(String name, String? value) async {
    if (!_isReady) return _notReady('setUserProperty($name)');
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: name,
        value: value,
      );
      return true;
    } catch (e, s) {
      logger.e('GA4 사용자 속성 설정 실패: $name=$value', error: e, stackTrace: s);
      return false;
    }
  }
}

/// 전송된 이벤트를 메모리에 기록하는 테스트용 싱크.
///
/// [deliver] 를 `false` 로 두면 "Firebase 미초기화 / 전송 실패"를 흉내 낸다 —
/// 이벤트는 기록하지만 성공을 반환하지 않는다. `sendDelay` 는 전송이 오래
/// 걸리는(타임아웃 예산을 넘기는) 경로를 재현한다.
class RecordingGa4Sink implements Ga4Sink {
  RecordingGa4Sink({this.deliver = true, this.sendDelay});

  /// 실제 전송 성공 여부. 테스트 중에 바꿔도 된다.
  bool deliver;

  /// 각 전송이 완료되기까지의 지연.
  Duration? sendDelay;

  final List<RecordedGa4Event> events = <RecordedGa4Event>[];
  final List<RecordedGa4Purchase> purchases = <RecordedGa4Purchase>[];
  final List<String?> userIds = <String?>[];
  final Map<String, String?> userProperties = <String, String?>{};

  void clear() {
    events.clear();
    purchases.clear();
    userIds.clear();
    userProperties.clear();
  }

  RecordedGa4Event get last => events.last;

  Future<bool> _settle() async {
    final delay = sendDelay;
    if (delay != null) await Future<void>.delayed(delay);
    return deliver;
  }

  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) {
    events.add(RecordedGa4Event(name, parameters));
    return _settle();
  }

  @override
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) {
    purchases.add(
      RecordedGa4Purchase(
        transactionId: transactionId,
        currency: currency,
        value: value,
        items: items,
      ),
    );
    return _settle();
  }

  @override
  Future<bool> setUserId(String? id) {
    userIds.add(id);
    return _settle();
  }

  @override
  Future<bool> setUserProperty(String name, String? value) {
    userProperties[name] = value;
    return _settle();
  }
}

class RecordedGa4Event {
  const RecordedGa4Event(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;

  @override
  String toString() => 'RecordedGa4Event($name, $parameters)';
}

class RecordedGa4Purchase {
  const RecordedGa4Purchase({
    required this.transactionId,
    required this.currency,
    required this.value,
    required this.items,
  });

  final String? transactionId;
  final String? currency;
  final num? value;
  final List<Ga4PurchaseItem> items;
}
