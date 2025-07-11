import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_content.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_card.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_error.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_logo_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_score_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_summary_widget.dart';
// ignore: unused_import
import 'package:picnic_lib/presentation/widgets/community/compatibility/fortune_divider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

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
  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final styleController = ExpansibleController();
  final activityController = ExpansibleController();
  final tipController = ExpansibleController();
  bool _isSaving = false;
  bool _isSharing = false;
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController
  static const _animationDuration = Duration(milliseconds: 300);
  static const _scrollCurve = Curves.easeOut;

  // late final에서 getter로 변경하여 항상 최신 아티스트 정보 사용
  String get _shareMessage {
    final artistName = getLocaleTextFromJson(widget.compatibility.artist.name);
    logger.d('🎯 아티스트 이름: "$artistName"');
    final message =
        AppLocalizations.of(context).compatibility_share_message(artistName);
    logger.d('🎯 공유 메시지: "$message"');
    return message;
  }

  @override
  void initState() {
    super.initState();
    logger.d('CompatibilityResultPage initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String message) async {
    showSimpleErrorDialog(context, message);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .loadCompatibility(widget.compatibility.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;

      if (widget.compatibility.isPending) {
        ref.read(compatibilityLoadingProvider.notifier).state = true;
      }

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
          .loadCompatibility(widget.compatibility.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;
    } catch (e, stack) {
      logger.e('Error refreshing compatibility data',
          error: e, stackTrace: stack);
    }
  }

  void _updateNavigation() {
    Future(() {
      // Future 콜백 내에서 mounted 체크
      if (mounted) {
        ref.read(navigationInfoProvider.notifier).settingNavigation(
              showPortal: true,
              showTopMenu: true,
              topRightMenu: TopRightType.board,
              showBottomNavigation: false,
              pageTitle: AppLocalizations.of(context).compatibility_page_title,
            );
      }
    });
  }

  Widget _buildResultContent(CompatibilityModel compatibility) {
    return CompatibilityResultContent(
      compatibility: compatibility,
      isSaving: _isSaving,
      onSave: _handleSave,
      onShare: _handleShare,
      onOpenCompatibility: _openCompatibility,
    );
  }

  void _openCompatibility(String compatibilityId) async {
    try {
      // 호환성 결과 열기 전에 로딩바 표시
      if (!mounted) return;

      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      // 첫 번째 비동기 작업 전 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      final userProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      // 첫 번째 비동기 작업 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      if (userProfile == null) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          content: AppLocalizations.of(context).message_error_occurred,
          onOk: () {
            if (mounted) {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCommunityCurrentPage(StorePage());
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        );
        return;
      }

      if ((userProfile.starCandy ?? 0) < 100) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          title: AppLocalizations.of(context).fortune_lack_of_star_candy_title,
          content:
              AppLocalizations.of(context).fortune_lack_of_star_candy_message,
          onOk: () {
            if (mounted) {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCommunityCurrentPage(StorePage());
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        );
        return;
      }

      // Supabase 함수 호출 전 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      await supabase.functions.invoke('open-compatibility', body: {
        'userId': userProfile.id,
        'compatibilityId': compatibilityId,
      });

      // Supabase 함수 호출 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      final updatedProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      // 두 번째 getUserProfiles 호출 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      if (updatedProfile == null) {
        throw Exception('Failed to get updated user profile');
      }

      await _refreshData();

      // 모든 비동기 작업 완료 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      OverlayLoadingProgress.stop();
      showSimpleDialog(
        contentWidget: Column(
          children: [
            Text(AppLocalizations.of(context).compatibility_remain_star_candy),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/star_100.png',
                    width: 36),
                Text(
                  '${updatedProfile.starCandy}',
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e, s) {
      logger.e('Error opening compatibility', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(
            AppLocalizations.of(context).message_error_occurred);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final compatibilityState = ref.watch(compatibilityProvider);

      return compatibilityState.when(
        data: (compatibility) {
          if (compatibility == null) {
            return _buildLoadingIndicator();
          }

          // CustomScrollView 대신 SingleChildScrollView 사용하여 렌더링 복잡성 감소
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(), // 더 안정적인 스크롤 물리학
            child: RepaintBoundary(
              key: _saveKey,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary500.withValues(alpha: .7),
                      AppColors.secondary500.withValues(alpha: .7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // 공유용 RepaintBoundary를 조건부로만 적용
                    RepaintBoundary(
                      key: _shareKey,
                      child: Container(
                        decoration: _isSharing
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary500.withValues(alpha: .7),
                                    AppColors.secondary500
                                        .withValues(alpha: .7),
                                  ],
                                ),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // MainAxisSize 최적화
                          children: [
                            const SizedBox(height: 24),
                            const CompatibilityLogoWidget(),
                            const SizedBox(height: 36),
                            CompatibilityCard(
                              artist: compatibility.artist,
                              ref: ref,
                              birthDate: compatibility.birthDate,
                              birthTime: compatibility.birthTime,
                              compatibility: compatibility,
                              gender: compatibility.gender,
                            ),
                            const SizedBox(height: 24),
                            CompatibilitySummaryWidget(
                                localizedResult:
                                    compatibility.getLocalizedResult(
                                        Localizations.localeOf(context)
                                            .languageCode)),
                            const SizedBox(height: 24),
                            CompatibilityScoreWidget(
                              compatibility: compatibility,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (compatibility.hasError)
                            CompatibilityErrorView(
                              error: compatibility.errorMessage ??
                                  AppLocalizations.of(context).error_unknown,
                            )
                          else if (compatibility.isCompleted)
                            _buildResultContent(compatibility)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => _buildLoadingIndicator(),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: getTextStyle(AppTypo.body14R, AppColors.grey500),
          ),
        ),
      );
    } catch (e, stack) {
      logger.e('Error building compatibility result page',
          error: e, stackTrace: stack);
      return Center(
        child: Text(
          'Error: $e',
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: MediumPulseLoadingIndicator(),
    );
  }

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return ShareUtils.saveImage(
      _saveKey,
      onStart: () {
        setState(() {
          _isSaving = true;
        });
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        styleController.expand();
        activityController.expand();
        tipController.expand();
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() {
          _isSaving = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: _animationDuration,
            curve: _scrollCurve,
          );
        });
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    logger.i('Share to Twitter');
    final artistName = getLocaleTextFromJson(compatibility.artist.name);
    final hashtag = AppLocalizations.of(context).compatibility_share_hashtag;
    logger.d('🎯 해시태그 - 아티스트 이름: "$artistName", 결과: "$hashtag"');

    return ShareUtils.shareToSocial(
      _shareKey,
      message: _shareMessage,
      hashtag: hashtag,
      downloadLink: await createBranchLink(
          getLocaleTextFromJson(compatibility.artist.name),
          '${Environment.appLinkPrefix}/community/compatibility/${compatibility.artist.id}'),
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() {
          _isSharing = true;
        });
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() {
          _isSharing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: _animationDuration,
            curve: _scrollCurve,
          );
        });
      },
    );
  }
}
