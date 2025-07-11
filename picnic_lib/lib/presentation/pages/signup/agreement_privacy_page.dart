import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/ui/style.dart';
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

  Widget _buildPrivacy(PolicyModel data) {
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
                AppLocalizations.of(context).label_agreement_privacy,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                textAlign: TextAlign.center,
              ),
              Positioned(
                left: 10.w,
                child: GestureDetector(
                  onTap: () {
                    navigationInfoNotifier.goBackSignUp();
                  },
                  child: SvgPicture.asset(
                    package: 'picnic_lib',
                    'assets/icons/arrow_left_style=line.svg',
                    width: 24.w,
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
                data: Localizations.localeOf(context).languageCode == 'ko'
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
                              title: AppLocalizations.of(context)
                                  .title_dialog_success,
                              contentWidget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .message_agreement_success,
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
                                final navContext = navigatorKey.currentContext;
                                if (navContext != null && navContext.mounted) {
                                  Navigator.of(navContext).pop();
                                  Navigator.of(navContext).pop();
                                }
                              });
                        });
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSimpleDialog(
                              title: AppLocalizations.of(context)
                                  .title_dialog_error,
                              content: AppLocalizations.of(context)
                                  .message_agreement_fail,
                              onOk: () {
                                final navContext = navigatorKey.currentContext;
                                if (navContext != null && navContext.mounted) {
                                  Navigator.of(navContext).pop();
                                }
                              });
                        });
                      }
                    } catch (e, s) {
                      logger.e('error', error: e, stackTrace: s);
                      Sentry.captureException(
                        e,
                        stackTrace: s,
                      );

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showSimpleDialog(
                            title:
                                AppLocalizations.of(context).title_dialog_error,
                            content: AppLocalizations.of(context)
                                .message_agreement_fail,
                            onOk: () {
                              final navContext = navigatorKey.currentContext;
                              if (navContext != null && navContext.mounted) {
                                Navigator.of(navContext).pop();
                              }
                            });
                      });
                      rethrow;
                    } finally {
                      OverlayLoadingProgress.stop();
                    }
                  },
                  child: Text(
                      AppLocalizations.of(context).label_button_agreement,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey00))),
            ],
          ),
        )
      ],
    );
  }
}
