import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/locale_provider.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_privacy';
  final String? language;

  const PrivacyPage({super.key, this.language});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage>
    with SingleTickerProviderStateMixin {
  PolicyLanguage? language;

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
        ref.watch(localeStateProvider).languageCode == 'ko'
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
                      ? policy.privacyKo.content
                      : policy.privacyEn.content),
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
