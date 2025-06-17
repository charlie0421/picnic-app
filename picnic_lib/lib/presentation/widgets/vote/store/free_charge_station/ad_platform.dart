import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 광고 플랫폼 추상 클래스
abstract class AdPlatform {
  final WidgetRef ref;
  final BuildContext context;
  final String id;
  final AnimationController? animationController;
  late final CommonUtils _commonUtils;
  bool _isDisposed = false;
  final Stopwatch _performanceStopwatch = Stopwatch();

  CommonUtils get commonUtils => _commonUtils;

  AdPlatform(this.ref, this.context, this.id, [this.animationController]) {
    _commonUtils = CommonUtils(ref, context);
  }

  // 로깅 유틸리티 메서드들
  void logInfo(String message, {String? tag}) {
    logger.i('[$id${tag != null ? ':$tag' : ''}] $message');
  }

  void logDebug(String message, {String? tag}) {
    logger.d('[$id${tag != null ? ':$tag' : ''}] $message');
  }

  void logWarning(String message, {String? tag, dynamic error}) {
    logger.w('[$id${tag != null ? ':$tag' : ''}] $message', error: error);
  }

  void logError(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    logger.e('[$id${tag != null ? ':$tag' : ''}] $message',
        error: error, stackTrace: stackTrace);
  }

  void startPerformanceLog(String operation) {
    _performanceStopwatch.reset();
    _performanceStopwatch.start();
    logDebug('$operation 시작');
  }

  void endPerformanceLog(String operation) {
    _performanceStopwatch.stop();
    logDebug('$operation 완료 (${_performanceStopwatch.elapsedMilliseconds}ms)');
  }

  Future<void> initialize();
  Future<void> showAd();
  Future<void> handleError(dynamic error, StackTrace? stackTrace);

  void dispose() {
    _isDisposed = true;
    stopAllAnimations();
    logger.i('[$id] 플랫폼 종료');
  }

  bool get isDisposed => _isDisposed;

  // 공통 로직: 로딩 상태 설정
  void setLoading(bool isLoading) {
    if (!context.mounted || isDisposed) return;
    ref.read(adLoadingStateProvider.notifier).setLoading(id, isLoading);
  }

  // 공통 로직: 로딩 UI 시작
  void startLoading() {
    if (!context.mounted || isDisposed) return;
    setLoading(true);
    OverlayLoadingProgress.start(context);
  }

  // 공통 로직: 로딩 UI 종료
  void stopLoading() {
    if (!context.mounted || isDisposed) return;
    setLoading(false);
    OverlayLoadingProgress.stop();
  }

  // 공통 로직: 버튼 애니메이션 시작
  void startButtonAnimation() {
    if (animationController == null || isDisposed) return;
    animationController!.reset();
    animationController!.forward(from: 0.0);
  }

  // 공통 로직: 버튼 애니메이션 중지
  void stopButtonAnimation() {
    if (animationController == null || isDisposed) return;
    if (animationController!.isAnimating) {
      animationController!.stop();
    }
  }

  void stopAllAnimations() {
    stopButtonAnimation();
    stopLoading();
  }

