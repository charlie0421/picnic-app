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
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();

    // 최초 한 번만 초기화
    if (!_isInitialized) {
      _isInitialized = true;
      // 다음 프레임에서 provider 초기화
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(compatibilityProvider.notifier).state = widget.compatibility;
      });
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

    // 초기화 전이거나 데이터가 없는 경우
    if (!_isInitialized || compatibility == null) {
      return Container(
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
                      compatibility: widget.compatibility,
                    ),
                    const CompatibilityLoadingView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // i18n 데이터가 없는 경우 새로고침
    if (compatibility.isCompleted && compatibility.localizedResults == null) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(compatibilityProvider.notifier).refresh();
      });
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
                    if (compatibility.status == CompatibilityStatus.pending)
                      const CompatibilityLoadingView()
                    else if (compatibility.status == CompatibilityStatus.error)
                      CompatibilityErrorView(
                        error:
                            compatibility.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
                      )
                    else if (compatibility.status ==
                        CompatibilityStatus.completed)
                      CompatibilityResultView(
                        compatibility: compatibility,
                        language: Intl.getCurrentLocale(),
                      ),
                  ],
                ),
              ),
            ),
            if (compatibility.isCompleted) ...[
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
