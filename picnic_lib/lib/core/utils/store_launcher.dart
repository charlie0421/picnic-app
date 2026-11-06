import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The outcome of one attempt to open the store page.
enum StoreLaunchResult {
  /// The OS accepted the store URL.
  opened,

  /// There was no store URL to open.
  emptyUrl,

  /// The OS refused the URL (`launchUrlString` returned false).
  refused,

  /// The platform channel reported an error.
  failed,
}

/// Opens the App Store / Play Store page for an update.
///
/// PICNIC-APP-45D: the update screens first asked `canLaunchUrlString` and
/// threw the localized message when it said no. On iOS 27 it said no for the
/// App Store https URL, so the force-update button did nothing and the
/// thrown String went to Sentry. This opens the URL directly and returns a
/// result, so the caller can show feedback and let the user retry.
class StoreLauncher {
  const StoreLauncher._();

  /// Test seam for the platform launch.
  @visibleForTesting
  static Future<bool> Function(String url)? debugLauncher;

  /// Test seam for the failure report.
  @visibleForTesting
  static void Function(StoreLaunchResult result, String surface)? debugReporter;

  /// Opens [url] in the external store app.
  ///
  /// Only a [PlatformException] becomes [StoreLaunchResult.failed]. Any other
  /// error is a defect and propagates.
  static Future<StoreLaunchResult> open(String url) async {
    if (url.trim().isEmpty) return StoreLaunchResult.emptyUrl;
    try {
      // App Store / Play Store URL 은 externalApplication 으로 열어야 OS 가
      // 외부 스토어 앱으로 deep-link 한다. platformDefault(iOS =
      // SFSafariViewController) 는 _failedSafariViewControllerLoadException 을
      // 던진다 (PICNIC-APP-4ED).
      final ok = await (debugLauncher ?? _launch)(url);
      return ok ? StoreLaunchResult.opened : StoreLaunchResult.refused;
    } on PlatformException {
      return StoreLaunchResult.failed;
    }
  }

  static Future<bool> _launch(String url) =>
      launchUrlString(url, mode: LaunchMode.externalApplication);

  /// Reports a failed attempt with closed values only (no URL).
  ///
  /// [surface] is `force_update` or `update_recommend`.
  static void reportFailure(StoreLaunchResult result, String surface) {
    final reporter = debugReporter;
    if (reporter != null) {
      reporter(result, surface);
      return;
    }
    Sentry.captureMessage(
      'store_launch_failed',
      level: SentryLevel.warning,
      withScope: (scope) {
        scope.setTag('store_launch_result', result.name);
        scope.setTag('store_launch_surface', surface);
        scope.fingerprint = ['store-launch-failed', surface, result.name];
      },
    ).ignore();
  }
}
