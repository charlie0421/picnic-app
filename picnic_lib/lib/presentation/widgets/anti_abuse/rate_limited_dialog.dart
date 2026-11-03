import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// 제한 응답 코드에 맞는 현지화 문구를 표시한다.
Future<void> showRateLimitedDialog(
  BuildContext context, {
  required String channel,
  String? rawCode,
  String csEmail = 'cs@picnic.fan',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _RateLimitedDialog(
      channel: channel,
      rawCode: rawCode,
      csEmail: csEmail,
    ),
  );
}

class _RateLimitedDialog extends StatelessWidget {
  const _RateLimitedDialog({
    required this.channel,
    this.rawCode,
    required this.csEmail,
  });

  final String channel;
  final String? rawCode;
  final String csEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSignup = channel == 'signup';
    final (title, message) = _copyForChannel(channel, l10n);

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (isSignup)
          TextButton(
            onPressed: () => _openCsMailto(csEmail),
            child: Text(l10n.button_cs_inquiry),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialog_button_ok),
        ),
      ],
    );
  }

  (String, String) _copyForChannel(String ch, AppLocalizations l) {
    if (rawCode == 'AD_DEVICE_ACCOUNT_LIMIT') {
      return (
        l.error_anti_abuse_ad_title,
        l.error_ad_device_account_restricted_message,
      );
    }
    switch (ch) {
      case 'signup':
        return (
          l.error_anti_abuse_signup_title,
          l.error_anti_abuse_signup_message,
        );
      case 'ad_watch':
        return (l.error_anti_abuse_ad_title, l.error_anti_abuse_ad_message);
      case 'attendance':
        return (
          l.error_anti_abuse_attendance_title,
          l.error_anti_abuse_attendance_message,
        );
      case 'artist_request':
        return (
          l.error_anti_abuse_artist_request_title,
          l.error_anti_abuse_artist_request_message,
        );
      default:
        // Unknown channel — fall back to attendance copy (모호 톤). 로그만 남김.
        return (
          l.error_anti_abuse_attendance_title,
          l.error_anti_abuse_attendance_message,
        );
    }
  }

  Future<void> _openCsMailto(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(uri);
    } catch (e, s) {
      logger.w('failed to launch CS mailto', error: e, stackTrace: s);
    }
  }
}
