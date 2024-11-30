import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/ui/overlay_notifier.dart';
import 'package:picnic_app/components/ui/smooth_circular_countdown.dart';
import 'package:picnic_app/dialogs/force_update_overlay.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/update_checker.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
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
    final updateInfo = ref.read(updateCheckerProvider);
    updateInfo.whenData((info) {
      if (info != null && info.status == UpdateStatus.updateRecommended) {
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
                            .update_recommend_text(info.latestVersion))),
                    TextButton(
                      child: Text(
                        S.of(context).update_button,
                        style: getTextStyle(AppTypo.body14M, AppColors.grey900)
                            .copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () => _launchAppStore(
                          info.url!, S.of(context).update_cannot_open_appstore),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = ref.watch(updateCheckerProvider);

    return updateInfo.when(
      data: (info) {
        if (info == null) return widget.child;
        switch (info.status) {
          case UpdateStatus.updateRequired:
            return ForceUpdateOverlay(
                forceVersion: info.forceVersion,
                url: info.url!,
                child: widget.child);
          case UpdateStatus.updateRecommended:
          case UpdateStatus.upToDate:
            return widget.child;
        }
      },
      loading: () => widget.child,
      error: (_, __) => widget.child,
    );
  }

  void _launchAppStore(String url, message) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw message;
    }
  }
}
