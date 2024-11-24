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
  String? _currentLocale;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Intl.getCurrentLocale();
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      if (_isInitialized) {
        _refreshData();
      }
    }
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      // 초기 데이터 설정
      await ref
          .read(compatibilityProvider.notifier)
          .setCompatibility(widget.compatibility);

      // compatibility가 pending 상태일 때만 loading 상태로 설정
      if (widget.compatibility.isPending) {
        ref.read(compatibilityLoadingProvider.notifier).state = true;
      }

      setState(() {
        _isInitialized = true;
      });

      // completed 상태면 데이터 새로고침
      if (widget.compatibility.isCompleted) {
        await _refreshData();
      }
    } catch (e, stack) {
      logger.e('Error initializing data', error: e, stackTrace: stack);
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .loadCompatibility(widget.compatibility.id);
    } catch (e, stack) {
      logger.e('Error refreshing compatibility data',
          error: e, stackTrace: stack);
    }
  }

  void _updateNavigation() {
    if (!mounted) return;

    Future(() {
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
    final compatibilityState = ref.watch(compatibilityProvider);

    return compatibilityState.when(
      data: (compatibility) {
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
                        if (!_isInitialized) ...[
                          const Center(child: CircularProgressIndicator()),
                        ] else if (compatibility.isPending) ...[
                          const CompatibilityLoadingView(),
                        ] else if (compatibility.hasError) ...[
                          CompatibilityErrorView(
                            error: compatibility.errorMessage ??
                                S.of(context).error_unknown,
                          ),
                        ] else if (compatibility.isCompleted) ...[
                          CompatibilityResultView(
                            compatibility: compatibility,
                            language: _currentLocale ?? Intl.getCurrentLocale(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (compatibility.isCompleted &&
                    compatibility.localizedResults != null) ...[
                  const SizedBox(height: 16),
                  VoteCardInfoFooter(
                    saveButtonText: S.of(context).vote_result_save_button,
                    shareButtonText: S.of(context).vote_result_share_button,
                    onSave: () => _handleSave(compatibility),
                    onShare: () => _handleShare(compatibility),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context).compatibility_status_error,
              style: getTextStyle(AppTypo.body14M, AppColors.point500),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _refreshData,
              child: Text(S.of(context).label_retry),
            ),
          ],
        ),
      ),
    );
  }

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return VoteShareUtils.captureAndSaveImage(
      _printKey,
      context,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    return VoteShareUtils.shareToTwitter(
      _printKey,
      title: getLocaleTextFromJson(compatibility.artist.name),
      context,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }
}
