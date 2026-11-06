import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/store_launcher.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class ForceUpdateOverlay extends StatefulWidget {
  final UpdateInfo updateInfo;

  const ForceUpdateOverlay({super.key, required this.updateInfo});

  @override
  State<ForceUpdateOverlay> createState() => _ForceUpdateOverlayState();
}

class _ForceUpdateOverlayState extends State<ForceUpdateOverlay> {
  /// 마지막 시도가 실패했는가. 실패하면 안내 문구를 보이고 버튼은 그대로
  /// 두어 다시 시도할 수 있게 한다 — 이 화면은 떠날 수 없다 (PICNIC-APP-45D).
  bool _launchFailed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: AppColors.primary500,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).update_required_title),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(
                    context,
                  ).update_required_text(forceVersion),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _launchAppStore,
                  child: Text(AppLocalizations.of(context).update_button),
                ),
                if (_launchFailed) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).update_cannot_open_appstore,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get forceVersion => widget.updateInfo.forceVersion;

  String? get url => widget.updateInfo.url;

  Future<void> _launchAppStore() async {
    final result = await StoreLauncher.open(url ?? '');
    final failed = result != StoreLaunchResult.opened;
    if (failed) StoreLauncher.reportFailure(result, 'force_update');
    if (!mounted) return;
    setState(() => _launchFailed = failed);
  }
}
