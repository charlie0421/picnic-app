import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

/// 광고 플랫폼 추상 클래스
abstract class AdPlatform {
  final WidgetRef ref;
  final BuildContext context;
  final String id;
  final AnimationController? animationController;
  late final CommonUtils _commonUtils;

  CommonUtils get commonUtils => _commonUtils;

  AdPlatform(this.ref, this.context, this.id, [this.animationController]) {
    _commonUtils = CommonUtils(ref, context);
  }

  Future<void> initialize();
  Future<void> showAd();
  Future<void> handleError(dynamic error, StackTrace? stackTrace);

  // 공통 로직: 로딩 상태 설정
  void setLoading(bool isLoading) {
    if (!context.mounted) return;
    ref.read(adLoadingStateProvider.notifier).setLoading(id, isLoading);
  }

  // 공통 로직: 로딩 UI 시작
  void startLoading() {
    if (!context.mounted) return;
    setLoading(true);
    OverlayLoadingProgress.start(context);
  }

  // 공통 로직: 로딩 UI 종료
  void stopLoading() {
    if (!context.mounted) return;
    setLoading(false);
    OverlayLoadingProgress.stop();
  }

  // 공통 로직: 버튼 애니메이션 시작
  void startButtonAnimation() {
    if (animationController == null) return;
    animationController!.reset();
    animationController!.forward(from: 0.0);
  }

  // 공통 로직: 버튼 애니메이션 중지
  void stopButtonAnimation() {
    logger.i('stopButtonAnimation');
    if (animationController == null) return;
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
    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (context.mounted) showRequireLoginDialog();
      return false;
    }
    return true;
  }

  // 공통 로직: 광고 시청 제한 확인
  Future<bool> checkAdsLimit(String platform) async {
    try {
      final response = await supabase.functions.invoke(
        'check-ads-count?platform=$platform',
      );
      if (!context.mounted) return false;

      logger.i('checkAdsLimit response: ${response.data}');

      final allowed = response.data['allowed'] as bool?;
      if (allowed != true) {
        final limits = (response.data['limits']
            as Map<String, dynamic>)[platform] as Map<String, dynamic>;
        // ignore: unused_local_variable
        final counts = (response.data['counts']
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
      _commonUtils.showErrorDialog(S.of(context).label_ads_load_fail);
      return false;
    }
  }

  // 공통 로직: 광고 제한 초과 처리
  void _handleExceededAdsLimit(
      String? nextAvailableTimeStr, Map<String, int>? limits) {
    if (nextAvailableTimeStr == null || !context.mounted) return;

    final nextAvailableTime = DateTime.parse(nextAvailableTimeStr).toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    showSimpleDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).label_ads_exceeded,
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          UnderlinedText(
            text: S.of(context).label_ads_limits(
                  limits?['hourly'] ?? 0,
                  limits?['daily'] ?? 0,
                ),
            textStyle: getTextStyle(AppTypo.body14M, AppColors.grey600),
          ),
          const SizedBox(height: 16),
          Text(S.of(context).ads_available_time,
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
          stopLoading();
          stopButtonAnimation();
          return;
        }
      }

      await action();
    } catch (e, s) {
      stopButtonAnimation();
      stopLoading();
      await handleError(e, s);
    } finally {}
  }
}
