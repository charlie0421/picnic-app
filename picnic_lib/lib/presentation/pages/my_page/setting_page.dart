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
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
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
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage>
    with RouteAwareStateMixin<SettingPage>, SingleTickerProviderStateMixin {
  bool value1 = false;
  bool value2 = false;
  String buildNumber = '';
  bool _isRestartingApp = false;
  bool _isCheckingPatch = false;
  bool _isManualPatchUpdating = false;
  String? _currentTitle;

  // 애니메이션 컨트롤러
  late AnimationController _patchAnimationController;
  late Animation<double> _patchFadeAnimation;
  late Animation<double> _patchScaleAnimation;

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

    // 애니메이션 초기화
    _patchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _patchFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _patchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _patchScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _patchAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    _patchAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBuildNumber().then((value) {
        buildNumber = value;
        setState(() {});
      });

      _currentTitle = AppLocalizations.of(context).mypage_setting;
      _updateNavigation();

      // 설정 페이지 진입 시 자동으로 패치 상태 확인
      _checkPatchStatusOnEntry();
    });
  }

  @override
  void dispose() {
    _patchAnimationController.dispose();
    super.dispose();
  }

  /// 설정 페이지 진입 시 자동 패치 확인 (조용히)
  Future<void> _checkPatchStatusOnEntry() async {
    if (UniversalPlatform.isWeb) return;

    setState(() {
      _isCheckingPatch = true;
    });

    try {
      final result = await ShorebirdUtils.checkPatchStatusForSettings();

      if (mounted) {
        final isRestartRequired =
            result.status == shorebird.UpdateStatus.restartRequired;

        ref.read(patchInfoProvider.notifier).updatePatchInfo({
          'hasUpdate': result.status == shorebird.UpdateStatus.outdated,
          'currentPatch': result.currentPatchNumber ?? result.nextPatchNumber,
          'needsRestart': isRestartRequired,
          'updateDownloaded': isRestartRequired,
        });

        // 애니메이션 리셋 및 재실행
        _patchAnimationController.reset();
        _patchAnimationController.forward();
      }
    } catch (e) {
      logger.w('자동 패치 확인 실패 (무시됨): $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPatch = false;
        });
      }
    }
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
            // 패치 정보 및 수동 재시작
            _buildPatchStatusTile(context, l10n, patchInfo),
          ],
        ),
      ),
      loading: () => ui.buildLoadingOverlay(),
      error: (error, stackTrace) => Container(),
    );
  }

  Widget _buildPatchStatusTile(
    BuildContext context,
    AppLocalizations l10n,
    PatchInfo patchInfo,
  ) {
    final arrowIcon = SvgPicture.asset(
      'assets/icons/arrow_right_style=line.svg',
      package: 'picnic_lib',
      width: 20.w,
      height: 20.w,
      colorFilter: const ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
    );
    final canApplyPatch = patchInfo.hasUpdate && !_isManualPatchUpdating;

    return FadeTransition(
      opacity: _patchFadeAnimation,
      child: ScaleTransition(
        scale: _patchScaleAnimation,
        child: Column(
      children: [
        InkWell(
          onTap: _isCheckingPatch ? null : () => _handlePatchStatusTap(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.label_setting_patch_section_title,
                  style: getTextStyle(AppTypo.body16M),
                ),
                SizedBox(width: 12.w),
                Expanded(
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
                                  AppColors.primary500,
                                ),
                              ),
                            ),
                          Text(
                            _isCheckingPatch
                                ? l10n.label_setting_patch_checking
                                : _localizedPatchStatusText(l10n, patchInfo),
                            style: getTextStyle(
                              AppTypo.caption12B,
                              patchInfo.canRestart
                                  ? AppColors.primary500
                                  : AppColors.secondary500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                      if (patchInfo.lastChecked != null && !_isCheckingPatch)
                        Text(
                          l10n.label_setting_patch_last_checked(
                            _formatTime(patchInfo.lastChecked!),
                          ),
                          style: getTextStyle(
                            AppTypo.caption10SB,
                            AppColors.grey500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          _buildPatchActionButton(
                            label: l10n.label_setting_patch_check_button,
                            onTap: _isCheckingPatch
                                ? null
                                : () => _handlePatchStatusTap(),
                            isPrimary: false,
                            isLoading: _isCheckingPatch,
                          ),
                          _buildPatchActionButton(
                            label: l10n.label_setting_patch_apply_button,
                            onTap: canApplyPatch
                                ? () => _handleManualPatchUpdate(context)
                                : null,
                            isLoading: _isManualPatchUpdating,
                          ),
                        ],
                      ),
                      if (patchInfo.needsRestart)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.message_setting_patch_restart_hint,
                            style: getTextStyle(
                              AppTypo.caption10SB,
                              AppColors.primary500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                patchInfo.canRestart
                    ? _buildRestartButton(context, patchInfo)
                    : arrowIcon,
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.grey200),
      ],
    ),
      ),
    );
  }

  String _localizedPatchStatusText(AppLocalizations l10n, PatchInfo patchInfo) {
    if (patchInfo.needsRestart) {
      return l10n.label_setting_patch_status_restart_required;
    }
    if (patchInfo.updateDownloaded) {
      return l10n.label_setting_patch_status_downloaded;
    }
    if (patchInfo.hasUpdate) {
      return l10n.label_setting_patch_status_available;
    }
    if (patchInfo.currentPatch != null) {
      return l10n.label_setting_patch_status_current_patch(
        patchInfo.currentPatch!,
      );
    }
    return l10n.label_setting_patch_status_none;
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.button_restart,
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                ),
              ),
            ),
    );
  }

  Widget _buildPatchActionButton({
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    final isDisabled = onTap == null;
    final backgroundColor = isPrimary
        ? AppColors.primary500
        : AppColors.primary500.withValues(alpha: 0.1);
    final textColor = isPrimary ? AppColors.grey00 : AppColors.primary500;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.4),
                    width: 1,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 12.w,
                  height: 12.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Text(label, style: getTextStyle(AppTypo.caption10SB, textColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// 수동 재시작 처리
  Future<void> _handleManualRestart(
    BuildContext context,
    PatchInfo patchInfo,
  ) async {
    if (!patchInfo.canRestart || _isRestartingApp) return;

    final l10n = AppLocalizations.of(context);

    // 확인 다이얼로그 표시
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.dialog_setting_restart_title,
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        ),
        content: Text(
          l10n.dialog_setting_restart_body,
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
              l10n.button_cancel,
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
              l10n.button_restart,
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

  /// 수동 패치 다운로드 및 적용 (자동 리스타트 포함)
  Future<void> _handleManualPatchUpdate(BuildContext context) async {
    if (_isManualPatchUpdating) return;

    final l10n = AppLocalizations.of(context);

    if (UniversalPlatform.isWeb) {
      SnackbarUtil().warning(
        l10n.message_setting_patch_web_not_supported,
        context: context,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isManualPatchUpdating = true;
      });
    }

    try {
      await ShorebirdUtils.checkAndUpdate();
      final patch = await ShorebirdUtils.checkPatch();

      if (!mounted || !context.mounted) {
        return;
      }

      ref.read(patchInfoProvider.notifier).updatePatchInfo({
        'updateDownloaded': true,
        'needsRestart': true,
        'currentPatch': patch?.number,
        'statusMessage': 'Patch downloaded',
      });

      // 패치 다운로드 성공 - 자동 리스타트 진행
      await _showAutoRestartAnimation(context, l10n);
    } catch (e, stackTrace) {
      logger.e('수동 패치 업데이트 실패: $e', stackTrace: stackTrace);
      if (!mounted || !context.mounted) {
        return;
      }
      SnackbarUtil().error(
        l10n.message_setting_patch_update_failed(e.toString()),
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isManualPatchUpdating = false;
        });
      }
    }
  }

  /// 자동 리스타트 애니메이션 표시 후 리스타트
  Future<void> _showAutoRestartAnimation(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!mounted || !context.mounted) return;

    // 오버레이로 리스타트 안내 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _AutoRestartDialog(
        onComplete: () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          if (context.mounted) {
            Phoenix.rebirth(context);
          }
        },
      ),
    );
  }

  /// 패치 상태 탭 처리 - 수동 패치 확인
  Future<void> _handlePatchStatusTap() async {
    if (_isCheckingPatch) return;

    setState(() {
      _isCheckingPatch = true;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final result = await ShorebirdUtils.checkPatchStatusForSettings();

      if (mounted) {
        // restartRequired인 경우 needsRestart를 true로, nextPatch 정보도 반영
        final isRestartRequired =
            result.status == shorebird.UpdateStatus.restartRequired;

        ref.read(patchInfoProvider.notifier).updatePatchInfo({
          'hasUpdate': result.status == shorebird.UpdateStatus.outdated,
          'currentPatch': result.currentPatchNumber ?? result.nextPatchNumber,
          'needsRestart': isRestartRequired,
          'updateDownloaded': isRestartRequired,
        });

        switch (result.status) {
          case shorebird.UpdateStatus.outdated:
            SnackbarUtil().info(
              l10n.message_setting_patch_update_available,
              context: context,
              actionLabel: l10n.button_update,
              onAction: () async {
                await _handleManualPatchUpdate(context);
              },
            );
            break;
          case shorebird.UpdateStatus.restartRequired:
            SnackbarUtil().info(
              l10n.message_setting_patch_restart_hint,
              context: context,
              actionLabel: l10n.button_restart,
              onAction: () {
                Phoenix.rebirth(context);
              },
            );
            break;
          case shorebird.UpdateStatus.upToDate:
            SnackbarUtil().success(
              l10n.message_setting_patch_up_to_date,
              context: context,
            );
            break;
          default:
            SnackbarUtil().info(
              l10n.message_setting_patch_status_unavailable,
              context: context,
            );
            break;
        }
      }
    } on PatchStatusException catch (error) {
      if (mounted) {
        if (error.code == PatchStatusError.webUnsupported) {
          SnackbarUtil().warning(
            l10n.message_setting_patch_web_not_supported,
            context: context,
          );
        } else {
          SnackbarUtil().error(
            l10n.message_setting_patch_status_failed(error.message ?? ''),
            context: context,
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ 패치 상태 확인 중 오류 발생: $e', stackTrace: stackTrace);

      if (mounted) {
        SnackbarUtil().error(
          l10n.message_setting_patch_status_failed(e.toString()),
          context: context,
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

/// 자동 리스타트 애니메이션 다이얼로그
class _AutoRestartDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _AutoRestartDialog({required this.onComplete});

  @override
  State<_AutoRestartDialog> createState() => _AutoRestartDialogState();
}

class _AutoRestartDialogState extends State<_AutoRestartDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 80,
      ),
    ]).animate(_controller);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 280.w,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 체크마크 애니메이션
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 40.w,
                        color: AppColors.primary500,
                      ),
                    ),
                    SizedBox(height: 16.w),
                    Text(
                      l10n.message_setting_patch_update_success,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      l10n.message_setting_patch_restarting,
                      style: getTextStyle(AppTypo.body14R, AppColors.grey600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.w),
                    // 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary500,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
