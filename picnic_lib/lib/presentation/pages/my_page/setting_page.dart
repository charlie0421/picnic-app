import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:load_switch/load_switch.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/platform_info_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage>
    with RouteAwareStateMixin<SettingPage> {
  bool value1 = false;
  bool value2 = false;
  String buildNumber = '';
  String? _currentTitle;

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

      _currentTitle = AppLocalizations.of(context).mypage_setting;
      _updateNavigation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).mypage_setting;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(platformInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);
    final updateChecker = ref.watch(checkUpdateProvider);
    final patchInfo = ref.watch(patchInfoProvider);
    final l10n = AppLocalizations.of(context);

    return userInfoState.when(
      data: (data) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).label_setting_alarm,
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
            ),
            const SizedBox(height: 4),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_setting_push_alarm,
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
                switchDecoration: (value, isActive) => BoxDecoration(
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
              leading: AppLocalizations.of(context).label_setting_event_alarm,
              title: Container(
                margin: EdgeInsets.only(left: 8.w),
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context).label_setting_event_alarm_desc,
                  style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
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
                switchDecoration: (value, isActive) => BoxDecoration(
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
            Text(
              AppLocalizations.of(context).label_setting_storage,
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
            ),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_setting_remove_cache,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () async {
                OverlayLoadingProgress.start(context);
                final cacheManager = DefaultCacheManager();
                cacheManager.emptyCache().then((value) {
                  OverlayLoadingProgress.stop();
                  if (navigatorKey.currentContext != null) {
                    showSimpleDialog(
                      content: AppLocalizations.of(
                        navigatorKey.currentContext!,
                      ).message_setting_remove_cache,
                      onOk: () => Navigator.of(context).pop(),
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).label_setting_appinfo,
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
            ),
            updateChecker.when(
              data: (info) {
                if (info == null) {
                  return Container();
                }
                switch (info.status) {
                  case UpdateStatus.needPatch:
                    return PicnicListItem(
                      leading:
                          '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                      title: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? l10n.label_setting_patch_number(patchInfo.currentPatch!) : ''}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.primary500,
                          ),
                        ),
                      ),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                    );
                  case UpdateStatus.updateRequired:
                    return PicnicListItem(
                      leading:
                          '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                      title: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? l10n.label_setting_patch_number(patchInfo.currentPatch!) : ''}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.primary500,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () async {
                        (await canLaunchUrlString(info.url!))
                            ? launchUrlString(info.url!)
                            : throw AppLocalizations.of(
                                navigatorKey.currentContext!,
                              ).update_cannot_open_appstore;
                      },
                    );
                  case UpdateStatus.updateRecommended:
                    return PicnicListItem(
                      leading:
                          '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                      title: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? l10n.label_setting_patch_number(patchInfo.currentPatch!) : ''}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.primary500,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () async {
                        (await canLaunchUrlString(info.url!))
                            ? launchUrlString(info.url!)
                            : throw AppLocalizations.of(
                                navigatorKey.currentContext!,
                              ).update_cannot_open_appstore;
                      },
                    );
                  case UpdateStatus.upToDate:
                    return PicnicListItem(
                      leading:
                          '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                      title: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${AppLocalizations.of(context).label_setting_recent_version_up_to_date} 빌드: $buildNumber${patchInfo.currentPatch != null ? l10n.label_setting_patch_number(patchInfo.currentPatch!) : ''}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.secondary500,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                    );
                }
              },
              loading: () => ui.buildLoadingOverlay(),
              error: (_, _) => Container(),
            ),
            // 패치 번호 표시 (정보 전용 - 패치 적용은 앱 시작 시 자동)
            _buildPatchStatusTile(l10n, patchInfo),
          ],
        ),
      ),
      loading: () => ui.buildLoadingOverlay(),
      error: (error, stackTrace) => Container(),
    );
  }

  /// 패치 정보 표시 (간소화 - 현재 패치 번호만)
  /// 패치 다운로드/적용은 앱 시작 시 자동으로 처리됨
  Widget _buildPatchStatusTile(AppLocalizations l10n, PatchInfo patchInfo) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.w),
          child: Row(
            children: [
              Text(
                l10n.label_setting_patch_section_title,
                style: getTextStyle(AppTypo.body16M),
              ),
              const Spacer(),
              Text(
                patchInfo.currentPatch != null
                    ? l10n.label_setting_patch_status_current_patch(
                        patchInfo.currentPatch!,
                      )
                    : l10n.label_setting_patch_status_none,
                style: getTextStyle(
                  AppTypo.caption12B,
                  AppColors.secondary500,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.grey200),
      ],
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
}
