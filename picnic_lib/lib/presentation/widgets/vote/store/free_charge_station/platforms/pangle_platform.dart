// pangle_platform.dart

import 'dart:async';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

typedef PangleClaimCreator =
    Future<PangleClaimModel> Function({
      required String platform,
      required String placementId,
      required String clientRequestId,
    });

class PangleClaimPreflightResult {
  const PangleClaimPreflightResult({
    required this.loaded,
    required this.reference,
    required this.subscription,
  });
  final bool loaded;
  final AdRewardReference reference;
  final StreamSubscription<void> subscription;
}

class PangleClaimPreflight {
  const PangleClaimPreflight({
    required this.createClaim,
    required this.persist,
    required this.pollingSignals,
    required this.poll,
    required this.load,
    this.loadTimeout = const Duration(seconds: 5),
    this.onPollError,
    this.isAborted,
  });
  final PangleClaimCreator createClaim;
  final Future<void> Function(String, AdRewardReference) persist;
  final Stream<void> pollingSignals;
  final Future<void> Function(String, AdRewardReference) poll;
  final Future<bool> Function(String, String) load;
  final Duration loadTimeout;
  final void Function(Object error, StackTrace stackTrace)? onPollError;

  /// 호출부(플랫폼)가 dispose 됐는지 알려 주는 훅. 구독은 execute 내부에서
  /// 만들어지고 반환 후에야 호출부에 전달되므로, load 를 기다리는 사이에
  /// dispose 되면 호출부의 dispose 는 이 구독을 취소할 수 없다.
  final bool Function()? isAborted;

  Future<PangleClaimPreflightResult> execute({
    required String ownerUserId,
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) async {
    final claim = await createClaim(
      platform: platform,
      placementId: placementId,
      clientRequestId: clientRequestId,
    );
    await persist(ownerUserId, claim.reference);
    final subscription = pollingSignals.listen((_) {
      if (isAborted?.call() ?? false) return;
      // Future.sync: dispose 된 ref.read 처럼 poll 이 동기로 던지는 경우도
      // catchError 로 모은다 — 동기 throw 는 catchError 가 붙기 전에 전파된다.
      unawaited(
        Future.sync(() => poll(ownerUserId, claim.reference)).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          onPollError?.call(error, stackTrace);
        }),
      );
    });
    try {
      final loaded = await load(
        placementId,
        claim.mediaExtra(ownerUserId),
      ).timeout(loadTimeout, onTimeout: () => false);
      if (isAborted?.call() ?? false) {
        await subscription.cancel();
      }
      return PangleClaimPreflightResult(
        loaded: loaded,
        reference: claim.reference,
        subscription: subscription,
      );
    } catch (_) {
      await subscription.cancel();
      rethrow;
    }
  }
}

/// Pangle 광고 플랫폼 구현
class PanglePlatform extends AdPlatform {
  bool _isInitialized = false;
  StreamSubscription<void>? _pollingSubscription;
  AdRewardReference? _activeReference;

  /// `ad_impression` 용 1회성 구독. SDK 의 노출 콜백(`onAdShown`)은 브로드캐스트
  /// 스트림이라, 살려 두면 이후의 다른 시청 건까지 잡아 중복 발송된다.
  /// 첫 이벤트 · 표시 실패 · dispose · 다음 시청 시작 중 무엇이든 먼저 오면 끊고,
  /// 광고가 끝내 뜨지 않은 경우를 대비해 [_impressionListenTimeout] 로 자동 해제한다.
  StreamSubscription<void>? _impressionSubscription;
  Timer? _impressionTimeout;
  static const Duration _impressionListenTimeout = Duration(seconds: 30);

  PanglePlatform(
    super.ref,
    super.context,
    super.id, [
    super.animationController,
  ]);

