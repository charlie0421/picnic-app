import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ForceUpdateOverlay extends StatelessWidget {
  final UpdateInfo updateInfo;

  const ForceUpdateOverlay({super.key, required this.updateInfo});

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
                  child: Text(AppLocalizations.of(context).update_button),
                  onPressed: () => _launchAppStore(
                    url ?? '',
                    AppLocalizations.of(context).update_cannot_open_appstore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get forceVersion => updateInfo.forceVersion;

  String? get url => updateInfo.url;

  void _launchAppStore(String url, String message) async {
    if (await canLaunchUrlString(url)) {
      // App Store / Play Store URL 은 externalApplication 으로 열어야 OS 가
      // 외부 스토어 앱으로 deep-link 함. platformDefault(iOS = SFSafariView
      // Controller) 는 store URL 인텐트 미스매치로 _failedSafariViewController
      // LoadException 을 던짐 (PICNIC-APP-4ED: 169u/330e).
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      throw message;
    }
  }
}
