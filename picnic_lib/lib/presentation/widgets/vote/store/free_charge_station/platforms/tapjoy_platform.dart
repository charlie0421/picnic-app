import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy 미션 플랫폼 구현
class TapjoyPlatform extends AdPlatform {
  TapjoyPlatform(super.ref, super.context, super.id,
      [super.animationController]);

  @override
  Future<void> initialize() async {
    // Tapjoy는 showAd에서 초기화
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      // 애니메이션 시작
      startButtonAnimation();

      await _setupTapjoyUser();
      await _requestTapjoyPlacement();
      // 애니메이션은 콜백에서 중지됨
    }, isMission: true);
  }

  Future<void> _setupTapjoyUser() async {
    await Tapjoy.setUserID(
      userId: supabase.auth.currentUser!.id,
      onSetUserIDSuccess: () =>
          logger.i('setUserID onSuccess: ${supabase.auth.currentUser!.id}'),
      onSetUserIDFailure: (error) =>
          {logger.e('setUserID onFailure', error: error), stopAllAnimations()},
    );
  }

  Future<void> _requestTapjoyPlacement() async {
    TJPlacement placement = await TJPlacement.getPlacement(
      placementName: 'mission',
      onRequestSuccess: (placement) async {
        logger.i('Tapjoy onRequestSuccess');
      },
      onRequestFailure: (placement, error) {
        logger.e('Tapjoy onRequestFailure', error: error);
        if (context.mounted) {
          stopAllAnimations();

          commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
              error: error);
        }
      },
      onContentReady: (placement) {
        logger.i('Tapjoy onContentReady');
        placement.showContent();
        // 콘텐츠가 준비되어 표시될 때 애니메이션 중지
        stopAllAnimations();
      },
      onContentShow: (placement) {
        logger.i('Tapjoy onContentShow');
      },
      onContentDismiss: (placement) {
        logger.i('Tapjoy onContentDismiss');
        if (context.mounted) {
          stopAllAnimations();
          commonUtils.refreshUserProfile();
        }
      },
    );
    placement.setEntryPoint(TJEntryPoint.entryPointStore);

    await placement.requestContent();
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Error in Tapjoy mission', error: error, stackTrace: stackTrace);
    if (context.mounted) {
      stopAllAnimations();

      commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
          error: error);
    }
  }
}
