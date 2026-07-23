// pangle_platform.dart

import 'dart:async';
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
  });
  final PangleClaimCreator createClaim;
  final Future<void> Function(String, AdRewardReference) persist;
  final Stream<void> pollingSignals;
  final Future<void> Function(String, AdRewardReference) poll;
  final Future<bool> Function(String, String) load;
  final Duration loadTimeout;

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
      unawaited(poll(ownerUserId, claim.reference));
    });
    try {
      final loaded = await load(
        placementId,
        claim.mediaExtra(ownerUserId),
      ).timeout(loadTimeout, onTimeout: () => false);
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
    bool adLoadSuccess = await _loadPangleAd();
    if (!context.mounted || isDisposed) return;

    if (adLoadSuccess) {
      try {
        startPerformanceLog('광고 표시');
        await PangleAds.showRewardedAd();
        endPerformanceLog('광고 표시');
        stopAllAnimations();
      } catch (e, s) {
        logError(
          'Pangle 광고 표시 실패 상세:\n'
          '  error: $e\n'
          '  errorType: ${e.runtimeType}\n'
          '  adUnitId: $adUnitId',
        );
        logAdShowFailure('Pangle', e, adUnitId, 'Pangle 광고 표시 실패', s);
        throw Exception('Pangle 광고 표시 실패');
      }
    } else {
      logAdLoadFailure(
        'Pangle',
        '광고 로드 실패',
        adUnitId,
        '광고 로드 실패',
        StackTrace.current,
      );
      // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
      stopAllAnimations();
    }
    endPerformanceLog('광고 로드');
  }

  Future<bool> _loadPangleAd() async {
    if (Environment.pangleIosRewardedVideoId == null ||
        Environment.pangleAndroidRewardedVideoId == null) {
      logAdLoadFailure(
        'Pangle',
        '광고 ID가 설정되지 않음',
        'rewarded',
        '광고 ID가 설정되지 않음',
        null,
      );
      return false;
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
          ).execute(
            ownerUserId: ownerUserId,
            platform: platform,
            placementId: adUnitId,
            clientRequestId: const Uuid().v4(),
          );
      _activeReference = preflight.reference;
      _pollingSubscription = preflight.subscription;

      final result = preflight.loaded;

      return result == true;
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
      logAdLoadFailure('Pangle', e, failedAdUnitId, 'Pangle 광고 로드 실패', s);
      // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
      return false;
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
    unawaited(_pollingSubscription?.cancel());
    _pollingSubscription = null;
    if (_activeReference != null) {
      _activeReference = null;
    }
    super.dispose();
  }
}
