import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:load_switch/load_switch.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_app/presentation/common/picnic_list_item.dart';
import 'package:picnic_app/core/constatns/constants.dart';
import 'package:picnic_app/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/presentation/providers/app_setting_provider.dart';
import 'package:picnic_app/presentation/providers/navigation_provider.dart';
import 'package:picnic_app/presentation/providers/platform_info_provider.dart';
import 'package:picnic_app/presentation/providers/update_checker.dart';
import 'package:picnic_app/presentation/providers/user_info_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_setting';

  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool value1 = false;
  bool value2 = false;
  String buildNumber = '';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBuildNumber().then((value) {
        buildNumber = value;
        setState(() {});
      });

      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: S.of(context).mypage_setting);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(platformInfoProvider);
    final appSettingState = ref.watch(appSettingProvider);
    final appSettingNotifier = ref.read(appSettingProvider.notifier);
    final userInfoState = ref.watch(userInfoProvider);
    final updateChecker = ref.watch(checkUpdateProvider);
    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin)) ??
            false;

    return userInfoState.when(
        data: (data) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Text(S.of(context).label_setting_alarm,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  const SizedBox(height: 4),
                  PicnicListItem(
                    leading: S.of(context).label_setting_push_alarm,
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    tailing: LoadSwitch(
                      width: 48.cw,
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
                    leading: S.of(context).label_setting_event_alarm,
                    title: Container(
                      margin: EdgeInsets.only(left: 8.cw),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        S.of(context).label_setting_event_alarm_desc,
                        style:
                            getTextStyle(AppTypo.caption12R, AppColors.grey600),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    tailing: LoadSwitch(
                      width: 48.cw,
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
                  Text(S.of(context).label_setting_language,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  DropdownButtonFormField(
                    value: appSettingState.locale.languageCode,
                    icon: SvgPicture.asset(
                        'assets/icons/arrow_down_style=line.svg'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.grey00, width: 0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    ),
                    dropdownColor: AppColors.grey00,
                    borderRadius: BorderRadius.circular(8),
                    items: languageMap.entries.map((entry) {
                      return DropdownMenuItem(
                        alignment: Alignment.center,
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: appSettingState.locale.languageCode ==
                                  entry.key
                              ? getTextStyle(AppTypo.body14B, AppColors.grey900)
                              : getTextStyle(
                                  AppTypo.body14M, AppColors.grey400),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (appSettingState.locale.languageCode == value) {
                        return;
                      }
                      appSettingNotifier.setLocale(Locale(
                        value!,
                        countryMap[value] ?? '',
                      ));
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(S.of(context).label_setting_storage,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  PicnicListItem(
                      leading: S.of(context).label_setting_remove_cache,
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () async {
                        OverlayLoadingProgress.start(context);
                        final cacheManager = DefaultCacheManager();
                        cacheManager.emptyCache().then((value) {
                          OverlayLoadingProgress.stop();
                          showSimpleDialog(
                              content:
                                  Intl.message('message_setting_remove_cache'),
                              onOk: () => Navigator.of(context).pop());
                        });
                      }),
                  const SizedBox(height: 24),
                  Text(S.of(context).label_setting_appinfo,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  updateChecker.when(
                      data: (info) {
                        if (info == null) {
                          return Container();
                        }
                        switch (info.status) {
                          case UpdateStatus.updateRequired:
                            return PicnicListItem(
                              leading:
                                  '${S.of(context).label_setting_current_version} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.cw),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${S.of(context).label_setting_recent_version} (${info.latestVersion})',
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
                                    : throw Intl.message(
                                        'update_cannot_open_appstore');
                              },
                            );
                          case UpdateStatus.updateRecommended:
                            return PicnicListItem(
                              leading:
                                  '${S.of(context).label_setting_current_version} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.cw),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${S.of(context).label_setting_recent_version} (${info.latestVersion})',
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
                                    : throw Intl.message(
                                        'update_cannot_open_appstore');
                              },
                            );
                          case UpdateStatus.upToDate:
                            return PicnicListItem(
                              leading:
                                  '${S.of(context).label_setting_current_version} ${info.currentVersion}${isAdmin ? ' ($buildNumber)' : ''}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.cw),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  S
                                      .of(context)
                                      .label_setting_recent_version_up_to_date,
                                  style: getTextStyle(
                                      AppTypo.caption12B, AppColors.mint500),
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
                ],
              ),
            ),
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) => Container());
  }
}
