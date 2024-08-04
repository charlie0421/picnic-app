import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/pages/signup/agreement_privacy.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/policy_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
    final userInfoNotifier = ref.watch(userInfoProvider);

    return asyncPolicyState.when(
        data: (data) => _buildTerms(data),
        error: (error, stackTrace) =>
            ErrorView(context, error: error, stackTrace: stackTrace),
        loading: () => buildLoadingOverlay());
  }

  _buildTerms(
    data,
  ) {
    final navigationInfoState = ref.watch(navigationInfoProvider);
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
                    height: 24,
                    color: AppColors.Grey900,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Expanded(
          child: Container(
            color: AppColors.Grey100,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Markdown(
                data: Intl.getCurrentLocale() == 'ko'
                    ? data.terms_ko.content
                    : data.terms_en.content),
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
                      style:
                          getTextStyle(AppTypo.BODY16B, AppColors.Primary500))),
            ],
          ),
        )
      ],
    );
  }
}
