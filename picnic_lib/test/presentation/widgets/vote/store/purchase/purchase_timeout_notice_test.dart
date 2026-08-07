import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_timeout_notice.dart';

/// 90초 안전망 타임아웃 문구 분기 (Android 결제창 방치 케이스).
///
/// 실제 스토어 플러그인 채널·Play 결제 시트까지 위젯 테스트로 재현하기는
/// 어렵다는 것이 기존 핸드오프의 결론이므로, 여기서는
/// (1) 문구를 고르는 순수 함수 [resolvePurchaseTimeoutNotice] 의 전 조합,
/// (2) production 이 쓰는 [PurchaseLaunchLifecycleTracker] 의 상품별 관찰,
/// (3) PurchaseSafetyManager 의 상품별 타이머 → onTimeoutUIReset(productId)
///     → tracker 조회로 이어지는 배선에서, 서로 다른 상품의 시도가 공존할 때
///     각 시도가 자기 관찰값으로 문구를 고르는지 (다중 시도 귀속 회귀)
/// 를 검증한다.
void main() {
  group('resolvePurchaseTimeoutNotice', () {
    test('Android: 런치 후 resumed 이벤트가 없고 앱이 전면도 아니면 미확정 문구', () {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.detached,
        null,
      ]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: false,
            resumedSincePurchaseLaunch: false,
            currentLifecycleState: state,
          ),
          PurchaseTimeoutNotice.paymentUnconfirmed,
          reason: 'lifecycleState=$state 는 결제 시트 안일 수 있다',
        );
      }
    });

    test('Android: resumed 이벤트가 한 번이라도 있었으면 기존 접수 문구 유지', () {
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.paused,
        null,
      ]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: false,
            resumedSincePurchaseLaunch: true,
            currentLifecycleState: state,
          ),
          PurchaseTimeoutNotice.paymentAccepted,
          reason: '시트를 닫고 나온 사용자는 정산 대기 안내를 받아야 한다',
        );
      }
    });

    test('Android: resumed 이벤트를 놓쳤어도 지금 전면이면 기존 접수 문구 유지', () {
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.resumed,
        ),
        PurchaseTimeoutNotice.paymentAccepted,
      );
    });

    test('사실상 취소(취소 관측 + 증거 없음 + 시트 닫힘)는 플랫폼 무관하게 팝업을 생략한다', () {
      for (final isIOS in [true, false]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: isIOS,
            resumedSincePurchaseLaunch: true,
            currentLifecycleState: AppLifecycleState.resumed,
            identitylessCancellationObserved: true,
            purchaseEvidenceObserved: false,
          ),
          PurchaseTimeoutNotice.suppressed,
          reason: '취소했고 구매 흔적이 0이면 접수 안내는 무의미하다 (isIOS=$isIOS)',
        );
      }
    });

    test('resumed 이벤트를 놓쳤어도 현재 전면이면 시트 닫힘으로 인정한다 (Sol 2차 MEDIUM-1)', () {
      // iOS 는 resumed 이벤트가 purchase() 반환(=recordLaunch)보다 먼저
      // 지나가 관찰이 false 로 남을 수 있다. 타임아웃 시점에 앱이 전면이면
      // 시트는 확실히 닫혀 있으므로 취소 억제가 동작해야 한다.
      for (final isIOS in [true, false]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: isIOS,
            resumedSincePurchaseLaunch: false,
            currentLifecycleState: AppLifecycleState.resumed,
            identitylessCancellationObserved: true,
            purchaseEvidenceObserved: false,
          ),
          PurchaseTimeoutNotice.suppressed,
          reason: 'isIOS=$isIOS',
        );
      }
    });

    test('시트가 닫힌 적 없는(방치) 시도는 취소가 관측돼도 생략하지 않는다', () {
      // 진짜 사용자 취소는 항상 시트가 닫힌 뒤다. resumed 없는 시도에 대한
      // 취소 관측은 다른 시도의 것일 수밖에 없으므로 생략 근거가 아니다.
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.paused,
          identitylessCancellationObserved: true,
          purchaseEvidenceObserved: false,
        ),
        PurchaseTimeoutNotice.paymentUnconfirmed,
      );
    });

    test('구매 증거가 하나라도 있으면 취소가 관측돼도 팝업을 생략하지 않는다', () {
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: true,
          resumedSincePurchaseLaunch: true,
          currentLifecycleState: AppLifecycleState.resumed,
          identitylessCancellationObserved: true,
          purchaseEvidenceObserved: true,
        ),
        PurchaseTimeoutNotice.paymentAccepted,
        reason: '증거가 있는 시도의 팝업은 이중 결제 안전장치라 유지해야 한다',
      );
      // Android 에서 증거는 있는데 아직 시트 안이면(카드 승인 지연 등)
      // 미확정 문구가 맞다.
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.paused,
          identitylessCancellationObserved: true,
          purchaseEvidenceObserved: true,
        ),
        PurchaseTimeoutNotice.paymentUnconfirmed,
      );
    });

    test('취소 관측이 없으면 구매 증거가 없어도 팝업은 유지된다', () {
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: true,
          resumedSincePurchaseLaunch: true,
          currentLifecycleState: AppLifecycleState.resumed,
          identitylessCancellationObserved: false,
          purchaseEvidenceObserved: false,
        ),
        PurchaseTimeoutNotice.paymentAccepted,
        reason: '이벤트가 아무것도 안 온 경우는 취소 확신이 없다 - 안전 기본값 유지',
      );
    });

    test('iOS: 어떤 조합에서도 기존 접수 문구를 유지한다 (회귀 금지)', () {
      for (final resumed in [true, false]) {
        for (final state in [
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
          AppLifecycleState.paused,
          null,
        ]) {
          expect(
            resolvePurchaseTimeoutNotice(
              isIOS: true,
              resumedSincePurchaseLaunch: resumed,
              currentLifecycleState: state,
            ),
            PurchaseTimeoutNotice.paymentAccepted,
            reason: 'iOS 는 SK2 블로킹 반환이라 이 분기가 동작하면 안 된다 '
                '(resumed=$resumed, state=$state)',
          );
        }
      }
    });
  });

  /// 정리 후보 판정 전용 술어. 90초 문구 판정([isPurchaseSheetClosed])과
  /// 갈라진 이유는 런치 직후의 창이다 - Android `buyConsumable` 은 Play 결제
  /// Activity 가 전면에 오기 전에 반환하므로, 그 순간의 resumed 를 "닫힘"으로
  /// 읽으면 결제 시트 안 사용자의 시도가 지워진다 (Sol 4차 재검증 MAJOR).
  group('isPurchaseSheetProvenClosed', () {
    test('전이를 본 적 없으면 지금 전면이어도 닫힘이 아니다 (4차 반례)', () {
      expect(
        isPurchaseSheetProvenClosed(
          leftForegroundSincePurchaseLaunch: false,
          returnedToForegroundSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.resumed,
        ),
        isFalse,
      );
    });

    test('나갔지만 아직 안 돌아왔으면 닫힘이 아니다 - 사용자가 시트 안에 있다', () {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.detached,
        null,
      ]) {
        expect(
          isPurchaseSheetProvenClosed(
            leftForegroundSincePurchaseLaunch: true,
            returnedToForegroundSincePurchaseLaunch: false,
            currentLifecycleState: state,
          ),
          isFalse,
          reason: 'lifecycleState=$state',
        );
      }
    });

    test('나갔다가 돌아왔으면 이후 상태와 무관하게 닫힘이다', () {
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.paused,
        null,
      ]) {
        expect(
          isPurchaseSheetProvenClosed(
            leftForegroundSincePurchaseLaunch: true,
            returnedToForegroundSincePurchaseLaunch: true,
            currentLifecycleState: state,
          ),
          isTrue,
          reason: '시트는 이미 닫혔다 - 그 뒤의 백그라운드 전환은 무관하다',
        );
      }
    });

    test('resumed 이벤트를 놓쳤어도 나간 적이 있고 지금 전면이면 닫힘이다', () {
      expect(
        isPurchaseSheetProvenClosed(
          leftForegroundSincePurchaseLaunch: true,
          returnedToForegroundSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.resumed,
        ),
        isTrue,
      );
    });
  });

  group('PurchaseLaunchLifecycleTracker', () {
    test('런치 기록이 없는 상품과 null(전역 타이머)은 접수 문구 쪽으로 판정된다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      expect(tracker.resumedSinceLaunch(null), isTrue);
      expect(tracker.resumedSinceLaunch('UNKNOWN'), isTrue);
    });

    test('런치 → resumed 순서를 상품별로 기록한다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('STAR100'), isFalse);

      tracker.recordResumed();
      expect(tracker.resumedSinceLaunch('STAR100'), isTrue);

      // 같은 상품의 새 런치는 관찰을 다시 시작한다.
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('STAR100'), isFalse);
    });

    test('다른 상품의 런치가 이전 시도의 이력을 덮지 않는다 (Sol 리뷰 회귀)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      // A 런치 → 사용자가 A 시트를 닫고 나옴 (resumed).
      tracker.recordLaunch('STAR100');
      tracker.recordResumed();
      // A 의 시도·타이머가 남은 상태에서 B 런치 → B 시트 방치.
      tracker.recordLaunch('STAR200');

      expect(tracker.resumedSinceLaunch('STAR100'), isTrue,
          reason: 'A 는 시트를 닫고 나왔으므로 접수 문구를 받아야 한다');
      expect(tracker.resumedSinceLaunch('STAR200'), isFalse,
          reason: 'B 는 아직 시트 안일 수 있으므로 미확정 문구를 받아야 한다');
    });

    test('식별자 없는 취소는 활성 관찰이 하나일 때만 기록된다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      tracker.recordIdentitylessCancellation();
      expect(
        tracker.observationFor('STAR100').identitylessCancellationObserved,
        isTrue,
        reason: '단독 시도의 취소는 그 시도의 것으로 볼 수 있다',
      );
    });

    test('시도가 둘 이상이면 식별자 없는 취소를 어느 쪽에도 기록하지 않는다 (경고 보존)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      // A 는 실결제 진행 중(이벤트 지연으로 증거 아직 없음), B 는 취소됨.
      tracker.recordLaunch('STAR100');
      tracker.recordLaunch('STAR200');
      tracker.recordResumed();
      tracker.recordIdentitylessCancellation();

      expect(
        tracker.observationFor('STAR100').identitylessCancellationObserved,
        isFalse,
        reason: 'B 의 취소가 A(실결제, 이벤트 지연)의 이중 결제 경고를 지우면 안 된다',
      );
      expect(
        tracker.observationFor('STAR200').identitylessCancellationObserved,
        isFalse,
        reason: '귀속 불가 - 취소한 쪽도 팝업이 한 번 더 보일 뿐(현상 유지)',
      );
    });

    test('별칭 키는 하나의 관찰로 세므로 단독 시도 판정을 깨지 않는다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100', storeAliases: ['PICNICSTAR100']);
      tracker.recordIdentitylessCancellation();
      expect(
        tracker.observationFor('STAR100').identitylessCancellationObserved,
        isTrue,
        reason: '별칭 2개 키가 같은 관찰 객체이므로 활성 관찰은 여전히 1개다',
      );
    });

    test('구매 증거는 해당 상품에만 기록된다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      tracker.recordLaunch('STAR200');
      tracker.recordPurchaseEvidence('STAR100');

      expect(tracker.observationFor('STAR100').purchaseEvidenceObserved, isTrue);
      expect(tracker.observationFor('STAR200').purchaseEvidenceObserved, isFalse);
    });

    test('런치 기록이 없는 상품의 관찰값은 보수적이다 (생략·미확정 트리거 금지)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordIdentitylessCancellation();

      final unknown = tracker.observationFor('UNKNOWN');
      expect(unknown.resumedSinceLaunch, isTrue);
      expect(unknown.purchaseEvidenceObserved, isTrue);
      expect(unknown.identitylessCancellationObserved, isFalse);

      final global = tracker.observationFor(null);
      expect(global.identitylessCancellationObserved, isFalse);
    });

    test('런치 확정 전에 도착한 구매 증거는 latch 됐다가 런치에 병합된다 (Sol 2차 HIGH-2)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      // purchased 이벤트가 런치 확정보다 먼저 도착하는 레이스
      // (bindWithLaunchGrace 가 흡수하는 것과 동일).
      tracker.recordPurchaseEvidence('STAR100');
      tracker.recordLaunch('STAR100');
      tracker.recordIdentitylessCancellation();
      tracker.recordResumed();

      expect(
        tracker.observationFor('STAR100').purchaseEvidenceObserved,
        isTrue,
        reason: '실결제 증거가 런치 리셋에 지워지면 팝업이 잘못 생략된다',
      );
    });

    test('스토어 별칭 ID 로 도착한 증거가 서버 ID 시도로 모인다 (Sol 2차 HIGH-3)', () {
      final tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      // iOS: 이벤트가 앱 접두사 붙은 스토어 ID 로 도착.
      tracker.recordLaunch('STAR100', storeAliases: ['PICNICSTAR100']);
      tracker.recordPurchaseEvidence('picnicSTAR100');
      expect(tracker.observationFor('STAR100').purchaseEvidenceObserved, isTrue);
      tracker.clear('STAR100');
      expect(
        tracker.observationFor('PICNICSTAR100').purchaseEvidenceObserved,
        isTrue,
        reason: 'clear 는 별칭 키까지 정리해 보수적 기본값으로 돌아가야 한다',
      );

      // Android dev: 네임스페이스 SKU 로 도착.
      tracker.recordLaunch('STAR100', storeAliases: ['staging.star100']);
      tracker.recordPurchaseEvidence('STAGING.STAR100');
      expect(tracker.observationFor('star100').purchaseEvidenceObserved, isTrue);
    });

    test('시도 없는 이벤트는 latch 하지 않는다 - production 게이트 재현 (Sol 2차 MEDIUM-2)', () {
      final tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      final registry = PurchaseCampaignAttemptRegistry();
      // purchase_star_candy_state.dart 의 증거 관찰 게이트와 동일한 조건
      // (스토어 표기 역해석 포함).
      void observeEvidence(
        String productId, {
        String iosAppPrefix = '',
        String androidNamespace = '',
      }) {
        final matches =
            tracker.hasObservation(productId) ||
            serverProductIdCandidatesForStoreEvent(
              productId,
              iosAppPrefix: iosAppPrefix,
              androidNamespace: androidNamespace,
            ).any(registry.contains);
        if (matches) {
          tracker.recordPurchaseEvidence(productId);
        }
      }

      // 초기화 정리/재전달로 도착한 restored - 활성 시도 없음 → 관찰 금지.
      observeEvidence('STAR100');

      // 이후 정상 시도: latch 오염이 없어야 취소 억제가 동작한다.
      tracker.recordLaunch('STAR100');
      tracker.recordResumed();
      tracker.recordIdentitylessCancellation();
      expect(
        tracker.observationFor('STAR100').purchaseEvidenceObserved,
        isFalse,
        reason: '과거 구매의 이벤트가 새 시도의 취소 억제를 무력화하면 안 된다',
      );

      // 활성 시도가 있는 이벤트-선행 레이스는 여전히 latch 된다 (HIGH-2).
      registry.begin(
        const PurchaseCampaignAttempt(
          attemptId: 'a2',
          productId: 'STAR200',
          displayedCampaign: null,
        ),
      );
      observeEvidence('star200');
      tracker.recordLaunch('STAR200');
      expect(
        tracker.observationFor('STAR200').purchaseEvidenceObserved,
        isTrue,
      );

      // 스토어 별칭 표기(iOS 접두사·Android 네임스페이스)로 도착한 이벤트도
      // 역해석으로 게이트를 통과해 latch 된다 (Sol 재검증2의 별칭 레이스).
      registry.begin(
        const PurchaseCampaignAttempt(
          attemptId: 'a3',
          productId: 'STAR300',
          displayedCampaign: null,
        ),
      );
      observeEvidence('PICNICSTAR300', iosAppPrefix: 'PICNIC');
      tracker.recordLaunch('STAR300', storeAliases: ['PICNICSTAR300']);
      expect(
        tracker.observationFor('STAR300').purchaseEvidenceObserved,
        isTrue,
        reason: 'iOS 접두사 표기의 런치 전 증거가 유실되면 안 된다',
      );

      registry.begin(
        const PurchaseCampaignAttempt(
          attemptId: 'a4',
          productId: 'STAR400',
          displayedCampaign: null,
        ),
      );
      observeEvidence('staging.star400', androidNamespace: 'staging.');
      tracker.recordLaunch('STAR400', storeAliases: ['staging.star400']);
      expect(
        tracker.observationFor('STAR400').purchaseEvidenceObserved,
        isTrue,
        reason: 'Android 네임스페이스 표기의 런치 전 증거가 유실되면 안 된다',
      );
    });

    test('serverProductIdCandidatesForStoreEvent 는 접두사/네임스페이스를 역해석한다', () {
      expect(
        serverProductIdCandidatesForStoreEvent(
          'PICNICSTAR100',
          iosAppPrefix: 'PICNIC',
          androidNamespace: '',
        ),
        containsAll(['PICNICSTAR100', 'STAR100']),
      );
      expect(
        serverProductIdCandidatesForStoreEvent(
          'staging.star100',
          iosAppPrefix: '',
          androidNamespace: 'STAGING.',
        ),
        containsAll(['staging.star100', 'star100']),
      );
      // 접두사 설정이 비어 있으면(현재 전 환경) 원본 그대로 하나뿐이다.
      expect(
        serverProductIdCandidatesForStoreEvent(
          'star100',
          iosAppPrefix: '',
          androidNamespace: '',
        ),
        ['star100'],
      );
      // 접두사와 동일한 문자열 자체는 후보를 만들지 않는다.
      expect(
        serverProductIdCandidatesForStoreEvent(
          'PICNIC',
          iosAppPrefix: 'PICNIC',
          androidNamespace: '',
        ),
        ['PICNIC'],
      );
    });

    test('새 런치는 이전 시도의 취소/증거 관찰을 초기화한다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      tracker.recordPurchaseEvidence('STAR100');
      tracker.recordIdentitylessCancellation();

      tracker.recordLaunch('STAR100');
      final observation = tracker.observationFor('STAR100');
      expect(observation.resumedSinceLaunch, isFalse);
      expect(observation.purchaseEvidenceObserved, isFalse);
      expect(observation.identitylessCancellationObserved, isFalse);
    });

    test('비전면 전이를 거친 뒤의 복귀만 "돌아왔다"로 센다 (Sol 4차 재검증)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');

      // 시트가 뜨기 전에 들어온 resumed - 닫힘의 증거가 아니다.
      tracker.recordResumed();
      var observation = tracker.observationFor('STAR100');
      expect(observation.resumedSinceLaunch, isTrue,
          reason: '90초 문구 판정이 쓰는 관찰값은 그대로 선다');
      expect(observation.leftForegroundSinceLaunch, isFalse);
      expect(observation.returnedToForegroundSinceLaunch, isFalse,
          reason: '나간 적이 없으니 돌아온 것도 아니다');

      // 시트가 떴다가 닫혔다.
      tracker.recordLeftForeground();
      observation = tracker.observationFor('STAR100');
      expect(observation.leftForegroundSinceLaunch, isTrue);
      expect(observation.returnedToForegroundSinceLaunch, isFalse);

      tracker.recordResumed();
      expect(
        tracker.observationFor('STAR100').returnedToForegroundSinceLaunch,
        isTrue,
      );
    });

    test('전이 순번을 런치 요청 시점부터 세면 런치 중 지나간 전이도 잡힌다 (iOS 블로킹 반환)',
        () {
      final tracker = PurchaseLaunchLifecycleTracker();
      final exitsAtLaunchStart = tracker.foregroundExitCount;

      // purchase() 가 도는 동안 시트가 떴다 닫힌다.
      tracker.recordLeftForeground();
      tracker.recordResumed();

      tracker.recordLaunch(
        'STAR100',
        foregroundExitsAtLaunchStart: exitsAtLaunchStart,
      );

      final observation = tracker.observationFor('STAR100');
      expect(observation.leftForegroundSinceLaunch, isTrue,
          reason: '런치 호출 중의 전이는 이 시도의 것이다');
      expect(observation.returnedToForegroundSinceLaunch, isFalse,
          reason: '복귀 이벤트는 관찰 생성 전에 지나갔다 - 현재 전면 상태가 이어받는다');
    });

    test('런치 요청 시점 이후 전이가 없으면 leftForeground 는 서지 않는다 (Android 즉시 반환)',
        () {
      final tracker = PurchaseLaunchLifecycleTracker();
      final exitsAtLaunchStart = tracker.foregroundExitCount;
      tracker.recordLaunch(
        'STAR100',
        foregroundExitsAtLaunchStart: exitsAtLaunchStart,
      );
      expect(
        tracker.observationFor('STAR100').leftForegroundSinceLaunch,
        isFalse,
      );
    });

    test('새 런치는 전이 관찰도 초기화한다 - 이전 시도의 닫힘이 새 시도로 새지 않는다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      tracker.recordLeftForeground();
      tracker.recordResumed();
      expect(
        tracker.observationFor('STAR100').returnedToForegroundSinceLaunch,
        isTrue,
      );

      final exits = tracker.foregroundExitCount;
      tracker.recordLaunch('STAR100', foregroundExitsAtLaunchStart: exits);
      final observation = tracker.observationFor('STAR100');
      expect(observation.leftForegroundSinceLaunch, isFalse);
      expect(observation.returnedToForegroundSinceLaunch, isFalse);
    });

    test('런치 관찰이 없는 상품은 정리 판정에서도 보수적 기본값(닫힘)이다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      final unknown = tracker.observationFor('UNKNOWN');
      expect(unknown.leftForegroundSinceLaunch, isTrue);
      expect(unknown.returnedToForegroundSinceLaunch, isTrue);
    });

    test('안전망 타이머와 같은 canonical 상품 키를 쓸 수 있다 (STAR100 vs star100)', () {
      final tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('star100'), isFalse);
      tracker.recordResumed();
      expect(tracker.resumedSinceLaunch('star100'), isTrue);
      tracker.clear('star100');
      expect(tracker.resumedSinceLaunch('STAR100'), isTrue);
    });
  });

  group('PurchaseSafetyManager onTimeoutUIReset(productId) 배선', () {
    late PurchaseSafetyManager manager;
    late PurchaseLaunchLifecycleTracker tracker;
    late Map<String, String> shownMessageKeyByProduct;
    late Future<PurchaseSweepReport?> Function() resolveStoreQueueSweep;

    setUp(() {
      tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      shownMessageKeyByProduct = {};
      // 기본값: 큐를 확인했고 애초에 비어 있었다.
      resolveStoreQueueSweep = () async => const PurchaseSweepReport(
            trigger: PurchaseSweepTrigger.manual,
            outcome: PurchaseSweepOutcome.completed,
          );
      manager = PurchaseSafetyManager(
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        resetPurchaseState: () {},
      );
      // purchase_star_candy_state.dart 의 onTimeoutUIReset 콜백과 동일한
      // 분기 구조: 타이머가 알려 준 productId → tracker 관찰값 → resolver
      // → (suppressed 면) 스토어 큐 실측 재확인. 큐가 비어 있음이 확인된
      // 경우에만 문구를 생략하고, 아니면 접수 경고를 유지한다.
      manager.onTimeoutUIReset = (productId) async {
        final observation = tracker.observationFor(productId);
        final notice = resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: observation.resumedSinceLaunch,
          // 방치 시나리오: 앱은 Play 시트 뒤에서 paused 상태다.
          currentLifecycleState: AppLifecycleState.paused,
          identitylessCancellationObserved:
              observation.identitylessCancellationObserved,
          purchaseEvidenceObserved: observation.purchaseEvidenceObserved,
        );
        tracker.clear(productId);
        if (notice == PurchaseTimeoutNotice.suppressed) {
          final report = await resolveStoreQueueSweep();
          // 프로덕션과 같은 술어를 쓴다 (PurchaseSweepReport.verifiedEmpty):
          // "확인했고 애초에 비어 있었다"만 생략 사유다.
          if (report?.verifiedEmpty ?? false) return;
          shownMessageKeyByProduct[productId ?? '<global>'] =
              'purchase_payment_accepted_message';
          return;
        }
        shownMessageKeyByProduct[productId ?? '<global>'] =
            notice == PurchaseTimeoutNotice.paymentUnconfirmed
                ? 'purchase_payment_unconfirmed_message'
                : 'purchase_payment_accepted_message';
      };
    });

    tearDown(() {
      manager.disposeSafetyTimer();
    });

    testWidgets('런치 후 resumed 없이 90초 경과 시 미확정 문구를 고른다', (tester) async {
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_unconfirmed_message',
      );
      expect(manager.isSafetyTimeoutTriggered, isTrue);
    });

    testWidgets('resumed 를 받은 시도는 90초 경과 시 기존 접수 문구를 고른다', (tester) async {
      tracker.recordLaunch('STAR100');
      tracker.recordResumed();
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
      );
    });

    testWidgets('타이머 공존 시 각 시도가 자기 관찰값으로 문구를 고른다 (Sol 리뷰 회귀)',
        (tester) async {
      // A 런치 → A 시트 닫고 나옴(resumed) → A 타이머는 식별자 없는
      // 취소로 정리되지 못하고 잔존 → B 런치 → B 시트 방치.
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-a');
      tracker.recordResumed();
      tracker.recordLaunch('STAR200');
      manager.startSafetyTimer(productId: 'STAR200', attemptId: 'attempt-b');

      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
        reason: 'A 는 시트를 닫고 나왔다 - B 의 런치가 A 의 이력을 덮으면 안 된다',
      );
      expect(
        shownMessageKeyByProduct['STAR200'],
        'purchase_payment_unconfirmed_message',
        reason: 'B 는 방치 상태다',
      );
    });

    testWidgets('사실상 취소(식별자 없는 취소 + 증거 없음)는 90초에 팝업이 뜨지 않는다',
        (tester) async {
      // 사용자가 시트에서 취소 → 취소 이벤트가 ID 없이 도착해 타이머는
      // 살아남고, resumed 로 복귀한 상태.
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      tracker.recordResumed();
      tracker.recordIdentitylessCancellation();

      await tester.pump(const Duration(seconds: 91));
      await tester.pump(); // 큐 재확인 비동기 완료 대기

      expect(shownMessageKeyByProduct, isEmpty,
          reason: '방금 취소한 사용자에게 "접수됐다" 안내는 무의미하다');
      expect(manager.isSafetyTimeoutTriggered, isTrue,
          reason: '타이머·상태 정리는 그대로 일어나야 한다 - 표시만 생략');
    });

    testWidgets(
        '이전 세대의 지연 취소가 잘못 기록돼도 큐에서 실결제가 발견되면 경고를 유지한다 '
        '(Sol 머지 게이트: 세대 교차, found=1/settled=1/preserved=0)', (tester) async {
      // A 시도 종료 → 같은 상품 B 재런치(유일 관찰) → A 의 지연된 식별자
      // 없는 취소 도착(B 에 기록됨) → B 는 실결제인데 이벤트가 90초 이상
      // 지연. 관찰만으로는 suppressed 로 판정되지만, 실결제라면 스토어
      // 큐에 미소비 트랜잭션이 남아 있으므로 실측 재확인이 경고를 지킨다.
      // 핵심: 스윕이 발견 즉시 정산에 **성공**해도(found=1, settled=1,
      // preserved=0) "애초에 비어 있었음"이 아니므로 생략하면 안 된다.
      resolveStoreQueueSweep = () async => const PurchaseSweepReport(
            trigger: PurchaseSweepTrigger.manual,
            outcome: PurchaseSweepOutcome.completed,
            found: 1,
            settled: 1,
          );

      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-b');
      tracker.recordResumed();
      tracker.recordIdentitylessCancellation(); // 사실은 이전 세대 A 의 취소

      await tester.pump(const Duration(seconds: 91));
      await tester.pump(); // 큐 재확인 비동기 완료 대기

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
        reason: '큐 미확인/잔존 시 이중 결제 경고가 유일한 안전장치다',
      );
    });

    testWidgets('취소가 관측돼도 구매 증거가 있으면 팝업(접수 문구)은 유지된다',
        (tester) async {
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      tracker.recordResumed();
      tracker.recordPurchaseEvidence('star100'); // 스토어 소문자 SKU 로 도착
      tracker.recordIdentitylessCancellation();

      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
        reason: '증거가 있는 시도의 팝업은 이중 결제 안전장치다',
      );
    });

    testWidgets(
        '비전면 전이 없이 받은 resumed 도 90초 분기에서는 그대로 시트 닫힘으로 센다 '
        '(정리 판정만 엄격해졌고 문구 판정은 불변 - Sol 4차 재검증)', (tester) async {
      // 정리 후보 판정은 이 관찰을 "닫힘 아님"으로 본다
      // (returnedToForegroundSinceLaunch == false). 문구 판정은 예전 그대로
      // resumedSinceLaunch 만 보므로 취소 억제가 계속 동작해야 한다.
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      tracker.recordResumed(); // 앞선 비전면 전이 없음
      tracker.recordIdentitylessCancellation();

      final observation = tracker.observationFor('STAR100');
      expect(observation.returnedToForegroundSinceLaunch, isFalse,
          reason: '두 판정이 실제로 갈라져 있는 상황임을 고정한다');

      await tester.pump(const Duration(seconds: 91));
      await tester.pump();

      expect(shownMessageKeyByProduct, isEmpty,
          reason: '어제 배포된 패치(#24~#29)의 취소 억제 동작이 그대로여야 한다');
    });

    testWidgets('타이머가 정상 중지되면 어떤 문구도 뜨지 않는다', (tester) async {
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      manager.stopSafetyTimer(productId: 'STAR100');
      await tester.pump(const Duration(seconds: 91));

      expect(shownMessageKeyByProduct, isEmpty);
    });
  });
}
