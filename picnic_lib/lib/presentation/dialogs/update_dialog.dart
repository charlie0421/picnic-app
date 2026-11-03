import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/overlay_notifier.dart';
import 'package:picnic_lib/presentation/widgets/ui/smooth_circular_countdown.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
                onPressed: () => _launchAppStore(
                  latestInfo.url ?? '',
                  AppLocalizations.of(context).update_cannot_open_appstore,
                ),
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

  void _launchAppStore(String url, message) async {
    if (await canLaunchUrlString(url)) {
      // App Store / Play Store URL 은 externalApplication 으로 열어야 OS 가
      // 외부 스토어 앱으로 deep-link 함 (PICNIC-APP-4ED 참고).
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      throw message;
    }
  }
}
