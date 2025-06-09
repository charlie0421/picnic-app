// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart'
    show showRequireLoginDialog;
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_artist_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class MyPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_mypage';

  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: t('page_title_mypage'));

      // 앱 시작 시 언어 설정 확인
      final currentLanguage = ref.read(appSettingProvider).language;
      logger.i('앱 시작 시 언어 설정: $currentLanguage');
    });
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
            body: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView(
                children: [
                  const SizedBox(height: 24),
                  // 프로필
                  data != null ? _buildProfile() : _buildNonLogin(),
                  // 캔디 정보
                  supabase.isLogged
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: StarCandyInfoText(
                              alignment: MainAxisAlignment.start))
                      : const SizedBox(height: 16),
                  Text(t('label_setting_language'),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  _buildLanguageSelector(),
                  const Divider(color: AppColors.grey200),
                  // 공지사항
                  PicnicListItem(
                      leading: t('label_mypage_notice'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () => ref
                          .read(navigationInfoProvider.notifier)
                          .setCurrentMyPage(const NoticePage())),
                  // FAQ
                  PicnicListItem(
                      leading: t('label_mypage_faq'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () => ref
                          .read(navigationInfoProvider.notifier)
                          .setCurrentMyPage(const FAQPage())),
                  // 충전내역
                  if (data != null && (data.isAdmin ?? false))
                    PicnicListItem(
                        leading: t('label_mypage_charge_history'),
                        assetPath: 'assets/icons/arrow_right_style=line.svg',
                        onTap: () {}),
                  // 고객센터
                  PicnicListItem(
                      leading: t('label_mypage_customer_center'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () {
                        _launchURL('https://forms.gle/VPfgdt2JSMyBisps5');
                      }),
                  PicnicListItem(
                      leading: t('label_mypage_setting'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () => ref
                          .read(navigationInfoProvider.notifier)
                          .setCurrentMyPage(const SettingPage())),
                  // 나의 아티스트
                  _buildMyArtist('VOTE'),
                  const Divider(color: AppColors.grey200),
                  // 투표내역
                  PicnicListItem(
                      leading: t('label_mypage_vote_history'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () => data != null
                          ? ref
                              .read(navigationInfoProvider.notifier)
                              .setCurrentMyPage(const VoteHistoryPage())
                          : showRequireLoginDialog()),
                  // _buildMyStar('PIC'),
                  // const Divider(color: AppColors.Grey200),
                  // ListItem(
                  //     leading: t('label_mypage_membership_history,
                  //     assetPath: 'assets/icons/arrow_right_style=line.svg',
                  //     onTap: () {}),
                ],
              ),
            ),
          );
        },
        loading: () => ui.buildLoadingOverlay(),
        error: (error, stackTrace) => Container());
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
              colorFilter: const ColorFilter.mode(
                AppColors.grey00,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(t('label_mypage_should_login'),
              style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
          SizedBox(width: 16.w),
          SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/setting_style=line.svg',
              width: 20.w,
              height: 20.w,
              colorFilter: const ColorFilter.mode(
                AppColors.grey900,
                BlendMode.srcIn,
              )),
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
                Text(
                  data?.nickname ?? '',
                  style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset(
                    package: 'picnic_lib',
                    'assets/icons/setting_style=line.svg',
                    width: 20.w,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.grey900,
                      BlendMode.srcIn,
                    )),
              ],
            );
          },
          loading: () => ui.buildLoadingOverlay(),
          error: (error, stack) {
            return Text('Error: $error');
          },
        ),
      ),
    );
  }

  Widget _buildMyArtist(String categoryText) {
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        logger.i('🎯 나의 아티스트 탭 clicked');
        if (!supabase.isLogged) {
          logger.i('🎯 User not logged in, navigating to signup');
          Navigator.of(context).pushNamed(SignUpScreen.routeName);
        } else {
          logger.i('🎯 User logged in, setting VoteArtistPage');
          ref
              .read(navigationInfoProvider.notifier)
              .setCurrentMyPage(const VoteArtistPage());
          logger.i('🎯 VoteArtistPage set successfully');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryText, style: getTextStyle(AppTypo.body14B)),
                    Text(t('label_mypage_my_artist'),
                        style: getTextStyle(AppTypo.body16M)),
                  ],
                ),
                SvgPicture.asset(
                    package: 'picnic_lib',
                    'assets/icons/arrow_right_style=line.svg',
                    width: 20.w,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.grey900,
                      BlendMode.srcIn,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          supabase.isLogged
              ? SizedBox(
                  height: 80,
                  child: bookmarkedArtists.when(
                    data: (artists) {
                      if (artists.isEmpty) {
                        return Container(
                          alignment: Alignment.center,
                          child: Text(t('label_mypage_no_artist'),
                              style: getTextStyle(
                                  AppTypo.title18B, AppColors.primary500)),
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
                    error: (error, stack) => Text('Error: $error'),
                  ),
                )
              : Container(
                  alignment: Alignment.center,
                  child: Text(t('label_mypage_should_login'),
                      style:
                          getTextStyle(AppTypo.title18B, AppColors.primary500)),
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
        ));
  }

  void _launchURL(String targetUrl) async {
    Uri url = Uri.parse(targetUrl);
    if (await canLaunchUrl(url)) {
      try {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // WebView 대신 외부 브라우저 사용
        );
      } catch (e, s) {
        logger.e('_launchURL:', error: e, stackTrace: s);
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  // 언어 선택기 위젯
  Widget _buildLanguageSelector() {
    // 현재 언어를 미리 읽어둠
    final currentLanguage = ref.read(appSettingProvider).language;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.grey00,
          useSafeArea: true,
          builder: (context) {
            // 바텀시트 내에서 현재 언어 값을 상태로 관리
            return StatefulBuilder(
              builder: (context, setState) {
                // 로컬 상태로 현재 선택된 언어 관리
                String selectedLanguage = currentLanguage;

                void onLanguageSelected(String langCode) {
                  // 같은 언어 선택 시 무시
                  if (langCode == currentLanguage) {
                    Navigator.of(context).pop();
                    return;
                  }

                  // 바텀시트 닫기
                  Navigator.of(context).pop();

                  // 약간의 지연 후 작업 수행
                  Future.delayed(const Duration(milliseconds: 50), () {
                    // 언어 변경 및 앱 재시작
                    ref.read(appSettingProvider.notifier).setLanguage(langCode);
                    PicnicLibL10n.setCurrentLocale(langCode);
                    if (context.mounted) {
                      Phoenix.rebirth(context);
                    }
                    logger.i('⭐ 언어 변경 완료: $langCode');
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(t('title_select_language'),
                          style:
                              getTextStyle(AppTypo.body16B, AppColors.grey900)),
                    ),
                    Divider(height: 1, color: AppColors.grey100),
                    _buildLanguageOptionItem(context, 'ko', '한국어',
                        selectedLanguage, onLanguageSelected),
                    _buildLanguageOptionItem(context, 'en', 'English',
                        selectedLanguage, onLanguageSelected),
                    _buildLanguageOptionItem(context, 'ja', '日本語',
                        selectedLanguage, onLanguageSelected),
                    _buildLanguageOptionItem(context, 'zh', '中文',
                        selectedLanguage, onLanguageSelected),
                    _buildLanguageOptionItem(context, 'id', 'Indonesia',
                        selectedLanguage, onLanguageSelected),
                    SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageMap[currentLanguage] ?? 'Unknown',
              style: getTextStyle(AppTypo.body14M, AppColors.grey900),
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
  Widget _buildLanguageOptionItem(BuildContext context, String langCode,
      String label, String currentLanguage, Function(String) onSelect) {
    final isSelected = langCode == currentLanguage;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(langCode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        color: isSelected ? AppColors.grey100 : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: getTextStyle(
                isSelected ? AppTypo.body14B : AppTypo.body14M,
                isSelected ? AppColors.grey900 : AppColors.grey600,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.grey900, size: 20),
          ],
        ),
      ),
    );
  }
}
