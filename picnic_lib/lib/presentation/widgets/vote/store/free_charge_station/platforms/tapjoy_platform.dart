import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:picnic_lib/core/utils/tapjoy_session.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy 미션 플랫폼 구현
///
/// PICNIC-2682: 오퍼월을 요청하기 전에 SDK 가 Picnic UUID 를 사용자 ID 로 확인할
/// 때까지 기다린다. `Tapjoy.setUserID` 의 MethodChannel Future 는 네이티브 요청이
/// 나갔다는 뜻일 뿐이라(TapjoyOfferwallPlugin.kt:170), 그 상태에서 오퍼월을 열면
/// SDK 가 아직 들고 있는 기본 기기 ID 로 오퍼가 만들어지고 서버 콜백의 `snuid` 가
/// UUID 가 아니게 된다.
class TapjoyPlatform extends AdPlatform {
  /// 무료충전소 미션 오퍼월의 placement 이름.
  static const String placementName = 'mission';

  /// placement 채널 호출(getPlacement·requestContent·showContent)의 상한.
  /// 응답이 오지 않으면 세션의 직렬화 큐가 영구 pending 이 된다 (blocker-3).
  static const Duration dispatchTimeout = Duration(seconds: 15);

  Timer? _safetyTimer;
  bool _isInitialized = false;

  /// 늦게 도착한 placement 콜백이 **같은 인스턴스의** 지난 시도를 열지 못하게
  /// 막는다. 같은 이름의 placement 를 다시 잡는 경우는 이 토큰으로 막히지
  /// 않으므로 [TapjoyPlacementGate] 가 함께 필요하다.
  final TapjoyAttemptGuard _attemptGuard = TapjoyAttemptGuard();

  TapjoyPlatform(
    super.ref,
    super.context,
    super.id, [
    super.animationController,
  ]);

