import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_loading_view.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_result_card.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_result_view.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_footer.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/vote_share_util.dart';

final _loadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class CompatibilityResultPage extends ConsumerStatefulWidget {
  const CompatibilityResultPage({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  ConsumerState<CompatibilityResultPage> createState() =>
      _CompatibilityResultPageState();
}

class _CompatibilityResultPageState
    extends ConsumerState<CompatibilityResultPage> {
  final GlobalKey _printKey = GlobalKey();
  String? _currentLocale;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Intl.getCurrentLocale();
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _refreshData();
    }
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_loadingProvider.notifier).state = true;
      ref.read(compatibilityProvider.notifier).state = widget.compatibility;
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    // 이미 로딩 중이면 스킵
    if (ref.read(_loadingProvider)) return;

    final compatibility = ref.read(compatibilityProvider);
    if (compatibility == null) return;

    if (compatibility.isCompleted && compatibility.localizedResults == null) {
      ref.read(_loadingProvider.notifier).state = true;

      try {
        await ref.read(compatibilityProvider.notifier).refresh();
      } finally {
        if (mounted) {
          ref.read(_loadingProvider.notifier).state = false;
        }
      }
    }
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: S.of(context).compatibility_page_title,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final compatibility = ref.watch(compatibilityProvider);
    final isLoading = ref.watch(_loadingProvider);

    if (compatibility == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RepaintBoundary(
              key: _printKey,
              child: Container(
                color: AppColors.grey00,
                child: Column(
                  children: [
                    CompatibilityResultCard(
                      compatibility: compatibility,
                    ),
                    if (compatibility.status == CompatibilityStatus.pending ||
                        isLoading)
                      const CompatibilityLoadingView()
                    else if (compatibility.status == CompatibilityStatus.error)
                      CompatibilityErrorView(
                        error:
                            compatibility.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
                      )
                    else if (compatibility.status ==
                            CompatibilityStatus.completed &&
                        !isLoading &&
                        compatibility.localizedResults != null)
                      CompatibilityResultView(
                        compatibility: compatibility,
                        language: _currentLocale ?? Intl.getCurrentLocale(),
                      ),
                  ],
                ),
              ),
            ),
            if (compatibility.isCompleted &&
                !isLoading &&
                compatibility.localizedResults != null) ...[
              VoteCardInfoFooter(
                saveButtonText: S.of(context).vote_result_save_button,
                shareButtonText: S.of(context).vote_result_share_button,
                onSave: () => VoteShareUtils.captureAndSaveImage(
                  _printKey,
                  context,
                  onStart: () {},
                  onComplete: () {},
                ),
                onShare: () => VoteShareUtils.shareToTwitter(
                  _printKey,
                  title: getLocaleTextFromJson(compatibility.artist.name),
                  context,
                  onStart: () {},
                  onComplete: () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