  @override
  Future<void> initialize() async {
    if (_isInitialized || isDisposed) return;

    try {
      if (Environment.pangleIosAppId == null ||
          Environment.pangleAndroidAppId == null) {
        logWarning('앱 ID가 설정되지 않음');
        return;
      }

      startPerformanceLog('Pangle SDK 초기화');
      final initResult = await PangleAds.initPangle(
        Platform.isIOS
            ? Environment.pangleIosAppId!
            : Environment.pangleAndroidAppId!,
        environment: Environment.pangleEnvironment,
        productionAppId: Platform.isIOS
            ? Environment.productionPangleIosAppId
            : Environment.productionPangleAndroidAppId,
        sandboxPlacementId: Platform.isIOS
            ? Environment.pangleIosRewardedVideoId
            : Environment.pangleAndroidRewardedVideoId,
        productionPlacementId: Platform.isIOS
            ? Environment.productionPangleIosRewardedVideoId
            : Environment.productionPangleAndroidRewardedVideoId,
      );

      if (initResult != true) {
        throw Exception('Pangle SDK 초기화 실패');
      }

      _isInitialized = true;
      endPerformanceLog('Pangle SDK 초기화');
    } catch (e, s) {
      logError('초기화 실패', error: e, stackTrace: s);
      if (context.mounted && !isDisposed) {
        showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_sdk_init_fail,
          type: DialogType.error,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      await initialize();
      await _loadAndShowAd();
    });
  }

  Future<void> _loadAndShowAd() async {
    final adUnitId = Platform.isIOS
        ? (Environment.pangleIosRewardedVideoId ?? 'unknown')
        : (Environment.pangleAndroidRewardedVideoId ?? 'unknown');

    startPerformanceLog('광고 로드');
    final adLoad = await _loadPangleAd();
    if (!context.mounted || isDisposed) return;

    if (adLoad.loaded) {
      try {
        startPerformanceLog('광고 표시');
        // SDK 가 실제로 전체 화면 광고를 띄운 순간(onAdShown)에만 ad_impression 을
        // 보내기 위해, show 호출 직전에 1회성 구독을 건다. 로드 실패 경로는
        // 여기까지 오지 않으므로 실패 시 발송되지 않는다.
        _listenForImpressionOnce();
        final shown = await PangleAds.showRewardedAd();
        if (!shown) {
          // 표시 자체가 거부됐다 — 노출은 없었으므로 구독을 즉시 끊어
          // 다음 시청 건의 onAdShown 을 잘못 집계하지 않게 한다.
          _cancelImpressionListener();
        }
        endPerformanceLog('광고 표시');
        stopAllAnimations();
      } catch (e, s) {
        _cancelImpressionListener();
        logError(
          'Pangle 광고 표시 실패 상세:\n'
          '  error: $e\n'
          '  errorType: ${e.runtimeType}\n'
          '  adUnitId: $adUnitId',
        );
        logAdShowFailure('Pangle', e, adUnitId, 'Pangle 광고 표시 실패', s);
        throw Exception('Pangle 광고 표시 실패');
      }
    } else if (!adLoad.reported) {
      // 예외 없이 loaded=false 로 돌아온 경우에만 여기 온다 — 말 그대로 "지금
      // 보여줄 광고가 없는" 상태이므로 no-fill 로 분류되는 라벨을 의도적으로
      // 넘긴다("모든 광고 소진" 안내 + Sentry 보고 생략).
      //
      // reported=true 인 경로(광고 ID 미설정, 로드 예외)는 _loadPangleAd 가 이미
      // 실제 에러로 로깅·안내했다. 여기서 또 남기면 한 번의 실패에 다이얼로그가
      // 두 번 뜬다. 그 라벨을 예외 경로에 쓰면 진짜 버그까지 no-fill 로 삼켜진다.
      logAdLoadFailure(
        'Pangle',
        '광고 로드 실패',
        adUnitId,
        '광고 로드 실패',
        StackTrace.current,
      );
      stopAllAnimations();
    } else {
      stopAllAnimations();
    }
    endPerformanceLog('광고 로드');
  }

  /// `ad_impression` (스펙 §2-6) 을 SDK 노출 콜백 1회에만 발송한다.
  void _listenForImpressionOnce() {
    _cancelImpressionListener();
    final ga4 = ga4AdContext;
    if (ga4 == null) return; // 구좌 컨텍스트 없이 임의값으로 보내지 않는다.

    _impressionSubscription = PangleAds.onAdShown.listen((_) {
      _cancelImpressionListener();
      unawaited(
        PicnicAnalytics.instance.logAdImpression(
          adPlatform: ga4.adPlatform,
          adSource: ga4.adSource,
          adFormat: ga4.adFormat,
          adUnitName: ga4.adUnitName,
          sectionName: ga4.sectionName,
          adCategory: ga4.adCategory,
          virtualCurrencyName: ga4.virtualCurrencyName,
          rewardAmount: ga4.rewardAmount,
        ),
      );
    });
    _impressionTimeout = Timer(
      _impressionListenTimeout,
      _cancelImpressionListener,
    );
  }

