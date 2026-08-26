import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
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

  /// 이 플랫폼이 켠 로딩(전역 오버레이 + adLoadingStateProvider)이 아직
  /// 꺼지지 않았는지. OverlayLoadingProgress 는 전역 싱글턴이라, dispose 가
  /// 자신이 켠 것만 정리해야 다른 기능의 오버레이를 닫지 않는다.
  bool _startedLoading = false;
  final Stopwatch _performanceStopwatch = Stopwatch();

  /// 이번 시청 건의 GA4 컨텍스트. 구좌(버튼) 클릭 시점에 주입된다.
  ///
  /// `ad_request` 를 보낸 구좌의 카테고리·재화·수량을 `ad_impression` /
  /// `ad_click` / `earn_virtual_currency` 까지 그대로 옮기기 위한 값이며,
  /// analytics 전용이라 광고 동작에는 전혀 관여하지 않는다.
  FreeChargeAdGa4Context? ga4AdContext;

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

  void logError(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    logger.e(
      '[$id${tag != null ? ':$tag' : ''}] $message',
      error: error,
      stackTrace: stackTrace,
    );
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
    final ownedLoading = _startedLoading;
    _startedLoading = false;
    _isDisposed = true;
    // stopAllAnimations() 는 isDisposed 가드에 막혀 여기서는 전부 no-op 이라
    // teardown 에 필요한 정리를 직접 한다. 단, 이 플랫폼이 켠 로딩만 끈다.
    if (animationController != null && animationController!.isAnimating) {
      animationController!.stop();
    }
    if (ownedLoading) {
      // 오버레이는 전역이라 페이지가 죽어도 남는다 — 먼저 내린다.
      OverlayLoadingProgress.stop();
      // 로딩 상태는 전역 provider 라 남으면 다음 방문의 버튼이 잠긴다.
      // State.dispose 안에서의 ref.read 는 허용되고, 그 밖의 늦은 호출이
      // 던지면 AdService 가 플랫폼별로 격리한다.
      ref.read(adLoadingStateProvider.notifier).setLoading(id, false);
    }
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
    _startedLoading = true;
    OverlayLoadingProgress.start(context);
  }

  // 공통 로직: 로딩 UI 종료
  void stopLoading() {
    if (!context.mounted || isDisposed) return;
    setLoading(false);
    _startedLoading = false;
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

  /// G3: kDebugMode + admob 한정으로 서버 `disabled` 게이트를 우회할지 여부.
  ///
  /// AdMob 은 운영 롤아웃 전이라 서버가 `disabled: true` 를 내려줄 수 있다.
  /// QA 가 로컬 디버그 빌드에서 실제 시청 플로우(요청→응답→rate limit)를
  /// 끝까지 확인할 수 있도록 이 게이트만 우회한다 — `allowed`/rate limit/에러
  /// 경로는 그대로 둔다. 순수 함수라 kDebugMode 를 직접 읽지 않고 인자로
  /// 받는다: 이래야 release 분기(`isDebugMode: false`)도 테스트로 고정할 수 있다.
  @visibleForTesting
  static bool shouldBypassDisabledForDebugAdmob({
    required bool isDebugMode,
    required String platform,
  }) {
    return isDebugMode && platform == 'admob';
  }

  /// G3: `check-ads-count` 요청/응답 판정 seam — BuildContext 에 의존하지 않는다.
  ///
  /// os 스코프 1차 응답이 `disabled: true` 이고 [shouldBypassDisabledForDebugAdmob]
  /// 조건(kDebugMode+admob)을 만족할 때만 os 파라미터 없이 정확히 한 번
  /// 재요청하고, 그 2차 응답을 최종 데이터로 그대로 반환한다. 2차 응답이 다시
  /// disabled 여도 재귀 재시도는 하지 않는다 — "정확히 한 번"이 요구사항이고,
  /// 무한 루프를 방지한다. [checkAdsLimit] 은 이 결과를 기존 disabled/allowed
  /// 판정 로직에 그대로 흘려보낸다: 단순히 disabled 게이트만 건너뛰면 1차
  /// 응답의 allowed:false 가 그대로 남아 여전히 막히므로(PICNIC-2377 리뷰
  /// 지적), 판정 대상 데이터 자체를 2차 응답으로 교체해야 한다.
  @visibleForTesting
  static Future<Map> resolveAdsCountData({
    required String platform,
    required String os,
    required bool isDebugMode,
  }) async {
    final data = await _requestAdsCount(platform: platform, os: os);

    if (data['disabled'] == true &&
        shouldBypassDisabledForDebugAdmob(
          isDebugMode: isDebugMode,
          platform: platform,
        )) {
      logger.w(
        '⚠️ [DEBUG ONLY] [$platform] disabled=true 이지만 kDebugMode+admob 이라 '
        'os 파라미터 없이 재요청합니다. release 빌드에서는 절대 발생하면 안 됩니다.',
      );
      return _requestAdsCount(platform: platform, os: null);
    }

    return data;
  }

  static Future<Map> _requestAdsCount({
    required String platform,
    required String? os,
  }) async {
    final query = os == null
        ? 'check-ads-count?platform=$platform'
        : 'check-ads-count?platform=$platform&os=$os';
    logger.i('[checkAdsLimit] request start: $query');
    final resp = await supabase.functions.invoke(query);

    final status = (resp as dynamic).status;
    logger.i('[checkAdsLimit] response status: $status, raw: ${resp.data}');

    // 상태코드 4xx/5xx 로깅. invoke() 는 실제로는 2xx 외 응답에 대해
    // FunctionException 을 던지므로(catch 로 전파) 이 분기는 방어적 로깅이다.
    if (status is int && status >= 400) {
      logger.w('[checkAdsLimit] http error status: $status');
    }

    return (resp.data as Map?) ?? const {};
  }

  // 공통 로직: 광고 시청 제한 확인
  Future<bool> checkAdsLimit(String platform) async {
    if (!context.mounted || isDisposed) return false;

    try {
      final os = Platform.isIOS ? 'ios' : 'android';
      final data = await resolveAdsCountData(
        platform: platform,
        os: os,
        isDebugMode: kDebugMode,
      );
      if (!context.mounted || isDisposed) return false;

      // 서버 설정에 의해 비활성화된 경우
      if (data['disabled'] == true) {
        if (context.mounted && !isDisposed) {
          showSimpleDialog(
            content: AppLocalizations.of(
              context,
            ).label_ads_temporarily_unavailable,
          );
        }
        return false;
      }

      final allowed = data['allowed'] == true;
      if (allowed != true) {
        // limits 안전 파싱
        final limitsMap = (data['limits'] as Map?) ?? const {};
        final platformLimits = (limitsMap[platform] as Map?) ?? const {};
        final hourly = (platformLimits['hourly'] as num?)?.toInt() ?? 10;
        final daily = (platformLimits['daily'] as num?)?.toInt() ?? 50;
        final nextAvailableTime = data['nextAvailableTime'] as String?;

        _handleExceededAdsLimit(nextAvailableTime, {
          'hourly': hourly,
          'daily': daily,
        });
        return false;
      }
      return true;
    } catch (e, s) {
      logError('Error in checkAdsLimit', error: e, stackTrace: s);
      if (context.mounted && !isDisposed) {
        showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error,
        );
      }
      return false;
    }
  }

  // 공통 로직: 광고 제한 초과 처리
  void _handleExceededAdsLimit(
    String? nextAvailableTimeStr,
    Map<String, int>? limits,
  ) {
    if (!context.mounted || isDisposed) return;

    DateTime? nextAvailableTime;
    if (nextAvailableTimeStr != null) {
      try {
        nextAvailableTime = DateTime.parse(nextAvailableTimeStr).toLocal();
      } catch (_) {
        nextAvailableTime = null;
      }
    }

    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    showSimpleDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).label_ads_exceeded,
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (limits != null)
            UnderlinedText(
              text: AppLocalizations.of(context).label_ads_limits(
                (limits['hourly'] as num?)?.toInt() ?? 0,
                (limits['daily'] as num?)?.toInt() ?? 0,
              ),
              textStyle: getTextStyle(AppTypo.body14M, AppColors.grey600),
            ),
          if (nextAvailableTime != null) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).ads_available_time,
              style: getTextStyle(AppTypo.body14M, AppColors.grey900),
              textAlign: TextAlign.center,
            ),
            Text(
              formatter.format(nextAvailableTime),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // 공통 로직: 전체 오류 처리 흐름
  Future<void> safelyExecute(
    Future<void> Function() action, {
    bool isMission = false,
  }) async {
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
  void logAdLoadFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    logger.e(message, error: error);

    // 일시적/외부 요인 에러는 Sentry 보고에서 제외
    if (isNonReportableAdError(platform, error, message)) {
      logger.i('$platform 광고 에러 Sentry 보고 제외: $message');

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
      showSimpleDialog(
        content: AppLocalizations.of(context).label_ads_load_fail,
        type: DialogType.error,
      );
    }
  }

  /// Sentry 에 보내지 않아도 되는 광고 에러 감지.
  ///
  /// 판정은 전적으로 [message] 문자열에 달려 있다(AdMob 의 [LoadAdError] 코드만
  /// 예외). 따라서 호출부는 **실제 에러 텍스트**를 넘겨야 한다 — 하드코딩한
  /// 일반 라벨('… 광고 로드 실패' 등)을 넘기면 SDK 초기화 실패·설정 오류 같은
  /// 진짜 버그까지 no-fill 로 분류되어 사용자에겐 "모든 광고 소진"으로 보이고
  /// Sentry 보고까지 막힌다.
  ///
  /// 인스턴스 상태를 쓰지 않으므로 static 이다 — 테스트가 로직을 복제하지 않고
  /// 이 구현을 그대로 호출할 수 있어야 키워드 목록이 바뀌어도 검증이 따라간다.
  @visibleForTesting
  static bool isNonReportableAdError(
    String platform,
    dynamic error,
    String message,
  ) {
    final lowercaseMessage = message.toLowerCase();

    if (platform == 'AdMob' && error is LoadAdError) {
      // code 1: Request Error (설정/네트워크 문제)
      // code 2: Network Error (사용자 네트워크 문제)
      // code 3: No Fill (광고 재고 없음)
      if (error.code == 1 || error.code == 2 || error.code == 3) {
        return true;
      }
    }

    final nonReportableKeywords = [
      'no fill',
      'nofill',
      'no ad available',
      'no ad to show',
      'inventory unavailable',
      'no ads available',
      'not_ready',
      'not ready',
      'network error',
      '광고 없음',
      '광고 없습니다',
      '광고가 없습니다',
      '광고 로드 실패',
      '광고 로드 시간 초과',
      // Tapjoy SDK 미연결 (초기화 race / 백그라운드 복귀 race) — 사용자 환경
      // 또는 SDK lifecycle 이슈, 우리 코드 버그 아님 (PICNIC-APP-43M)
      'sdk is not connected',
      // iOS NSURLError 계열 (-1001 timeout / -1009 not connected / -1003 cannot
      // find host / -1004 cannot connect to host 등) — 사용자 네트워크 환경
      // (PICNIC-APP-43N: '작업을 완료할 수 없습니다. Server Error With Status Code:-1001')
      'server error with status code:-',
      '작업을 완료할 수 없습니다',
    ];

    return nonReportableKeywords.any(
      (keyword) => lowercaseMessage.contains(keyword),
    );
  }

  // No Fill 에러 시 표시할 간단한 다이얼로그
  void _showNoFillDialog() {
    showSimpleDialog(
      title: AppLocalizations.of(context).dialog_title_ads_exhausted,
      content: AppLocalizations.of(context).dialog_content_ads_exhausted,
    );
  }

  // 공통 로직: 광고 표시 실패 로깅
  void logAdShowFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    logger.e(message, error: error, stackTrace: stackTrace);

    if (isNonReportableAdError(platform, error, message)) {
      logger.i('$platform 광고 표시 에러 Sentry 보고 제외: $message');
      return;
    }

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
