import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/presentation/widgets/ui/overlay_notifier.dart';
import 'package:picnic_app/presentation/widgets/ui/smooth_circular_countdown.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_app/presentation/providers/update_checker.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateDialog({super.key, required this.child});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkForUpdate();
    });
  }

  void _checkForUpdate() {
    final initState = ref.watch(appInitializationProvider);
    final updateInfo = initState.updateInfo;
    if (updateInfo != null &&
        updateInfo.status == UpdateStatus.updateRecommended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.showOverlayNotification(
            childBuilder: (remainingSeconds) => Container(
              color: Colors.yellow,
              padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                      child: Text(S
                          .of(context)
                          .update_recommend_text(updateInfo.latestVersion))),
                  TextButton(
                    child: Text(
                      S.of(context).update_button,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900)
                          .copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onPressed: () => _launchAppStore(updateInfo.url ?? '',
                        S.of(context).update_cannot_open_appstore),
                  ),
                  SizedBox(width: 8.cw),
                  SmoothCircularCountdown(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: 5,
                  ),
                ],
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _launchAppStore(String url, message) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw message;
    }
  }
}
