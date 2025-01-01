import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/presentation/widgets/error.dart';
import 'package:picnic_app/data/models/policy.dart';
import 'package:picnic_app/presentation/pages/signup/agreement_privacy_page.dart';
import 'package:picnic_app/presentation/providers/navigation_provider.dart';
import 'package:picnic_app/presentation/providers/policy_provider.dart';
import 'package:picnic_app/presentation/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/i18n.dart';
import 'package:picnic_app/core/utils/ui.dart';

class AgreementTermsPage extends ConsumerStatefulWidget {
  const AgreementTermsPage({super.key});

  @override
  ConsumerState<AgreementTermsPage> createState() => _AgreementTermsPageState();
}

class _AgreementTermsPageState extends ConsumerState<AgreementTermsPage> {
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
        data: (PolicyModel data) => _buildTerms(data),
        error: (error, stackTrace) =>
            buildErrorView(context, error: error, stackTrace: stackTrace),
        loading: () => buildLoadingOverlay());
  }

  _buildTerms(
    PolicyModel data,
  ) {
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
                Intl.message('label_agreement_terms'),
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
                        AppColors.grey900, BlendMode.srcIn),
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
                data: getLocaleLanguage() == 'ko'
                    ? data.termsKo.content
                    : data.termsEn.content),
          ),
        ),
        SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () => navigationInfoNotifier
                      .setCurrentSignUpPage(const AgreementPrivacyPage()),
                  child: Text(Intl.message('label_button_agreement'),
                      style: getTextStyle(AppTypo.body16B, AppColors.grey00))),
            ],
          ),
        )
      ],
    );
  }
}
