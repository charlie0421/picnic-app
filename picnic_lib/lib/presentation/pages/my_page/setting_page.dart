import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:load_switch/load_switch.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/platform_info_provider.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:picnic_lib/presentation/providers/locale_provider.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool value1 = false;
  bool value2 = false;
  String buildNumber = '';
  String? patchVersion;
  bool isPatched = false;
  String _patchInfo = "Loading...";

  Future<bool> _getFuture1() async {
    await Future.delayed(const Duration(seconds: 1));
    return !value1;
  }

  Future<bool> _getFuture2() async {
    await Future.delayed(const Duration(seconds: 1));
    return !value2;
  }

  Future<String> getBuildNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  @override
  void initState() {
    super.initState();
    _fetchPatchInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBuildNumber().then((value) {
        buildNumber = value;
        setState(() {});
      });

      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: t('mypage_setting'));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(platformInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);
    final updateChecker = ref.watch(checkUpdateProvider);
    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin)) ??
            false;

    return userInfoState.when(
        data: (data) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Text(t('label_setting_alarm'),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  const SizedBox(height: 4),
                  PicnicListItem(
                    leading: t('label_setting_push_alarm'),
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    tailing: LoadSwitch(
                      width: 48.w,
                      height: 28,
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
                        color: value ? AppColors.primary500 : AppColors.grey200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [switchBoxShadow],
                      ),
                      spinColor: (value) =>
                          value ? AppColors.primary500 : AppColors.primary500,
                      spinStrokeWidth: 1,
                      onChange: (v) {
                        value1 = v;
                        setState(() {});
                      },
                      onTap: (v) {},
                    ),
                  ),
                  PicnicListItem(
                    leading: t('label_setting_event_alarm'),
                    title: Container(
                      margin: EdgeInsets.only(left: 8.w),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t('label_setting_event_alarm_desc'),
                        style:
                            getTextStyle(AppTypo.caption12R, AppColors.grey600),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    tailing: LoadSwitch(
                      width: 48.w,
                      height: 28,
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
                        color: value ? AppColors.primary500 : AppColors.grey200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [switchBoxShadow],
                      ),
                      spinColor: (value) =>
                          value ? AppColors.primary500 : AppColors.primary500,
                      spinStrokeWidth: 1,
                      onChange: (v) {
                        value2 = v;
                        setState(() {});
                      },
                      onTap: (v) {},
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(t('label_setting_storage'),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  PicnicListItem(
                      leading: t('label_setting_remove_cache'),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () async {
                        OverlayLoadingProgress.start(context);
                        final cacheManager = DefaultCacheManager();
                        cacheManager.emptyCache().then((value) {
                          OverlayLoadingProgress.stop();
                          showSimpleDialog(
                              content: t('message_setting_remove_cache'),
                              onOk: () => Navigator.of(context).pop());
                        });
                      }),
                  const SizedBox(height: 24),
                  Text(t('label_setting_appinfo'),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  updateChecker.when(
                      data: (info) {
                        if (info == null) {
                          return Container();
                        }
                        switch (info.status) {
                          case UpdateStatus.needPatch:
                            return PicnicListItem(
                              leading:
                                  '${t('label_setting_current_version')} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${t('label_setting_recent_version')} (${info.latestVersion})${isAdmin ? ' 빌드: $buildNumber${isPatched ? ' / 패치: $patchVersion' : ''}' : ''}',
                                  style: getTextStyle(
                                      AppTypo.caption12B, AppColors.primary500),
                                ),
                              ),
                              assetPath:
                                  'assets/icons/arrow_right_style=line.svg',
                            );
                          case UpdateStatus.updateRequired:
                            return PicnicListItem(
                              leading:
                                  '${t('label_setting_current_version')} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${t('label_setting_recent_version')} (${info.latestVersion})${isAdmin ? ' 빌드: $buildNumber${isPatched ? ' / 패치: $patchVersion' : ''}' : ''}',
                                  style: getTextStyle(
                                      AppTypo.caption12B, AppColors.primary500),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              assetPath:
                                  'assets/icons/arrow_right_style=line.svg',
                              onTap: () async {
                                (await canLaunchUrlString(info.url!))
                                    ? launchUrlString(info.url!)
                                    : throw t('update_cannot_open_appstore');
                              },
                            );
                          case UpdateStatus.updateRecommended:
                            return PicnicListItem(
                              leading:
                                  '${t('label_setting_current_version')} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${t('label_setting_recent_version')} (${info.latestVersion})${isAdmin ? ' 빌드: $buildNumber${isPatched ? ' / 패치: $patchVersion' : ''}' : ''}',
                                  style: getTextStyle(
                                      AppTypo.caption12B, AppColors.primary500),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              assetPath:
                                  'assets/icons/arrow_right_style=line.svg',
                              onTap: () async {
                                (await canLaunchUrlString(info.url!))
                                    ? launchUrlString(info.url!)
                                    : throw t('update_cannot_open_appstore');
                              },
                            );
                          case UpdateStatus.upToDate:
                            return PicnicListItem(
                              leading:
                                  '${t('label_setting_current_version')} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${t('label_setting_recent_version_up_to_date')}${isAdmin ? ' 빌드: $buildNumber${isPatched ? ' / 패치: $patchVersion' : ''}' : ''}',
                                  style: getTextStyle(AppTypo.caption12B,
                                      AppColors.secondary500),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              assetPath:
                                  'assets/icons/arrow_right_style=line.svg',
                            );
                        }
                      },
                      loading: () => buildLoadingOverlay(),
                      error: (_, __) => Container()),
                  if (isAdmin)
                    PicnicListItem(
                      leading: 'Patch',
                      title: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        alignment: Alignment.centerRight,
                        child: Text(
                          _patchInfo,
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.secondary500),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      tailing: SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) => Container());
  }

  Future<void> _fetchPatchInfo() async {
    try {
      final patchNumber = await shorebird.ShorebirdUpdater().readCurrentPatch();
      setState(() {
        _patchInfo =
            patchNumber != null ? "Current Patch: $patchNumber" : "No patch";
      });
    } catch (e) {
      setState(() {
        _patchInfo = "Failed to load patch info";
      });
    }
  }
}
