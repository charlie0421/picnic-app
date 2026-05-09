import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Anti-abuse 다이얼로그 — 채널별로 톤이 다름.
///
///   - signup        : 부분적으로 명확 ("비정상 활동 감지됨") + 고객센터 링크
///   - ad_watch      : 모호 톤 ("잠시 후 다시 시도")
///   - attendance    : 모호 톤
///   - artist_request: 모호 톤
///
/// 모호 톤은 abuser 가 회피 패턴을 추론하기 어렵게 하기 위함 (스펙 §9 참조).
Future<void> showRateLimitedDialog(
  BuildContext context, {
  required String channel,
  String csEmail = 'cs@picnic.fan',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _RateLimitedDialog(channel: channel, csEmail: csEmail),
  );
}

class _RateLimitedDialog extends StatelessWidget {
  const _RateLimitedDialog({required this.channel, required this.csEmail});

  final String channel;
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
    switch (ch) {
      case 'signup':
        return (l.error_anti_abuse_signup_title,
            l.error_anti_abuse_signup_message);
      case 'ad_watch':
        return (l.error_anti_abuse_ad_title, l.error_anti_abuse_ad_message);
      case 'attendance':
        return (l.error_anti_abuse_attendance_title,
            l.error_anti_abuse_attendance_message);
      case 'artist_request':
        return (l.error_anti_abuse_artist_request_title,
            l.error_anti_abuse_artist_request_message);
      default:
        // Unknown channel — fall back to attendance copy (모호 톤). 로그만 남김.
        return (l.error_anti_abuse_attendance_title,
            l.error_anti_abuse_attendance_message);
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
