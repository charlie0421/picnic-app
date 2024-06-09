import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:load_switch/load_switch.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';

class SettingPage extends ConsumerStatefulWidget {
  String pageName = Intl.message('page_title_setting');

  SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool value1 = false;
  bool value2 = false;

  Future<bool> _getFuture1() async {
    await Future.delayed(const Duration(seconds: 1));
    return !value1;
  }

  Future<bool> _getFuture2() async {
    await Future.delayed(const Duration(seconds: 1));
    return !value2;
  }

  @override
  Widget build(BuildContext context) {
    final asyncPlatformInfoState = ref.watch(platformInfoProvider);
    final appSettingState = ref.watch(appSettingProvider);
    final appSettingNotifier = ref.read(appSettingProvider.notifier);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          SizedBox(height: 16.h),
          Text('알림', style: getTextStyle(AppTypo.BODY14B, AppColors.Gray600)),
          SizedBox(height: 4.h),
          ListItem(
            leading: '푸시알림',
            assetPath: 'assets/icons/right_arrow.svg',
            onTap: () {},
            tailing: LoadSwitch(
              width: 48.w,
              height: 28.h,
              value: value1,
              future: _getFuture1,
              style: SpinStyle.material,
              curveIn: Curves.easeInBack,
              curveOut: Curves.easeOutBack,
              animationDuration: const Duration(milliseconds: 500),
              thumbDecoration: (value, isActive) => BoxDecoration(
                gradient: switchThumbGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              switchDecoration: (
                value,
                isActive,
              ) =>
                  BoxDecoration(
                color: value ? AppColors.Primary500 : AppColors.Gray200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [switchBoxShadow],
              ),
              spinColor: (value) =>
                  value ? AppColors.Primary500 : AppColors.Primary500,
              spinStrokeWidth: 1,
              onChange: (v) {
                value1 = v;
                setState(() {});
              },
              onTap: (v) {},
            ),
          ),
          const Divider(color: AppColors.Gray200),
          ListItem(
            leading: '이벤트알림',
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '각종 이벤트나 행사를 안내드려요.',
                style: getTextStyle(AppTypo.CAPTION12R, AppColors.Gray600),
                textAlign: TextAlign.start,
              ),
            ),
            assetPath: 'assets/icons/right_arrow.svg',
            onTap: () {},
            tailing: LoadSwitch(
              width: 48.w,
              height: 28.h,
              value: value2,
              future: _getFuture2,
              style: SpinStyle.material,
              curveIn: Curves.easeInBack,
              curveOut: Curves.easeOutBack,
              animationDuration: const Duration(milliseconds: 500),
              thumbDecoration: (value, isActive) => BoxDecoration(
                gradient: switchThumbGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              switchDecoration: (
                value,
                isActive,
              ) =>
                  BoxDecoration(
                color: value ? AppColors.Primary500 : AppColors.Gray200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [switchBoxShadow],
              ),
              spinColor: (value) =>
                  value ? AppColors.Primary500 : AppColors.Primary500,
              spinStrokeWidth: 1,
              onChange: (v) {
                value2 = v;
                setState(() {});
              },
              onTap: (v) {},
            ),
          ),
          const Divider(color: AppColors.Gray200),
          SizedBox(height: 48.h),
          Text('언어설정', style: getTextStyle(AppTypo.BODY14B, AppColors.Gray600)),
          DropdownButtonFormField(
            value: appSettingState.locale.languageCode,
            icon: SvgPicture.asset('assets/icons/down_arrow.svg'),
            decoration: const InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.Gray00, width: 0),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
            ),
            dropdownColor: AppColors.Gray00,
            borderRadius: BorderRadius.circular(8),
            items: languageMap.entries.map((entry) {
              return DropdownMenuItem(
                alignment: Alignment.center,
                value: entry.key,
                child: Text(
                  entry.value,
                  style: appSettingState.locale.languageCode == entry.key
                      ? getTextStyle(AppTypo.BODY14B, AppColors.Gray900)
                      : getTextStyle(AppTypo.BODY14M, AppColors.Gray400),
                ),
              );
            }).toList(),
            onChanged: (value) {
              logger.d('value: $value');
              appSettingNotifier.setLocale(Locale(
                value!,
              ));
            },
          ),
          // [
          //   DropdownMenuItem(
          //     alignment: Alignment.center,
          //     value: 'ko',
          //     child: Text(
          //       '한국어',
          //       style: getTextStyle(AppTypo.BODY16M, AppColors.Gray900),
          //     ),
          //   ),
          //   DropdownMenuItem(
          //     alignment: Alignment.center,
          //     value: 'en',
          //     child: Text('English',
          //         style: getTextStyle(AppTypo.BODY16M, AppColors.Gray900)),
          //   ),
          // ],
          const Divider(color: AppColors.Gray200),
          SizedBox(height: 48.h),
          Text('저장공간 관리',
              style: getTextStyle(AppTypo.BODY14B, AppColors.Gray600)),
          ListItem(
              leading: '캐시메모리 삭제',
              assetPath: 'assets/icons/right_arrow.svg',
              onTap: () {}),
          const Divider(color: AppColors.Gray200),
          SizedBox(height: 48.h),
          Text('앱 정보', style: getTextStyle(AppTypo.BODY14B, AppColors.Gray600)),
          const Divider(color: AppColors.Gray200),
          ListItem(
              leading:
                  '현재 버전 ${asyncPlatformInfoState.value?.version ?? ''}(${asyncPlatformInfoState.value?.buildNumber ?? ''})',
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '업데이트',
                  style: getTextStyle(AppTypo.CAPTION12B, AppColors.Primary500),
                  textAlign: TextAlign.start,
                ),
              ),
              assetPath: 'assets/icons/right_arrow.svg',
              onTap: () {}),
        ],
      ),
    );
  }
}
