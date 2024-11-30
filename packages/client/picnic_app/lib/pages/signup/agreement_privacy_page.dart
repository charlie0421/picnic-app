import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/models/policy.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/policy_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
    ref.watch(userInfoProvider);

    return asyncPolicyState.when(
        data: (data) => _buildPrivacy(data),
        error: (error, stackTrace) =>
            buildErrorView(context, error: error, stackTrace: stackTrace),
        loading: () => buildLoadingOverlay());
  }

  _buildPrivacy(PolicyModel data) {
    ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    return Column(
      children: [
        SizedBox(
          height: 25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Text(
                Intl.message('label_agreement_privacy'),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                textAlign: TextAlign.center,
              ),
              Positioned(
                left: 10.cw,
                child: GestureDetector(
                  onTap: () {
                    navigationInfoNotifier.goBackSignUp();
                  },
                  child: SvgPicture.asset(
                    'assets/icons/arrow_left_style=line.svg',
                    width: 24.cw,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.grey900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Expanded(
          child: Container(
            color: AppColors.grey100,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Markdown(
                data: Intl.getCurrentLocale() == 'ko'
                    ? data.privacyKo.content
                    : data.privacyEn.content),
          ),
        ),
        SizedBox(
          height: 60,
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
                              title: Intl.message('title_dialog_success'),
                              contentWidget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    Intl.message('message_agreement_success'),
                                    style: getTextStyle(
                                        AppTypo.body16R, AppColors.grey900),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    formatCurrentTime(),
                                    style: getTextStyle(
                                        AppTypo.caption10SB, AppColors.grey500),
                                  ),
                                ],
                              ),
                              onOk: () {
                                navigationInfoNotifier.setResetStackSignUp();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              });
                        });
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSimpleDialog(
                              title: Intl.message('title_dialog_error'),
                              content: Intl.message('message_agreement_fail'),
                              onOk: () {
                                Navigator.pop(context);
                              });
                        });
                      }
                    } catch (e, s) {
                      logger.e(e, stackTrace: s);
                      Sentry.captureException(
                        e,
                        stackTrace: s,
                      );

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showSimpleDialog(
                            title: Intl.message('title_dialog_error'),
                            content: Intl.message('message_agreement_fail'),
                            onOk: () {
                              Navigator.pop(context);
                            });
                      });
                      rethrow;
                    } finally {
                      OverlayLoadingProgress.stop();
                    }
                  },
                  child: Text(Intl.message('label_button_agreement'),
                      style: getTextStyle(AppTypo.body16B, AppColors.grey00))),
            ],
          ),
        )
      ],
    );
  }
}