  @override
  Future<void> initialize() async {
    if (_isInitialized || isDisposed) return;
    _isInitialized = true;
    logInfo('초기화 완료');
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      _setupSafetyTimer();

      await runTapjoyOfferwall();
    }, isMission: true);
  }

  /// 오퍼월 본체 — [showAd] 의 로그인/로딩 래퍼 안에서만 실행된다.
  ///
  /// 세션이 connect 준비 → `setUserID` 성공 이벤트 → 계정 재확인까지 마친
  /// 뒤에만 placement 를 요청한다. 실패는 그대로 던져 `safelyExecute` 가
  /// 사용자에게 실패를 알리게 한다 — 여기서 삼키면 기기 ID 로 오퍼가 생성된다.
  ///
  /// 별도 메서드인 이유는 테스트 seam 이다. 이게 없으면 배선을 검증하려고
  /// 실제 Tapjoy SDK placement 를 세워야 하고, 결국 [TapjoySession] 만 단위
  /// 테스트하게 된다 — 그러면 `showAd()` 가 세션을 **거치지 않도록** 바뀌어도
  /// 테스트가 통과한다.
  @visibleForTesting
  Future<void> runTapjoyOfferwall() async {
    // 거절될 탭이 전역 SDK 사용자 ID 를 바꾸지 않도록, ID 동기화보다 게이트를
    // 먼저 본다. 최종 판정은 requestPlacement 의 tryEnter 가 한다 (blocker-2).
    if (TapjoyPlacementGate.isActive(placementName)) {
      logInfo('$placementName 오퍼월이 이미 열려 있어 중복 요청을 무시한다');
      stopAllAnimations();
      return;
    }
    await TapjoySession.instance.runOfferwall(requestPlacement);
  }

  /// 채널 예외가 "네이티브에 전달되지 않았다"는 **증거**인가.
  ///
  /// [MissingPluginException] 만 확실하다 — 플러그인이 없으면 요청이 네이티브에
  /// 도달할 수 없고 늦은 콜백도 오지 않는다. 그 밖의 채널 실패는 네이티브가
  /// 이미 요청을 실행한 뒤 응답 전달만 실패한 경우일 수 있으므로
  /// (TapjoyOfferwallPlugin.kt:374-378, .swift:449-452) 미전달의 증거가 아니다.
  static bool _isCertainlyUndelivered(Object error) =>
      error is MissingPluginException;

  void _setupSafetyTimer() {
    _safetyTimer?.cancel();
    // 애니메이션만 멈추는 표시용 타이머다. 인증 성공으로 간주하지 않는다.
    _safetyTimer = Timer(const Duration(seconds: 30), () {
      if (context.mounted && !isDisposed) {
        logWarning('안전장치: 애니메이션 중지');
        stopAllAnimations();
      }
    });
  }

  @visibleForTesting
  Future<void> requestPlacement(String userId) async {
    // SDK 는 placement 를 이름 하나로 캐시하고 getPlacement 마다 콜백을 통째로
    // 덮어쓴다. requestContent 의 채널 반환은 즉시라 세션 큐가 바로 풀리므로,
    // 활성 수명 동안은 앱 전역 게이트로 두 번째 요청을 막는다.
    if (!TapjoyPlacementGate.tryEnter(placementName, this)) {
      logInfo('$placementName 오퍼월이 이미 열려 있어 중복 요청을 무시한다');
      stopAllAnimations();
      return;
    }

    startPerformanceLog('플레이스먼트 요청');
    final attempt = _attemptGuard.begin();
    // 계정이 A→B→A 로 되돌아와도 이 시도가 되살아나지 않게 세대를 캡처한다.
    final authGeneration = TapjoySession.instance.authGeneration;

    // 게이트는 **네이티브 terminal 이벤트로만** 푼다. dispose 나 타이머로 풀면
    // 이 요청의 늦은 콜백이 새 owner 의 closure·토큰·Auth 를 통과해 남의 화면을
    // 연다(blocker-B). SDK 는 placement 이름 외에 correlation/cancel 을 주지
    // 않으므로 Dart 에서 안전한 조기 해제 방법이 없다.
    var released = false;
    void release() {
      if (released) return;
      released = true;
      TapjoyPlacementGate.exit(placementName, this);
    }

    /// 이 콜백이 아직 이번 시도·이번 계정의 것인가.
    bool isLive() =>
        _attemptGuard.isCurrent(attempt) &&
        !isDisposed &&
        context.mounted &&
        TapjoySession.instance.authGeneration == authGeneration &&
        TapjoySession.instance.currentUserId == userId;

    try {
      final placement = await _withDispatchTimeout(
        'getPlacement',
        () => TJPlacement.getPlacement(
          placementName: placementName,
          onRequestSuccess: (placement) async {
            logInfo('플레이스먼트 요청 성공');
            // 요청이 성공해도 내려줄 오퍼가 없을 수 있다(정상 no-fill). 그 경우
            // onContentReady·show·dismiss 가 오지 않으므로 여기가 이 요청의
            // terminal 이다. 패키지 예제(home_widget.dart:161)도 같은 분기를 쓴다.
            bool available;
            // 원 Future 를 따로 들고 있어야 상한을 넘긴 뒤 늦게 도착한 정상
            // 결과(no-fill)를 terminal 로 인정할 수 있다.
            final availability = placement.isContentAvailable();
            try {
              available = await availability.timeout(
                dispatchTimeout,
                onTimeout: () => throw TimeoutException(
                  'isContentAvailable',
                  dispatchTimeout,
                ),
              );
            } catch (error) {
              // 조회가 실패했을 뿐 "오퍼가 없다"는 증거는 아니다. 늦은
              // onContentReady 가 아직 올 수 있으므로 terminal 까지 격리한다.
              if (_isCertainlyUndelivered(error)) {
                logWarning('isContentAvailable 미전달 — 게이트를 놓는다', error: error);
                release();
              } else {
                logWarning(
                  'isContentAvailable 확인 실패 — terminal 까지 격리',
                  error: error,
                );
                // 늦게라도 no-fill 이 확정되면 그게 이 요청의 terminal 이다.
                unawaited(
                  availability.then<void>((late) {
                    if (late) return;
                    logWarning('늦게 도착한 no-fill 결과 — 게이트를 놓는다');
                    release();
                  }, onError: (Object _) {}),
                );
              }
              if (isLive()) _handleAdFailure('content_check_failed');
              return;
            }
            if (available) return;

            logInfo('표시할 오퍼가 없어 이 요청을 종료한다');
            release();
            if (isLive()) {
              _handleAdFailure('no_content');
            }
          },
          onRequestFailure: (placement, error) {
            release();
            if (!isLive()) return;
            logAdLoadFailure(
              'Tapjoy',
              error,
              placementName,
              error.toString(),
              StackTrace.current,
            );
            _handleAdFailure(error);
          },
          onContentReady: (placement) async {
            if (!isLive()) {
              // 화면이 사라졌거나 계정이 바뀐 뒤 도착한 준비 콜백. 이 요청의
              // 수명은 여기서 끝난다 — showContent 를 부르지 않는 한 show/dismiss
              // 는 오지 않으므로, 이 시점이 이 요청의 마지막 네이티브 이벤트다.
              logWarning('지난 시도의 콘텐츠 준비 콜백 — 표시하지 않고 게이트를 놓는다');
              release();
              return;
            }

            // 표시 직전 전역 SDK 사용자 ID 가 이 시도의 UUID 그대로인지 다시
            // 확인한다. 다른 탭이 ID 를 바꿔 놨다면 이 오퍼는 남의 것이 된다.
            bool matches;
            try {
              matches = await TapjoySession.instance.nativeUserIdMatches(
                userId,
              );
            } catch (error) {
              logWarning('표시 직전 사용자 ID 확인 실패 — 표시하지 않는다', error: error);
              matches = false;
            }
            if (!matches || !isLive()) {
              logWarning('표시 직전 SDK 사용자 ID 불일치 — 표시하지 않는다');
              release();
              // 계정 전환·dispose 로 이미 stale 이면 알릴 대상이 없다. 아직
              // 화면을 보고 있다면 실패를 전달해야 로딩이 안전 타이머까지
              // 남지 않는다. SDK 는 이 async 콜백의 Future 를 기다리지 않으므로
              // showAd 의 safelyExecute 로는 전파되지 않는다.
              if (isLive()) _handleAdFailure('user_id_mismatch');
              return;
            }

            logInfo('콘텐츠 준비 완료');
            try {
              await _withDispatchTimeout(
                'showContent',
                () => placement.showContent(),
              );
              stopAllAnimations();
            } catch (error) {
              if (_isCertainlyUndelivered(error)) {
                logWarning('showContent 미전달 — 게이트를 놓는다', error: error);
                release();
              } else {
                logWarning(
                  'showContent 전달 여부 불명 — terminal 까지 게이트 유지',
                  error: error,
                );
              }
              if (isLive()) _handleAdFailure('show_failed');
            }
          },
          onContentShow: (placement) {
            logInfo('콘텐츠 표시 시작');
          },
          onContentDismiss: (placement) {
            logInfo('콘텐츠 닫힘');
            release();
            if (context.mounted && !isDisposed) {
              stopAllAnimations();
              commonUtils.refreshUserProfile();
            }
            endPerformanceLog('플레이스먼트 요청');
          },
        ),
      );

      if (!isLive()) {
        logWarning('플레이스먼트 생성 사이에 시도가 무효화됨 — 요청하지 않음');
        release();
        return;
      }

      placement.setEntryPoint(TJEntryPoint.entryPointStore);
      await _withDispatchTimeout(
        'requestContent',
        () => placement.requestContent(),
      );
    } catch (error) {
      // 네이티브는 요청을 먼저 실행하고 응답을 나중에 돌려준다. 채널 실패나
      // timeout 은 "전달되지 않았다"는 증거가 아니므로, 확실한 미전달일 때만
      // 게이트를 놓고 나머지는 terminal 까지 격리한다 (blocker-1).
      if (_isCertainlyUndelivered(error)) {
        release();
      } else {
        logWarning('placement 요청 전달 여부 불명 — terminal 까지 게이트 유지', error: error);
      }
      rethrow;
    }
  }

  /// 채널 호출에 상한을 건다. 응답이 오지 않아도 세션의 직렬화 큐는 끝난다.
  Future<T> _withDispatchTimeout<T>(String name, Future<T> Function() call) =>
      call().timeout(
        dispatchTimeout,
        onTimeout: () => throw TimeoutException(name, dispatchTimeout),
      );

  void _handleAdFailure(String? error) {
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(
        content: AppLocalizations.of(context).label_ads_load_fail,
        type: DialogType.error,
      );
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logError('오류 발생', error: error, stackTrace: stackTrace);
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(
        content: AppLocalizations.of(context).label_ads_load_fail,
        type: DialogType.error,
      );
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    // placement 게이트는 여기서 놓지 않는다. 네이티브 요청이 아직 살아 있고
    // SDK 의 _placementMap['mission'] 에 이 인스턴스의 콜백이 그대로 걸려 있어,
    // 지금 놓으면 새 화면이 같은 placement 를 가져가 이 요청의 늦은 콜백을
    // 자기 것으로 받는다. 남은 콜백이 terminal 을 소비하며 스스로 놓는다.
    // 늦게 도착할 SDK 콜백이 이 화면을 되살리지 못하게 한다.
    _attemptGuard.cancel();
    super.dispose();
  }
}
