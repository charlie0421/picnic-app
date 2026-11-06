import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/store_launcher.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/overlay_notifier.dart';
import 'package:picnic_lib/presentation/widgets/ui/smooth_circular_countdown.dart';
import 'package:picnic_lib/ui/style.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final Widget child;
  final bool enabled;

  const UpdateDialog({super.key, required this.child, this.enabled = true});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  ProviderSubscription<AppInitializationState>? _subscription;
  String? _shownVersionPair;
  int _checkGeneration = 0;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AppInitializationState>(
      appInitializationProvider,
      (_, next) => _scheduleCheck(next),
      fireImmediately: true,
    );
  }

  @override
  void didUpdateWidget(covariant UpdateDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _scheduleCheck(ref.read(appInitializationProvider));
    }
  }

  bool _canShow(AppInitializationState state) {
    return widget.enabled &&
        state.isInitialized &&
        state.hasNetwork &&
        !state.isBanned &&
        state.updateInfo?.status == UpdateStatus.updateRecommended;
  }

  void _scheduleCheck(AppInitializationState state) {
    if (!_canShow(state)) {
      _checkGeneration++;
      return;
    }
    final info = state.updateInfo!;
    final pair = '${info.currentVersion}->${info.latestVersion}';
    if (_shownVersionPair == pair) return;
    final generation = ++_checkGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _checkGeneration) return;
      final latest = ref.read(appInitializationProvider);
      if (!_canShow(latest)) return;
      final latestInfo = latest.updateInfo!;
      final latestPair =
          '${latestInfo.currentVersion}->${latestInfo.latestVersion}';
      if (latestPair != pair || _shownVersionPair == pair) return;

      _shownVersionPair = pair;
      context.showOverlayNotification(
        childBuilder: (remainingSeconds) => Container(
          color: Colors.yellow,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).update_recommend_text(latestInfo.latestVersion),
                ),
              ),
              TextButton(
                child: Text(
                  AppLocalizations.of(context).update_button,
                  style: getTextStyle(
                    AppTypo.body14M,
                    AppColors.grey900,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
                onPressed: () => _launchAppStore(latestInfo.url ?? ''),
              ),
              SizedBox(width: 8.w),
              SmoothCircularCountdown(
                remainingSeconds: remainingSeconds,
                totalSeconds: 5,
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _checkGeneration++;
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// 권장 업데이트는 닫을 수 있는 안내라 실패해도 앱 사용을 막지 않는다.
  /// 예전처럼 문구를 던지지 않고 닫힌 값으로만 보고한다 (PICNIC-APP-45D).
  Future<void> _launchAppStore(String url) async {
    final result = await StoreLauncher.open(url);
    if (result != StoreLaunchResult.opened) {
      StoreLauncher.reportFailure(result, 'update_recommend');
    }
  }
}
