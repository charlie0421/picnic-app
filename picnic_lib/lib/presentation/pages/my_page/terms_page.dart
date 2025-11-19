import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

class TermsPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_terms_of_use';

  const TermsPage({super.key, this.language});

  final String? language;

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage>
    with SingleTickerProviderStateMixin, RouteAwareStateMixin<TermsPage> {
  PolicyLanguage? _selectedLanguage;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    final defaultLanguage = ref.read(appSettingProvider).language == 'ko'
        ? PolicyLanguage.ko
        : PolicyLanguage.en;
    _selectedLanguage = defaultLanguage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _currentTitle = AppLocalizations.of(context).label_mypage_terms_of_use;
      _updateNavigation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).label_mypage_terms_of_use;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final PolicyLanguage currentLanguage =
        _selectedLanguage ??
        (ref.watch(appSettingProvider).language == 'ko'
            ? PolicyLanguage.ko
            : PolicyLanguage.en);
    final policyModelState = ref.watch(asyncPolicyProvider);
    return policyModelState.when(
      data: (policy) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SegmentedButton<PolicyLanguage>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary500;
                        }
                        return AppColors.grey100;
                      }),
                      foregroundColor: const WidgetStatePropertyAll(
                        AppColors.grey700,
                      ),
                      overlayColor: WidgetStatePropertyAll(
                        AppColors.primary500.withValues(alpha: 0.12),
                      ),
                      side: WidgetStateProperty.resolveWith((states) {
                        return BorderSide(
                          color: states.contains(WidgetState.selected)
                              ? AppColors.primary500
                              : AppColors.secondary500,
                          width: 1.5,
                        );
                      }),
                    ),
                    segments: const <ButtonSegment<PolicyLanguage>>[
                      ButtonSegment<PolicyLanguage>(
                        value: PolicyLanguage.ko,
                        label: Text('한국어'),
                      ),
                      ButtonSegment<PolicyLanguage>(
                        value: PolicyLanguage.en,
                        label: Text('English'),
                      ),
                    ],
                    selected: {currentLanguage},
                    onSelectionChanged: (selection) {
                      final selected = selection.first;
                      setState(() {
                        _selectedLanguage = selected;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Markdown(
                data: currentLanguage == PolicyLanguage.ko
                    ? policy.termsKo.content
                    : policy.termsEn.content,
              ),
            ),
          ],
        );
      },
      loading: () => LargePulseLoadingIndicator(),
      error: (error, stack) =>
          buildErrorView(context, error: error, stackTrace: stack),
    );
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(
            pageTitle: title,
          );
    });
  }
}
