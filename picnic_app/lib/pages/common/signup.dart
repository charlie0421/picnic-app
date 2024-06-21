import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class SignUpPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_myprofile';

  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SignUpPage> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          SizedBox(height: 24.w),
          Container(
            width: 100.w,
            height: 100.w,
            alignment: Alignment.center,
            child: Stack(
              children: [
                SizedBox(
                  width: 100.w,
                  height: 100.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.w),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                        imageUrl: userInfo.value?.avatar_url ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => buildPlaceholderImage(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                      width: 24.w,
                      height: 24.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.Primary500,
                        borderRadius: BorderRadius.circular(50.w),
                      ),
                      child:
                          SvgPicture.asset('assets/icons/camera_style=line.svg',
                              width: 16.w,
                              height: 16.w,
                              colorFilter: const ColorFilter.mode(
                                AppColors.Grey00,
                                BlendMode.srcIn,
                              ))),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 57.w),
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: '닉네임을 입력하세요',
                hintStyle: getTextStyle(AppTypo.BODY14B, AppColors.Grey300),
                fillColor: AppColors.Grey00,
                labelStyle: getTextStyle(AppTypo.BODY14B, AppColors.Grey900),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.w),
                  borderSide: BorderSide(color: AppColors.Primary500),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.w),
                  borderSide: BorderSide(color: AppColors.StatusError),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                suffixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/pencil_style=fill.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.Grey700,
                        BlendMode.srcIn,
                      )),
                  onPressed: () {
                    _textEditingController.clear();
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 26.w),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: Intl.message('label_mypage_terms_of_use'),
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {}),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: Intl.message('label_mypage_privacy_policy'),
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {}),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: Intl.message('label_mypage_logout'),
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref.read(userInfoProvider.notifier).logout();
                Navigator.of(context).pop();
              }),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: Intl.message('label_mypage_withdrawal'),
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {}),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
        ],
      ),
    );
  }
}
