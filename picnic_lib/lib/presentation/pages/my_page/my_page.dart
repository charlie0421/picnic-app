// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart'
    show showRequireLoginDialog;
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_list_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_artist_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/admin_menu_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';

class MyPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_mypage';

  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage>
    with RouteAwareStateMixin<MyPage>, SingleTickerProviderStateMixin {
  String? _currentTitle;

  /// 파우치 새로고침 아이콘 회전. 스토어·무료충전소와 같은 800ms.
  late final AnimationController _pouchRefreshController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  @override
  void dispose() {
    _pouchRefreshController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).page_title_mypage;
      _updateNavigation();

      // 앱 시작 시 언어 설정 확인
      final currentLanguage = ref.read(appSettingProvider).language;
      logger.i('앱 시작 시 언어 설정: $currentLanguage');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).page_title_mypage;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoState = ref.watch(userInfoProvider);

    ref.listen(userInfoProvider, (previous, state) {
      if (state is AsyncData<UserProfilesModel?>) {
        ref
            .read(asyncBookmarkedArtistsProvider.notifier)
            .refreshBookmarkedArtists();
      }
    });

    return userInfoState.when(
      data: (data) {
        return Scaffold(
          backgroundColor: PicnicUi.surface,
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
            child: ListView(
              children: [
                const SizedBox(height: 24),
                // 프로필
                data != null ? _buildProfile() : _buildNonLogin(),
                const SizedBox(height: 16),
                // 파우치는 공통 위젯. 새로고침은 스토어·무료충전소와 같은 동작
                // (프로필 + 지갑 요약 재조회) — 여기만 빠져 있었다 (PICNIC-2689).
                StorePointInfo(
                  title: AppLocalizations.of(context).label_star_candy_pouch,
                  width: double.infinity,
                  refreshController: _pouchRefreshController,
                  onRefresh: data == null
                      ? null
                      : () {
                          _pouchRefreshController.forward(from: 0);
                          ref.read(userInfoProvider.notifier).getUserProfiles();
                          ref.read(walletSummaryProvider.notifier).refresh();
                        },
                ),
                const SizedBox(height: 16),

                // Language
                Text(
                  AppLocalizations.of(context).label_setting_language,
                  style: PicnicUi.text(
                    weight: FontWeight.w700,
                    color: PicnicUi.secondaryText,
                  ),
                ),
                _buildLanguageSelector(),
                Divider(color: PicnicUi.border),

                // My artist
                _buildMyArtist(),
                Divider(color: PicnicUi.border),

                // Notice
                PicnicListItem(
                  leading: AppLocalizations.of(context).label_mypage_notice,
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: () => ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const NoticePage()),
                ),
                // FAQ
                PicnicListItem(
                  leading: AppLocalizations.of(context).label_mypage_faq,
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: () => ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const FAQPage()),
                ),
                // Notifications
                if (data != null)
                  PicnicListItem(
                    leading: AppLocalizations.of(
                      context,
                    ).label_mypage_notifications,
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: () => ref
                        .read(navigationInfoProvider.notifier)
                        .setCurrentMyPage(
                          const NotificationsPage(
                            mode: NotificationsPageMode.embedded,
                          ),
                        ),
                  ),
                // QnA
                if (data != null && data.id != null)
                  PicnicListItem(
                    leading: "QnA",
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: () => ref
                        .read(navigationInfoProvider.notifier)
                        .setCurrentMyPage(QnaThreadListPage(userId: data.id!)),
                  ),

                if (data?.id != null)
                  PicnicListItem(
                    key: const Key('my-page-currency-history'),
                    leading: AppLocalizations.of(context).wallet_history_title,
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: () => ref
                        .read(navigationInfoProvider.notifier)
                        .setCurrentMyPage(const CurrencyHistoryPage()),
                  ),

                // Voting History
                PicnicListItem(
                  leading: AppLocalizations.of(context).label_my_vote_history,
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: () => data != null
                      ? ref
                            .read(navigationInfoProvider.notifier)
                            .setCurrentMyPage(const VoteHistoryPage())
                      : showRequireLoginDialog(),
                ),

                // Setting
                PicnicListItem(
                  leading: AppLocalizations.of(context).label_mypage_setting,
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: () => ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const SettingPage()),
                ),
                if (data?.hasAdminAccess ?? false)
                  PicnicListItem(
                    leading: '관리자',
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: () => ref
                        .read(navigationInfoProvider.notifier)
                        .setCurrentMyPage(const AdminMenuPage()),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => ui.buildLoadingOverlay(),
      error: (error, stackTrace) => Container(),
    );
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: title);
    });
  }

  Widget _buildNonLogin() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushNamed(SignUpScreen.routeName),
      child: Row(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(40),
            ),
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/header/default_avatar.svg',
              width: 80.w,
              height: 80.w,
              colorFilter: ColorFilter.mode(PicnicUi.surface, BlendMode.srcIn),
            ),
          ),
          SizedBox(width: 16.w),
          Flexible(
            child: Text(
              AppLocalizations.of(context).label_mypage_should_login,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PicnicUi.text(size: 18, weight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 16.w),
          SvgPicture.asset(
            package: 'picnic_lib',
            'assets/icons/setting_style=line.svg',
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(PicnicUi.ink, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final userInfo = ref.watch(userInfoProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref
          .read(navigationInfoProvider.notifier)
          .setCurrentMyPage(const MyProfilePage()),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: userInfo.when(
          data: (data) {
            return Row(
              children: [
                ProfileImageContainer(
                  avatarUrl: data?.avatarUrl,
                  width: 80,
                  height: 80,
                  borderRadius: 80.r,
                ),
                SizedBox(width: 16.w),
                Flexible(
                  child: Text(
                    data?.nickname ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PicnicUi.text(size: 18, weight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/setting_style=line.svg',
                  width: 20.w,
                  height: 20,
                  colorFilter: ColorFilter.mode(PicnicUi.ink, BlendMode.srcIn),
                ),
              ],
            );
          },
          loading: () => ui.buildLoadingOverlay(),
          error: (error, stack) {
            return PicnicFeedback(
              inline: true,
              icon: Icons.error_outline,
              message: AppLocalizations.of(context).message_error_occurred,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyArtist() {
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        logger.i('🎯 나의 아티스트 탭 clicked');
        if (!isSupabaseLoggedSafely) {
          logger.i('🎯 User not logged in, navigating to signup');
          Navigator.of(context).pushNamed(SignUpScreen.routeName);
        } else {
          logger.i('🎯 User logged in, setting MyArtistPage');
          ref
              .read(navigationInfoProvider.notifier)
              .setCurrentMyPage(const MyArtistPage());
          logger.i('🎯 MyArtistPage set successfully');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A 48 minimum and a Flexible title (PICNIC-2738): at 2.0x on a 360dp
          // screen the longest translation pushed the arrow off the row, and
          // once it wraps it needs more than a fixed 48.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).label_mypage_my_artist,
                        style: PicnicUi.text(size: 16, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/arrow_right_style=line.svg',
                  width: 20.w,
                  height: 20,
                  colorFilter: ColorFilter.mode(PicnicUi.ink, BlendMode.srcIn),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          isSupabaseLoggedSafely
              ? SizedBox(
                  height: 80,
                  child: bookmarkedArtists.when(
                    data: (artists) {
                      if (artists.isEmpty) {
                        // The slot is a fixed 80 because the artist list and
                        // its shimmer scroll horizontally and need a bounded
                        // height. The empty message shares it, so it stays on
                        // one line and shrinks to fit when it would not:
                        // wrapped to two lines it needed 104px at 2.0x in the
                        // longest translations (PICNIC-2738).
                        return Container(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).label_mypage_no_artist,
                              maxLines: 1,
                              style: PicnicUi.text(
                                size: 18,
                                weight: FontWeight.w700,
                                color: PicnicUi.actionColor,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: artists.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            PicnicCachedNetworkImage(
                              imageUrl: artists[index].image ?? '',
                              width: 60,
                              height: 60,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ],
                        ),
                        separatorBuilder: (BuildContext context, int index) {
                          return SizedBox(width: 14.w);
                        },
                      );
                    },
                    loading: () => _buildShimmer(),
                    error: (error, stack) => PicnicFeedback(
                      inline: true,
                      icon: Icons.error_outline,
                      message: AppLocalizations.of(
                        context,
                      ).message_error_occurred,
                    ),
                  ),
                )
              : Container(
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context).label_mypage_should_login,
                    style: PicnicUi.text(
                      size: 18,
                      weight: FontWeight.w700,
                      color: PicnicUi.actionColor,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: ListView.separated(
        itemCount: 5,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ],
        ),
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(width: 14.w);
        },
      ),
    );
  }

  // 언어 선택기 위젯
  Widget _buildLanguageSelector() {
    final currentLanguage = ref.read(appSettingProvider).language;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: PicnicUi.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          useSafeArea: true,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                final entries = languageMap.entries.toList();
                final isWide = MediaQuery.of(context).size.width > 480;

                void handleSelect(String langCode) async {
                  if (langCode == currentLanguage) {
                    Navigator.of(context).pop();
                    return;
                  }
                  try {
                    Navigator.of(context).pop();

                    // DB에 언어 업데이트 (비동기)
                    try {
                      await ref
                          .read(userInfoProvider.notifier)
                          .updateLanguage(langCode);
                    } catch (e) {
                      // DB 업데이트 실패는 로그만 남기고 계속 진행 (앱 동작에는 영향 없음)
                      logger.w('user_profiles.language 업데이트 실패', error: e);
                    }

                    // 로컬 스토리지에 언어 저장
                    ref.read(appSettingProvider.notifier).setLanguage(langCode);

                    // 앱 재시작하여 새 언어 적용
                    if (!context.mounted) return;
                    Phoenix.rebirth(context);
                  } catch (e, stackTrace) {
                    logger.e('언어 변경 중 오류 발생', error: e, stackTrace: stackTrace);
                    if (mounted && context.mounted) {
                      SnackbarUtil().error(
                        '언어 변경 중 오류가 발생했습니다.',
                        context: context,
                      );
                    }
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PicnicUi.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context).title_select_language,
                        style: PicnicUi.text(size: 16, weight: FontWeight.w700),
                      ),
                    ),
                    Divider(height: 1, color: PicnicUi.border),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        // Two columns on wide screens. The cells keep the
                        // grid's old 3.8:1 size as a minimum but may grow:
                        // a fixed aspect ratio cut the names from 2.0x on a
                        // 500dp screen and at 2.6x on every width.
                        child: isWide
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  const spacing = 4.0;
                                  final cellWidth =
                                      (constraints.maxWidth - spacing) / 2;
                                  Widget cell(int index) => ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: cellWidth / 3.8,
                                    ),
                                    child: _buildLanguageOptionItem(
                                      context,
                                      entries[index].key,
                                      entries[index].value,
                                      currentLanguage,
                                      handleSelect,
                                    ),
                                  );
                                  // GridView applied the vertical safe-area
                                  // inset on its own; a plain scroll view
                                  // does not, and the sheet does not avoid the
                                  // bottom inset, so keep it explicitly.
                                  return SingleChildScrollView(
                                    padding: MediaQuery.paddingOf(
                                      context,
                                    ).copyWith(left: 0, right: 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < entries.length;
                                          i += 2
                                        ) ...[
                                          if (i > 0)
                                            const SizedBox(height: spacing),
                                          IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(child: cell(i)),
                                                const SizedBox(width: spacing),
                                                Expanded(
                                                  child: i + 1 < entries.length
                                                      ? cell(i + 1)
                                                      : const SizedBox(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: entries.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: PicnicUi.vertical(4)),
                                itemBuilder: (context, index) {
                                  final e = entries[index];
                                  return _buildLanguageOptionItem(
                                    context,
                                    e.key,
                                    e.value,
                                    currentLanguage,
                                    handleSelect,
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            );
          },
        );
      },
      child: PicnicSurface(
        radius: 8,
        padding: EdgeInsets.symmetric(
          vertical: PicnicUi.vertical(12),
          horizontal: PicnicUi.horizontal(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageLabel(currentLanguage),
              style: PicnicUi.text(weight: FontWeight.w500),
            ),
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/arrow_down_style=line.svg',
            ),
          ],
        ),
      ),
    );
  }

  // 언어 옵션 아이템 (바텀시트 내부용)
  Widget _buildLanguageOptionItem(
    BuildContext context,
    String langCode,
    String label,
    String currentLanguage,
    Function(String) onSelect,
  ) {
    final isSelected = langCode == currentLanguage;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(langCode),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        child: PicnicSurface(
          radius: 8,
          color: isSelected
              ? AppColors.primary500.withValues(alpha: 0.06)
              : PicnicUi.surface,
          padding: EdgeInsets.symmetric(
            vertical: PicnicUi.vertical(12),
            horizontal: PicnicUi.horizontal(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: PicnicUi.text(
                    weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? PicnicUi.ink : PicnicUi.secondaryText,
                  ),
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: PicnicUi.horizontal(8)),
                Icon(Icons.check, color: PicnicUi.ink, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
