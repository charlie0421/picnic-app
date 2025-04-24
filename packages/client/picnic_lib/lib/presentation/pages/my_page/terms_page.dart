import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';

class TermsPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_terms_of_use';

  const TermsPage({super.key, this.language});

  final String? language;

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage>
    with SingleTickerProviderStateMixin {
  PolicyLanguage? language;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final PolicyLanguage language =
        ref.watch(appSettingProvider).language == 'ko'
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
                      ? policy.termsKo.content
                      : policy.termsEn.content),
            ),
          ],
        );
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stack) => buildErrorView(
        context,
        error: error,
        stackTrace: stack,
      ),
    );
  }
}
