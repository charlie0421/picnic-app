import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/common/myprofile.dart';
import 'package:picnic_app/pages/common/setting.dart';
import 'package:picnic_app/pages/vote/vote_history_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class MyPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_mypage';

  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView(
          children: [
            SizedBox(height: 24.w),
            _buildProfile(),
            SizedBox(height: 24.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                    width: 144.w, height: 36.w, child: const CommonMyPoint()),
              ],
            ),
            SizedBox(height: 24.w),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_notice,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {}),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_charge_history,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {}),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_customer_center,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {}),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_setting,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const SettingPage())),
            const Divider(color: AppColors.Grey200),
            _buildMyStar('VOTE'),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_vote_history,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const VoteHistoryPage())),
            const Divider(color: AppColors.Grey200),
            _buildMyStar('P-RAME'),
            const Divider(color: AppColors.Grey200),
            ListItem(
                leading: S.of(context).label_mypage_membership_history,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {}),
          ],
        ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(80).r,
                  child: CachedNetworkImage(
                    imageUrl: data?.avatar_url ?? '',
                    placeholder: (context, url) => buildPlaceholderImage(),
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                  ),
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
    return Column(
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
                  Text(S.of(context).label_mypage_mystar,
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
    );
  }
}
