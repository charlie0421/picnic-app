import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ForceUpdateOverlay extends StatelessWidget {
  final String forceVersion;
  final String url;
  final Widget child;

  const ForceUpdateOverlay(
      {super.key,
      required this.forceVersion,
      required this.url,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0).r,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.of(context).update_required_title),
                        const SizedBox(height: 16),
                        Text(S.of(context).update_required_text(forceVersion)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          child: Text(S.of(context).update_button),
                          onPressed: () => _launchAppStore(url),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchAppStore(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw '앱 스토어를 열 수 없습니다.';
    }
  }
}
