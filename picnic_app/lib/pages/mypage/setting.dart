import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:load_switch/load_switch.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';

class SettingPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_setting';

  const SettingPage({super.key});

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
          SizedBox(height: 16.w),
          Text(S.of(context).label_setting_alarm,
              style: getTextStyle(AppTypo.BODY14B, AppColors.Grey600)),
          SizedBox(height: 4.w),
          ListItem(
            leading: S.of(context).label_setting_push_alarm,
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            tailing: LoadSwitch(
              width: 48.w,
              height: 28.w,
              value: value1,
              future: _getFuture1,
              style: SpinStyle.material,
              curveIn: Curves.easeInBack,
              curveOut: Curves.easeOutBack,
              animationDuration: const Duration(milliseconds: 500),
              thumbDecoration: (value, isActive) => BoxDecoration(
                gradient: switchThumbGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              switchDecoration: (
                value,
                isActive,
              ) =>
                  BoxDecoration(
                color: value ? AppColors.Primary500 : AppColors.Grey200,
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
          const Divider(color: AppColors.Grey200),
          ListItem(
            leading: S.of(context).label_setting_event_alarm,
            title: Container(
              margin: EdgeInsets.only(left: 8.w),
              alignment: Alignment.centerLeft,
              child: Text(
                S.of(context).label_setting_event_alarm_desc,
                style: getTextStyle(AppTypo.CAPTION12R, AppColors.Grey600),
                textAlign: TextAlign.start,
              ),
            ),
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            tailing: LoadSwitch(
              width: 48.w,
              height: 28.w,
              value: value2,
              future: _getFuture2,
              style: SpinStyle.material,
              curveIn: Curves.easeInBack,
              curveOut: Curves.easeOutBack,
              animationDuration: const Duration(milliseconds: 500),
              thumbDecoration: (value, isActive) => BoxDecoration(
                gradient: switchThumbGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              switchDecoration: (
                value,
                isActive,
              ) =>
                  BoxDecoration(
                color: value ? AppColors.Primary500 : AppColors.Grey200,
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
          const Divider(color: AppColors.Grey200),
          SizedBox(height: 48.w),
          Text(S.of(context).label_setting_language,
              style: getTextStyle(AppTypo.BODY14B, AppColors.Grey600)),
          DropdownButtonFormField(
            value: appSettingState.locale.languageCode,
            icon: SvgPicture.asset('assets/icons/arrow_down_style=line.svg'),
            decoration: const InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.Grey00, width: 0),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
            ),
            dropdownColor: AppColors.Grey00,
            borderRadius: BorderRadius.circular(8),
            items: languageMap.entries.map((entry) {
              return DropdownMenuItem(
                alignment: Alignment.center,
                value: entry.key,
                child: Text(
                  entry.value,
                  style: appSettingState.locale.languageCode == entry.key
                      ? getTextStyle(AppTypo.BODY14B, AppColors.Grey900)
                      : getTextStyle(AppTypo.BODY14M, AppColors.Grey400),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (appSettingState.locale.languageCode == value) return;
              appSettingNotifier.setLocale(Locale(
                value!,
                countryMap[value] ?? '',
              ));
            },
          ),
          const Divider(color: AppColors.Grey200),
          SizedBox(height: 48.w),
          Text(S.of(context).label_setting_storage,
              style: getTextStyle(AppTypo.BODY14B, AppColors.Grey600)),
          ListItem(
              leading: S.of(context).label_setting_remove_cache,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () async {
                OverlayLoadingProgress.start(context);
                final cacheManager = DefaultCacheManager();
                await cacheManager.emptyCache();
                OverlayLoadingProgress.stop();
                showSimpleDialog(
                    title: S.of(context).label_setting_remove_cache,
                    context: context,
                    content: S.of(context).label_setting_remove_cache,
                    onOk: () {});
              }),
          const Divider(color: AppColors.Grey200),
          SizedBox(height: 48.w),
          Text(S.of(context).label_setting_appinfo,
              style: getTextStyle(AppTypo.BODY14B, AppColors.Grey600)),
          const Divider(color: AppColors.Grey200),
          ListItem(
              leading:
                  '${S.of(context).label_setting_current_version} ${asyncPlatformInfoState.value?.version ?? ''}(${asyncPlatformInfoState.value?.buildNumber ?? ''})',
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  S.of(context).label_setting_update,
                  // S.of(context).label_setting_recent_version,
                  style: getTextStyle(AppTypo.CAPTION12B, AppColors.Primary500),
                  textAlign: TextAlign.start,
                ),
              ),
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {}),
        ],
      ),
    );
  }
}
