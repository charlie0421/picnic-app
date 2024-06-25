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

  const TermsPage({super.key});

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabBar();
  }

  Widget _buildTabBar() {
    final PolicyLanguage language =
    ref
        .watch(appSettingProvider)
        .locale
        .languageCode == 'ko'
        ? PolicyLanguage.ko
        : PolicyLanguage.en;
    final policyModelState = ref
        .watch(asyncPolicyProvider(type: PolicyType.terms, language: language));
    return policyModelState.when(
      data: (policy) {
        return Column(
          children: [
            Expanded(
              child: Markdown(
                data: policy.content,
              ),
            ),
          ],
        );
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stack) =>
          ErrorView(
            context,
            error: error,
            stackTrace: stack,
          ),
    );
  }
}
