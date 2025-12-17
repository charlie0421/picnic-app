import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_result_content.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_card.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_error.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_logo_widget.dart';
// ignore: unused_import
import 'package:picnic_lib/presentation/widgets/community/goonghap/fortune_divider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

class GoonghapResultPage extends ConsumerStatefulWidget {
  const GoonghapResultPage({super.key, required this.goonghap});

  final GoonghapModel goonghap;

  @override
  ConsumerState<GoonghapResultPage> createState() =>
      _GoonghapResultPageState();
}

class _GoonghapResultPageState
    extends ConsumerState<GoonghapResultPage>
    with RouteAwareStateMixin<GoonghapResultPage> {
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
  bool _invokingI18n = false;
  bool _isLoadingI18n = false;

  // late final에서 getter로 변경하여 항상 최신 아티스트 정보 사용
  String get _shareMessage {
    final artistName = getLocaleTextFromJson(
      widget.goonghap.artist.name,
      context,
    );
    logger.d('🎯 아티스트 이름: "$artistName"');
    final message = AppLocalizations.of(
      context,
    ).goonghap_share_message(artistName);
    logger.d('🎯 공유 메시지: "$message"');
    return message;
  }

  @override
  void initState() {
    super.initState();
    logger.d('GoonghapResultPage initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      // 초기 진입 시 헤더 타이틀을 즉시 아티스트 이름으로 설정하여 공백 상태 방지
      if (mounted) {
        final nameJson = widget.goonghap.artist.name;
        final title = getBestLocaleText(nameJson, context);
        ref
            .read(navigationInfoProvider.notifier)
            .setPageTitle(pageTitle: title);
      }
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

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref
          .read(goonghapProvider.notifier)
          .loadGoonghap(widget.goonghap.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;

      if (widget.goonghap.isPending) {
        ref.read(goonghapLoadingProvider.notifier).set(true);
      }

      if (widget.goonghap.isCompleted) {
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
          .read(goonghapProvider.notifier)
          .loadGoonghap(widget.goonghap.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;
    } catch (e, stack) {
      logger.e(
        'Error refreshing goonghap data',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _updateNavigation() {
    Future(() {
      // Future 콜백 내에서 mounted 체크
      if (mounted) {
        // 아티스트 이름이 로케일에 없을 경우 다국어 키를 순회하여 안전하게 타이틀 생성
        String safeArtistTitle() {
          final nameJson = widget.goonghap.artist.name;
          String title = getLocaleTextFromJson(nameJson, context).trim();
          if (title.isEmpty) {
            const fallbacks = [
              'ko',
              'en',
              'ja',
              'id',
              'th',
              'vi',
              'fil',
              'zh',
              'zh-cn',
              'zh-tw',
            ];
            for (final lc in fallbacks) {
              title = getLocaleTextFromJsonWithLocale(nameJson, lc).trim();
              if (title.isNotEmpty) break;
            }
          }
          if (title.isEmpty) {
            title = 'Artist';
          }
          return title;
        }

        ref
            .read(navigationInfoProvider.notifier)
            .settingNavigation(
              showPortal: true,
              showTopMenu: true,
              showMyPoint: false,
              topRightMenu: TopRightType.none,
              showBottomNavigation: false,
              pageTitle: safeArtistTitle(),
            );
      }
    });
  }

  Widget _buildResultContent(GoonghapModel goonghap) {
    return GoonghapResultContent(
      goonghap: goonghap,
      isSaving: _isSaving,
      onSave: _handleSave,
      onShare: _handleShare,
      onOpenGoonghap: _openGoonghap,
    );
  }

  String _currentLanguageCode() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode.toLowerCase();
    final country = (locale.countryCode ?? '').toUpperCase();
    // Normalize to backend codes: e.g., zh-CN / zh-TW
    if (language == 'zh') {
      if (country == 'CN') return 'zh-CN';
      if (country == 'TW') return 'zh-TW';
      return 'zh';
    }
    // bn_BD -> bn
    if (language == 'bn') return 'bn';
    return language;
  }

  void _openGoonghap(String goonghapId) async {
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

      final userProfile = await ref
          .read(userInfoProvider.notifier)
          .getUserProfiles();

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
              Navigator.of(context).pop();
            }
          },
        );
        return;
      }

      if ((userProfile.starCandy ?? 0) < 100) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          title: AppLocalizations.of(context).fortune_lack_of_star_candy_title,
          content: AppLocalizations.of(
            context,
          ).fortune_lack_of_star_candy_message,
          onOk: () {
            if (mounted) {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCommunityCurrentPage(StorePage());
              Navigator.of(context).pop();
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

      await supabase.functions.invoke(
        'open-goonghap',
        body: {'userId': userProfile.id, 'goonghapId': goonghapId},
      );

      // Supabase 함수 호출 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      final updatedProfile = await ref
          .read(userInfoProvider.notifier)
          .getUserProfiles();

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
            Text(AppLocalizations.of(context).goonghap_remain_star_candy),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  package: 'picnic_lib',
                  'assets/icons/store/star_100.png',
                  width: 36,
                ),
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
      logger.e('Error opening goonghap', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(
          AppLocalizations.of(context).message_error_occurred,
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // 외부에서 pageTitle이 비워지는 경우를 복구 (build 내에서만 listen)
      ref.listen(navigationInfoProvider.select((s) => s.pageTitle), (
        previous,
        next,
      ) {
        if (!mounted) return;
        if (next.isEmpty) {
          final nameJson = widget.goonghap.artist.name;
          final title = getBestLocaleText(nameJson, context);
          ref
              .read(navigationInfoProvider.notifier)
              .setPageTitle(pageTitle: title);
        }
      });

      final goonghapState = ref.watch(goonghapProvider);

      // 타이틀은 didChangeDependencies -> _updateNavigation 에서만 설정 (build에서는 설정하지 않음)

      return goonghapState.when(
        data: (goonghap) {
          if (goonghap == null) {
            return _buildLoadingIndicator();
          }

          // i18n 누락 시 엣지 함수 호출(포스트 프레임, 1회 가드)
          final lang = _currentLanguageCode();
          final hasCurrent = goonghap.getLocalizedResult(lang) != null;
          final needsI18n = goonghap.isCompleted && !hasCurrent;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted || _invokingI18n) return;
            try {
              if (needsI18n) {
                _invokingI18n = true;
                if (mounted) {
                  setState(() {
                    _isLoadingI18n = true;
                  });
                }
                await supabase.functions.invoke(
                  'goonghap-i18n',
                  body: {
                    'goonghap_id': goonghap.id,
                    'language': lang,
                  },
                );
                await ref
                    .read(goonghapProvider.notifier)
                    .loadGoonghap(goonghap.id, forceRefresh: true);
              }
            } catch (e, s) {
              logger.e(
                'goonghap-i18n invoke failed',
                error: e,
                stackTrace: s,
              );
            } finally {
              _invokingI18n = false;
              if (mounted) {
                setState(() {
                  _isLoadingI18n = false;
                });
              }
            }
          });

          // 번역 로딩 중이면 로딩 인디케이터 표시
          if (needsI18n && (_isLoadingI18n || !hasCurrent)) {
            return _buildI18nLoadingIndicator(goonghap);
          }

          return CustomScrollView(
            controller: _scrollController, // Add the ScrollController here

            slivers: [
              SliverToBoxAdapter(
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
                        RepaintBoundary(
                          key: _shareKey,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _isSharing
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary500.withValues(
                                          alpha: .7,
                                        ),
                                        AppColors.secondary500.withValues(
                                          alpha: .7,
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: 24),
                                GoonghapLogoWidget(),
                                SizedBox(height: 36),
                                GoonghapCard(
                                  artist: goonghap.artist,
                                  birthDate: goonghap.birthDate,
                                  birthTime: goonghap.birthTime,
                                  gender: goonghap.gender,
                                  goonghap: goonghap,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (goonghap.hasError)
                                GoonghapErrorView(
                                  error:
                                      goonghap.errorMessage ??
                                      AppLocalizations.of(
                                        context,
                                      ).error_unknown,
                                )
                              else if (goonghap.isCompleted)
                                _buildResultContent(goonghap),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
      logger.e(
        'Error building goonghap result page',
        error: e,
        stackTrace: stack,
      );
      return Center(
        child: Text(
          'Error: $e',
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(child: MediumPulseLoadingIndicator());
  }

  Widget _buildI18nLoadingIndicator(GoonghapModel goonghap) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
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
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              GoonghapLogoWidget(),
              SizedBox(height: 36),
              GoonghapCard(
                artist: goonghap.artist,
                birthDate: goonghap.birthDate,
                birthTime: goonghap.birthTime,
                gender: goonghap.gender,
                goonghap: goonghap,
              ),
              const SizedBox(height: 48),
              // 번역 로딩 인디케이터
              MediumPulseLoadingIndicator(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).loading,
                style: getTextStyle(AppTypo.body14R, AppColors.grey00),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<Future<bool>> _handleSave(GoonghapModel goonghap) async {
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

  Future<Future<bool>> _handleShare(GoonghapModel goonghap) async {
    logger.i('Share to Twitter');
    final artistName = getLocaleTextFromJson(
      goonghap.artist.name,
      context,
    );
    final hashtag = AppLocalizations.of(context).goonghap_share_hashtag;
    logger.d('🎯 해시태그 - 아티스트 이름: "$artistName", 결과: "$hashtag"');

    return ShareUtils.shareToSocial(
      _shareKey,
      message: _shareMessage,
      hashtag: hashtag,
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(goonghap.artist.name, context),
        '${Environment.appLinkPrefix}/community/goonghap/${goonghap.artist.id}',
      ),
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
