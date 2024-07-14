import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/policy_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class AgreementPrivacyPage extends ConsumerStatefulWidget {
  const AgreementPrivacyPage({super.key});

  @override
  ConsumerState<AgreementPrivacyPage> createState() =>
      _AgreementPrivacyPageState();
}

class _AgreementPrivacyPageState extends ConsumerState<AgreementPrivacyPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncPolicyState = ref.watch(asyncPolicyProvider);
    final userInfoNotifier = ref.watch(userInfoProvider);

    return asyncPolicyState.when(
        data: (data) => _buildPrivacy(data),
        error: (error, stackTrace) =>
            ErrorView(context, error: error, stackTrace: stackTrace),
        loading: () => buildLoadingOverlay());
  }

  _buildPrivacy(data) {
    final navigationInfoState = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    return Column(
      children: [
        SizedBox(
          height: 25.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Text(
                Intl.message('label_agreement_privacy'),
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                textAlign: TextAlign.center,
              ),
              Positioned(
                left: 10.w,
                child: GestureDetector(
                  onTap: () {
                    navigationInfoNotifier.goBackSignUp();
                  },
                  child: SvgPicture.asset(
                    'assets/icons/arrow_left_style=line.svg',
                    width: 24.w,
                    height: 24.h,
                    color: AppColors.Grey900,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 5.h,
        ),
        Expanded(
          child: Container(
            color: AppColors.Grey100,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Markdown(
                data: Intl.getCurrentLocale() == 'ko'
                    ? data.privacy_ko.content
                    : data.privacy_en.content),
          ),
        ),
        SizedBox(
          height: 60.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    try {
                      OverlayLoadingProgress.start(context);

                      bool ret = await ref.read(setAgreementProvider.future);
                      logger.i(ret);
                      if (ret == true) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSimpleDialog(
                              context: context,
                              title: Intl.message('title_dialog_success'),
                              contentWidget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    Intl.message('message_agreement_success'),
                                    style: getTextStyle(
                                        AppTypo.BODY16R, AppColors.Grey900),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    formatCurrentTime(),
                                    style: getTextStyle(
                                        AppTypo.CAPTION10SB, AppColors.Grey500),
                                  ),
                                ],
                              ),
                              onOk: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                // Navigator.pop(context, true);
                                // Navigator.pushNamedAndRemoveUntil(context,
                                //     HomeScreen.routeName, (route) => false);
                                //
                                // asyncMyProfileNotifier.fetch();
                              });
                        });
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSimpleDialog(
                              context: context,
                              title: Intl.message('title_dialog_error'),
                              content: Intl.message('message_agreement_fail'),
                              onOk: () {
                                Navigator.pop(context);
                              });
                        });
                      }
                    } catch (e, stacktrace) {
                      logger.e(e);
                      logger.e(stacktrace);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showSimpleDialog(
                            context: context,
                            title: Intl.message('title_dialog_error'),
                            content: Intl.message('message_agreement_fail'),
                            onOk: () {
                              Navigator.pop(context);
                            });
                      });
                    } finally {
                      OverlayLoadingProgress.stop();
                    }
                  },
                  child: Text(Intl.message('label_button_agreement'),
                      style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900))),
            ],
          ),
        )
      ],
    );
  }
}