  void _cancelImpressionListener() {
    _impressionTimeout?.cancel();
    _impressionTimeout = null;
    unawaited(_impressionSubscription?.cancel());
    _impressionSubscription = null;
  }

  /// 광고 로드 시도 결과.
  ///
  /// [reported] 는 **이 함수가 이미 실패를 로깅하고 사용자에게 안내했다**는 뜻이다.
  /// 호출부가 이걸 보지 않고 무조건 자기 실패 로그를 남기면 한 번의 실패에
  /// 다이얼로그가 두 번 뜬다(예: 예외 경로에서 오류 다이얼로그 + "모든 광고 소진").
  Future<({bool loaded, bool reported})> _loadPangleAd() async {
    if (Environment.pangleIosRewardedVideoId == null ||
        Environment.pangleAndroidRewardedVideoId == null) {
      logAdLoadFailure(
        'Pangle',
        '광고 ID가 설정되지 않음',
        'rewarded',
        '광고 ID가 설정되지 않음',
        null,
      );
      return (loaded: false, reported: true);
    }

    try {
      final adUnitId = Platform.isIOS
          ? Environment.pangleIosRewardedVideoId!
          : Environment.pangleAndroidRewardedVideoId!;

      final adRewardRepository = ref.read(adRewardRepositoryProvider);
      final pendingStore = ref.read(pendingAdRewardStoreProvider);
      final ownerUserId =
          supabase.auth.currentUser?.id ??
          (throw StateError('Authenticated user required for Pangle claim'));
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _pollingSubscription?.cancel();
      final preflight =
          await PangleClaimPreflight(
            createClaim: adRewardRepository.createPangleClaim,
            persist: pendingStore.add,
            pollingSignals: PangleAds.pollingSignals,
            poll: (owner, reference) => ref
                .read(adRewardRecoveryProvider.notifier)
                .poll(ownerUserId: owner, reference: reference),
            load: PangleAds.loadRewardedAd,
            onPollError: (error, stackTrace) {
              logError(
                'Pangle reward polling failed',
                error: error,
                stackTrace: stackTrace,
              );
            },
            isAborted: () => isDisposed,
          ).execute(
            ownerUserId: ownerUserId,
            platform: platform,
            placementId: adUnitId,
            clientRequestId: const Uuid().v4(),
          );
      _activeReference = preflight.reference;
      _pollingSubscription = preflight.subscription;

      final result = preflight.loaded;

      // 예외 없이 여기까지 왔다면 '지금 보여줄 광고가 없다'는 정상 응답이다.
      // 안내는 호출부가 no-fill 로 처리한다.
      return (loaded: result == true, reported: false);
    } catch (e, s) {
      final failedAdUnitId = Platform.isIOS
          ? (Environment.pangleIosRewardedVideoId ?? 'unknown')
          : (Environment.pangleAndroidRewardedVideoId ?? 'unknown');
      logError(
        'Pangle 광고 로드 실패 상세:\n'
        '  error: $e\n'
        '  errorType: ${e.runtimeType}\n'
        '  adUnitId: $failedAdUnitId',
      );
      // 분류 근거로 **실제 예외 텍스트**를 넘긴다. 예전엔 'Pangle 광고 로드 실패'
      // 라는 일반 라벨을 넘겼는데, 이 문자열이 no-fill 키워드('광고 로드 실패')에
      // 걸려 SDK 초기화 실패·설정 오류·플레이스먼트 문제까지 전부 "모든 광고
      // 소진"으로 표시되고 Sentry 보고도 막혔다. 진짜 no-fill/네트워크 예외는
      // 자기 텍스트('no fill', 'network error' 등)로 여전히 걸러진다.
      logAdLoadFailure('Pangle', e, failedAdUnitId, e.toString(), s);
      return (loaded: false, reported: true);
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
    _cancelImpressionListener();
    unawaited(_pollingSubscription?.cancel());
    _pollingSubscription = null;
    if (_activeReference != null) {
      _activeReference = null;
    }
    super.dispose();
  }
}
