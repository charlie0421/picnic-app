import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/components/star_candy_info_text.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/mypage/myprofile.dart';
import 'package:picnic_app/pages/mypage/setting.dart';
import 'package:picnic_app/pages/mypage/vote_my_artist.dart';
import 'package:picnic_app/pages/vote/vote_history_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_mypage';

  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  Widget build(BuildContext context) {
    final userInfoState = ref.watch(userInfoProvider);

    return userInfoState.when(
        data: (data) => Scaffold(
              body: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ListView(
                  children: [
                    SizedBox(height: 24.h),
                    // 프로필
                    data != null ? _buildProfile() : _buildNonLogin(),
                    // 캔디 정보
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: StarCandyInfoText(
                            alignment: MainAxisAlignment.start)),
                    const Divider(color: AppColors.Grey200),
                    // 공지사항
                    if (data != null && data.is_admin)
                      ListItem(
                          leading: S.of(context).label_mypage_notice,
                          assetPath: 'assets/icons/arrow_right_style=line.svg',
                          onTap: () {}),
                    if (data != null && data.is_admin)
                      const Divider(color: AppColors.Grey200),
                    // 충전내역
                    if (data != null && data.is_admin)
                      ListItem(
                          leading: S.of(context).label_mypage_charge_history,
                          assetPath: 'assets/icons/arrow_right_style=line.svg',
                          onTap: () {}),
                    if (data != null && data.is_admin)
                      const Divider(color: AppColors.Grey200),
                    // 고객센터
                    ListItem(
                        leading: S.of(context).label_mypage_customer_center,
                        assetPath: 'assets/icons/arrow_right_style=line.svg',
                        onTap: () {
                          _launchURL('https://forms.gle/VPfgdt2JSMyBisps5');
                        }),
                    const Divider(color: AppColors.Grey200),
                    // 설정
                    ListItem(
                        leading: S.of(context).label_mypage_setting,
                        assetPath: 'assets/icons/arrow_right_style=line.svg',
                        onTap: () => ref
                            .read(navigationInfoProvider.notifier)
                            .setCurrentMyPage(const SettingPage())),
                    const Divider(color: AppColors.Grey200),
                    // 나의 아티스트
                    if (data != null && data.is_admin) _buildMyStar('VOTE'),
                    if (data != null && data.is_admin)
                      const Divider(color: AppColors.Grey200),
                    // 투표내역
                    ListItem(
                        leading: S.of(context).label_mypage_vote_history,
                        assetPath: 'assets/icons/arrow_right_style=line.svg',
                        onTap: () => data != null
                            ? ref
                                .read(navigationInfoProvider.notifier)
                                .setCurrentMyPage(const VoteHistoryPage())
                            : showRequireLoginDialog(context: context)),
                    const Divider(color: AppColors.Grey200),
                    // _buildMyStar('PIC'),
                    // const Divider(color: AppColors.Grey200),
                    // ListItem(
                    //     leading: S.of(context).label_mypage_membership_history,
                    //     assetPath: 'assets/icons/arrow_right_style=line.svg',
                    //     onTap: () {}),
                  ],
                ),
              ),
            ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) => Container());
  }

  Widget _buildNonLogin() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(SignUpScreen.routeName),
      child: Row(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            padding: const EdgeInsets.all(6).r,
            decoration: BoxDecoration(
              color: AppColors.Grey200,
              borderRadius: BorderRadius.circular(40).r,
            ),
            child: SvgPicture.asset(
              'assets/icons/header/default_avatar.svg',
              width: 80.w,
              height: 80.w,
              colorFilter: const ColorFilter.mode(
                AppColors.Grey00,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(S.of(context).label_mypage_should_login,
              style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
          SizedBox(width: 16.w),
          SvgPicture.asset('assets/icons/setting_style=line.svg',
              width: 20.w,
              height: 20.w,
              colorFilter: const ColorFilter.mode(
                AppColors.Grey900,
                BlendMode.srcIn,
              )),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final userInfo = ref.watch(userInfoProvider);
    return GestureDetector(
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
                  avatarUrl: data?.avatar_url,
                  width: 80.w,
                  height: 80.w,
                  borderRadius: 80.w,
                ),
                SizedBox(width: 16.w),
                Text(
                  data?.nickname ?? '',
                  style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900),
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset('assets/icons/setting_style=line.svg',
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.Grey900,
                      BlendMode.srcIn,
                    )),
              ],
            );
          },
          loading: () => buildLoadingOverlay(),
          error: (error, stack) {
            return Text('Error: $error');
          },
        ),
      ),
    );
  }

  Widget _buildMyStar(String categoryText) {
    return GestureDetector(
      onTap: () {
        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentMyPage(const VoteMyArtist());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryText, style: getTextStyle(AppTypo.BODY14B)),
                    Text(S.of(context).label_mypage_my_artist,
                        style: getTextStyle(AppTypo.BODY16M)),
                  ],
                ),
                SvgPicture.asset('assets/icons/arrow_right_style=line.svg',
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.Grey900,
                      BlendMode.srcIn,
                    )),
              ],
            ),
          ),
          SizedBox(height: 16.w),
          SizedBox(
            width: double.infinity,
            height: 80.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 80.w,
                  height: 80.w,
                  margin: EdgeInsets.only(right: 14.w),
                  child: CircleAvatar(
                    radius: 30.w,
                    backgroundColor: AppColors.Grey200,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String targetUrl) async {
    Uri url = Uri.parse(targetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );
    } else {
      throw 'Could not launch $url';
    }
  }
}