  // 공통 로직: 로그인 확인
  Future<bool> checkLogin() async {
    if (!context.mounted || isDisposed) return false;

    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (context.mounted) showRequireLoginDialog();
      return false;
    }
    return true;
  }

  // 공통 로직: 광고 시청 제한 확인
  Future<bool> checkAdsLimit(String platform) async {
    if (!context.mounted || isDisposed) return false;

    try {
      final response = await supabase.functions.invoke(
        'check-ads-count?platform=$platform',
      );
      if (!context.mounted || isDisposed) return false;

      logger.i('checkAdsLimit response: ${response.data}');

      final allowed = response.data['allowed'] as bool?;
      if (allowed != true) {
        final limits = (response.data['limits']
            as Map<String, dynamic>)[platform] as Map<String, dynamic>;
        _handleExceededAdsLimit(
          response.data['nextAvailableTime'],
          {
            'hourly': limits['hourly'] as int,
            'daily': limits['daily'] as int,
          },
        );
        return false;
      }
      return true;
    } catch (e, s) {
      logger.e('Error in checkAdsLimit', error: e, stackTrace: s);
      if (context.mounted && !isDisposed) {
        showSimpleDialog(content: t('label_ads_load_fail'), type: DialogType.error);
      }
      return false;
    }
  }

  // 공통 로직: 광고 제한 초과 처리
  void _handleExceededAdsLimit(
      String? nextAvailableTimeStr, Map<String, int>? limits) {
    if (nextAvailableTimeStr == null || !context.mounted || isDisposed) return;

    final nextAvailableTime = DateTime.parse(nextAvailableTimeStr).toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    showSimpleDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t('label_ads_exceeded'),
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          UnderlinedText(
            text: t('label_ads_limits', {
              'hourly': limits?['hourly'].toString() ?? '0',
              'daily': limits?['daily'].toString() ?? '0'
            }),
            textStyle: getTextStyle(AppTypo.body14M, AppColors.grey600),
          ),
          const SizedBox(height: 16),
          Text(t('ads_available_time'),
              style: getTextStyle(AppTypo.body14M, AppColors.grey900),
              textAlign: TextAlign.center),
          Text(formatter.format(nextAvailableTime),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 공통 로직: 전체 오류 처리 흐름
  Future<void> safelyExecute(Future<void> Function() action,
      {bool isMission = false}) async {
    if (!await checkLogin()) return;

    try {
      startLoading();

      if (!isMission) {
        final checkAdsLimitResult = await checkAdsLimit(id);
        if (!checkAdsLimitResult) {
          stopAllAnimations();
          return;
        }
      }

      await action();
    } catch (e, s) {
      stopAllAnimations();
      await handleError(e, s);
    }
  }

  void logInitFailure(String platform, dynamic error, StackTrace? stackTrace) {
    logger.e('초기화 실패', error: error, stackTrace: stackTrace);

    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('platform', platform);
        scope.setTag('error_type', error.runtimeType.toString());
        scope.setTag('error_string', error.toString());
      },
    );
  }

  // 공통 로직: 광고 로딩 실패 로깅
  void logAdLoadFailure(String platform, dynamic error, String adId,
      String message, StackTrace? stackTrace) {
    logger.e(message, error: error);

    // No Fill 에러 감지 및 처리
    if (_isNoFillError(platform, error, message)) {
      logger.i('$platform No Fill 에러는 Sentry 보고에서 제외됨');
      
      // No Fill 에러 시 사용자에게 다이얼로그 표시
      if (context.mounted && !isDisposed) {
        _showNoFillDialog();
      }
      return;
    }

    // 일반 에러는 Sentry에 보고
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('platform', platform);
        scope.setTag('ad_type', 'load');
        scope.setTag('ad_id', adId);
        scope.setTag('error_message', message);
        scope.setTag('error_type', error.runtimeType.toString());
        scope.setTag('error_string', error.toString());
      },
    );

    // 일반 에러 시 사용자에게 에러 다이얼로그 표시
    if (context.mounted && !isDisposed) {
      showSimpleDialog(content: t('label_ads_load_fail'), type: DialogType.error);
    }
  }

  // No Fill 에러 감지 메서드
  bool _isNoFillError(String platform, dynamic error, String message) {
    final lowercaseMessage = message.toLowerCase();
    
    // AdMob의 경우 - 특정 조건
    if (platform == 'AdMob' && 
        error is LoadAdError && 
        error.code == 3 &&
        error.message.contains('No fill')) {
      return true;
    }
    
    // 명확한 no fill 에러 메시지들만 감지
    final noFillKeywords = [
      'no fill',
      'nofill',
      'no ad available',
      'inventory unavailable', 
      'no ads available',
      'not_ready',         // Unity 특화
      'not ready',         // Unity 특화
      '광고 없음',
      '광고 없습니다',
      '광고가 없습니다',
    ];
    
    return noFillKeywords.any((keyword) => lowercaseMessage.contains(keyword));
  }

  // No Fill 에러 시 표시할 간단한 다이얼로그
  void _showNoFillDialog() {
    showSimpleDialog(
      title: t('dialog_title_ads_exhausted'),
      content: t('dialog_content_ads_exhausted')
    );
  }

  // 공통 로직: 광고 표시 실패 로깅
  void logAdShowFailure(String platform, dynamic error, String adId,
      String message, StackTrace? stackTrace) {
    logger.e(message, error: error, stackTrace: stackTrace);

    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('platform', platform);
        scope.setTag('ad_type', 'show');
        scope.setTag('ad_id', adId);
        scope.setTag('error_message', message);
        scope.setTag('error_type', error.runtimeType.toString());
        scope.setTag('error_string', error.toString());
      },
    );
  }
}
