import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
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
      _CompatibilityResultScreenState();
}

class _CompatibilityResultScreenState
    extends ConsumerState<CompatibilityResultPage> {
  final GlobalKey _printKey = GlobalKey();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: S.of(context).compatibility_page_title);
    });
  }

  Future<void> _initializeIfNeeded() async {
    if (!_isInitialized) {
      _isInitialized = true;

      // 위젯 빌드 후에 provider 상태 초기화
      await Future.microtask(() async {
        if (!mounted) return;

        final compatibilityNotifier = ref.read(compatibilityProvider.notifier);

        try {
          // 항상 최신 데이터를 가져오도록 수정
          final updatedCompatibility = await compatibilityNotifier
              .getCompatibility(widget.compatibility.id);
          if (updatedCompatibility != null) {
            compatibilityNotifier.state = updatedCompatibility;
          } else {
            // 데이터를 가져오지 못했을 경우 기존 데이터로 초기화
            compatibilityNotifier.state = widget.compatibility;
          }
        } catch (e) {
          logger.e('Failed to fetch updated compatibility', error: e);
          // 에러 발생 시 기존 데이터 사용
          compatibilityNotifier.state = widget.compatibility;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compatibility =
        ref.watch(compatibilityProvider) ?? widget.compatibility;

    // i18n 데이터가 없는 경우 새로고침
    if (compatibility.isCompleted && compatibility.localizedResults == null) {
      Future.microtask(() {
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
                    switch (compatibility.status) {
                      CompatibilityStatus.pending =>
                        const CompatibilityLoadingView(),
                      CompatibilityStatus.error => CompatibilityErrorView(
                          error: compatibility.errorMessage ??
                              '알 수 없는 오류가 발생했습니다.',
                        ),
                      CompatibilityStatus.completed => CompatibilityResultView(
                          compatibility: compatibility,
                          language: Intl.getCurrentLocale(),
                        ),
                      _ => const SizedBox(),
                    },
                  ],
                ),
              ),
            ),
            if (compatibility.isCompleted) ...[
              VoteCardInfoFooter(
                saveButtonText: '이미지 저장',
                shareButtonText: '공유하기',
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
