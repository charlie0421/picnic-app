import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/policy.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/policy_provider.dart';
import 'package:picnic_app/util.dart';

class TermsPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_terms_of_use';

  TermsPage({super.key, this.language});
  String? language;

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage>
    with SingleTickerProviderStateMixin {
  PolicyLanguage? language;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.language == 'ko') {
        ref.read(appSettingProvider.notifier).setLocale(Locale('ko'));
      } else {
        ref.read(appSettingProvider.notifier).setLocale(Locale('en'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PolicyLanguage language =
        ref.watch(appSettingProvider).locale.languageCode == 'ko'
            ? PolicyLanguage.ko
            : PolicyLanguage.en;
    final policyModelState = ref.watch(asyncPolicyProvider);
    return policyModelState.when(
      data: (policy) {
        return Column(
          children: [
            Expanded(
              child: Markdown(
                  data: language == PolicyLanguage.ko
                      ? policy.terms_ko!.content
                      : policy.terms_en!.content),
            ),
          ],
        );
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stack) => ErrorView(
        context,
        error: error,
        stackTrace: stack,
      ),
    );
  }
}
