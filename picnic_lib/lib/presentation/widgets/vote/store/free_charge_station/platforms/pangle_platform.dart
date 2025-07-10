// pangle_platform.dart

import 'dart:async';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/pangle_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:universal_io/io.dart';

/// Pangle 광고 플랫폼 구현
class PanglePlatform extends AdPlatform {
  Timer? _loadTimeoutTimer;
  bool _isInitialized = false;

  PanglePlatform(super.ref, super.context, super.id,
      [super.animationController]);

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
            type: DialogType.error);
      }
      rethrow;
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      PangleAds.setOnProfileRefreshNeeded(() {
        if (!isDisposed) {
          logInfo('사용자 프로필 새로고침 필요');
          commonUtils.refreshUserProfile();
        }
      });

      await initialize();
      await _loadAndShowAd();
    });
  }

  Future<void> _loadAndShowAd() async {
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
        logAdShowFailure('Pangle', e, 'rewarded', 'Pangle 광고 표시 실패', s);
        throw Exception('Pangle 광고 표시 실패');
      }
    } else {
      logAdLoadFailure(
          'Pangle', '광고 로드 실패', 'rewarded', '광고 로드 실패', StackTrace.current);
      // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
      stopAllAnimations();
    }
    endPerformanceLog('광고 로드');
  }

  Future<bool> _loadPangleAd() async {
    if (Environment.pangleIosRewardedVideoId == null ||
        Environment.pangleAndroidRewardedVideoId == null) {
      logAdLoadFailure(
          'Pangle', '광고 ID가 설정되지 않음', 'rewarded', '광고 ID가 설정되지 않음', null);
      return false;
    }

    try {
      final completer = Completer<bool>();

      _loadTimeoutTimer?.cancel();
      _loadTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          // 타임아웃은 no fill로 간주하므로 일반 로그만 남김
          logAdLoadFailure(
              'Pangle', '광고 로드 시간 초과', 'rewarded', '광고 로드 시간 초과', null);
          completer.complete(false);
        }
      });

      final result = await PangleAds.loadRewardedAd(
        Platform.isIOS
            ? Environment.pangleIosRewardedVideoId!
            : Environment.pangleAndroidRewardedVideoId!,
        supabase.auth.currentUser!.id,
      );

      _loadTimeoutTimer?.cancel();
      return result == true;
    } catch (e, s) {
      logAdLoadFailure('Pangle', e, 'rewarded', 'Pangle 광고 로드 실패', s);
      _loadTimeoutTimer?.cancel();
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
          type: DialogType.error);
    }
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = null;
    super.dispose();
  }
}
