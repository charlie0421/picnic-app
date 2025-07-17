import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:load_switch/load_switch.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
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
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool value1 = false;
  bool value2 = false;
  String buildNumber = '';
  bool _isRestartingApp = false;
  bool _isCheckingPatch = false;

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

      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
          pageTitle: AppLocalizations.of(context).mypage_setting);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(platformInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);
    final updateChecker = ref.watch(checkUpdateProvider);
    final patchInfo = ref.watch(patchInfoProvider);

    return userInfoState.when(
        data: (data) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).label_setting_alarm,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  const SizedBox(height: 4),
                  PicnicListItem(
                    leading:
                        AppLocalizations.of(context).label_setting_push_alarm,
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
                    leading:
                        AppLocalizations.of(context).label_setting_event_alarm,
                    title: Container(
                      margin: EdgeInsets.only(left: 8.w),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)
                            .label_setting_event_alarm_desc,
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
                  Text(AppLocalizations.of(context).label_setting_storage,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey600)),
                  PicnicListItem(
                      leading: AppLocalizations.of(context)
                          .label_setting_remove_cache,
                      assetPath: 'assets/icons/arrow_right_style=line.svg',
                      onTap: () async {
                        OverlayLoadingProgress.start(context);
                        final cacheManager = DefaultCacheManager();
                        cacheManager.emptyCache().then((value) {
                          OverlayLoadingProgress.stop();
                          if (navigatorKey.currentContext != null) {
                            showSimpleDialog(
                                content: AppLocalizations.of(
                                        navigatorKey.currentContext!)
                                    .message_setting_remove_cache,
                                onOk: () => Navigator.of(context).pop());
                          }
                        });
                      }),
                  const SizedBox(height: 24),
                  Text(AppLocalizations.of(context).label_setting_appinfo,
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
                                  '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? ' / 패치: ${patchInfo.currentPatch}' : ''}',
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
                                  '${AppLocalizations.of(context).label_setting_current_version} ${info.currentVersion}',
                              title: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? ' / 패치: ${patchInfo.currentPatch}' : ''}',
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
                                    : throw AppLocalizations.of(
                                            navigatorKey.currentContext!)
                                        .update_cannot_open_appstore;
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
                                  '${AppLocalizations.of(context).label_setting_recent_version} (${info.latestVersion}) 빌드: $buildNumber${patchInfo.currentPatch != null ? ' / 패치: ${patchInfo.currentPatch}' : ''}',
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
                                    : throw AppLocalizations.of(
                                            navigatorKey.currentContext!)
                                        .update_cannot_open_appstore;
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
                                  '${AppLocalizations.of(context).label_setting_recent_version_up_to_date} 빌드: $buildNumber${patchInfo.currentPatch != null ? ' / 패치: ${patchInfo.currentPatch}' : ''}',
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
                      loading: () => ui.buildLoadingOverlay(),
                      error: (_, __) => Container()),
                  // 패치 정보 및 수동 재시작
                  PicnicListItem(
                    leading: 'Patch Status',
                    title: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isCheckingPatch)
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  margin: EdgeInsets.only(right: 6.w),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary500),
                                  ),
                                ),
                              Text(
                                _isCheckingPatch
                                    ? 'Checking...'
                                    : patchInfo.displayInfo,
                                style: getTextStyle(
                                    AppTypo.caption12B,
                                    patchInfo.canRestart
                                        ? AppColors.primary500
                                        : AppColors.secondary500),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                          if (patchInfo.lastChecked != null &&
                              !_isCheckingPatch)
                            Text(
                              'Last checked: ${_formatTime(patchInfo.lastChecked!)}',
                              style: getTextStyle(
                                  AppTypo.caption10SB, AppColors.grey500),
                              textAlign: TextAlign.end,
                            ),
                        ],
                      ),
                    ),
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: () => _handlePatchStatusTap(),
                    tailing: patchInfo.canRestart
                        ? _buildRestartButton(context, patchInfo)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        loading: () => ui.buildLoadingOverlay(),
        error: (error, stackTrace) => Container());
  }

  /// 시간 포맷팅 (HH:mm 형식)
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 수동 재시작 버튼 위젯
  Widget _buildRestartButton(BuildContext context, PatchInfo patchInfo) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      child: _isRestartingApp
          ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
            )
          : GestureDetector(
              onTap: () => _handleManualRestart(context, patchInfo),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Restart',
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                ),
              ),
            ),
    );
  }

  /// 수동 재시작 처리
  Future<void> _handleManualRestart(
      BuildContext context, PatchInfo patchInfo) async {
    if (!patchInfo.canRestart || _isRestartingApp) return;

    // 확인 다이얼로그 표시
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Restart App',
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        ),
        content: Text(
          'A new update is ready. The app will restart to apply the changes.\n\nContinue?',
          style: getTextStyle(AppTypo.body14R, AppColors.grey700),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text(
              'Cancel',
              style: getTextStyle(AppTypo.body14M, AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(
              'Restart',
              style: getTextStyle(AppTypo.body14B, AppColors.primary500),
            ),
          ),
        ],
      ),
    );

    if (shouldRestart == true && mounted) {
      setState(() {
        _isRestartingApp = true;
      });

      try {
        // 짧은 지연 후 재시작 실행
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && context.mounted) {
          Phoenix.rebirth(context);
        }
      } catch (e) {
        logger.e('수동 재시작 실행 중 오류: $e');
        if (mounted) {
          setState(() {
            _isRestartingApp = false;
          });
        }
      }
    }
  }

  /// 패치 상태 탭 처리 - 수동 패치 확인
  Future<void> _handlePatchStatusTap() async {
    if (_isCheckingPatch) return;

    setState(() {
      _isCheckingPatch = true;
    });

    try {
      logger.i('🔍 설정 페이지에서 수동 패치 확인 시작');

      // 웹 환경에서는 스킵
      if (UniversalPlatform.isWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('웹 환경에서는 패치 기능을 사용할 수 없습니다.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 간단한 패치 상태 확인
      final patchStatus = await ShorebirdUtils.checkPatchStatusForSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(patchStatus),
            duration: Duration(seconds: 3),
            backgroundColor: patchStatus.contains('업데이트 가능')
                ? Colors.blue
                : patchStatus.contains('최신')
                    ? Colors.green
                    : Colors.grey,
            action: patchStatus.contains('업데이트 가능')
                ? SnackBarAction(
                    label: '업데이트',
                    textColor: Colors.white,
                    onPressed: () async {
                      try {
                        await ShorebirdUtils.checkAndUpdate();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('패치 업데이트 완료! 앱을 재시작하세요.'),
                              backgroundColor: Colors.green,
                              action: SnackBarAction(
                                label: '재시작',
                                textColor: Colors.white,
                                onPressed: () => Phoenix.rebirth(context),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('패치 업데이트 실패: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('❌ 패치 상태 확인 중 오류 발생: $e', stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('패치 상태 확인 실패: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPatch = false;
        });
      }
    }
  }
}
