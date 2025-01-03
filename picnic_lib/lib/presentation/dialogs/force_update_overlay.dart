import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
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
                Text(Intl.message('update_required_title')),
                const SizedBox(height: 16),
                // Text(S.of(context).update_required_text(forceVersion)),
                Text(
                    Intl.message('update_required_text', args: [forceVersion])),
                const SizedBox(height: 16),
                ElevatedButton(
                  child: Text(Intl.message(('update_button'))),
                  onPressed: () => _launchAppStore(
                      url ?? '', Intl.message(('update_cannot_open_appstore'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get forceVersion => updateInfo.latestVersion;

  String? get url => updateInfo.url;

  void _launchAppStore(String url, String message) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw message;
    }
  }
}
