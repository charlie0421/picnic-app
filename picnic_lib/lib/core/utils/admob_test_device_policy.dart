import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Debug-only AdMob test device policy.
///
/// Reads the comma-separated `ADMOB_TEST_DEVICE_IDS` `--dart-define` and turns
/// it into the list handed to `RequestConfiguration.testDeviceIds`. [apply]
/// must run before every `MobileAds.instance.initialize()` call site.
///
/// Policy:
/// - debug builds only (`kDebugMode`); release/profile always resolve to `null`
/// - segments are trimmed, empty segments are dropped
/// - order and case are preserved (AdMob hashed ids are matched verbatim)
/// - absent or blank values resolve to `null`, i.e. "not configured", and
///   [apply] is then a no-op — release/absent behaviour is unchanged
///
/// Nothing here hardcodes or logs a device id.
class AdMobTestDevicePolicy {
  const AdMobTestDevicePolicy._();

  /// `--dart-define` key, e.g. `--dart-define=ADMOB_TEST_DEVICE_IDS=id1,id2`.
  static const String environmentKey = 'ADMOB_TEST_DEVICE_IDS';

  static const String _rawFromEnvironment = String.fromEnvironment(
    environmentKey,
  );

  /// Pure parsing policy (no platform access).
  ///
  /// Returns `null` when [isDebugMode] is false or when [raw] is null, blank,
  /// or contains only empty segments. Otherwise returns the trimmed, non-empty
  /// segments of [raw] in their original order and case.
  static List<String>? parse(String? raw, {required bool isDebugMode}) {
    if (!isDebugMode || raw == null) return null;

    final ids = raw
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    return ids.isEmpty ? null : ids;
  }

  /// Test device ids resolved from the build-time define, or `null` when not
  /// configured or not a debug build.
  static List<String>? get testDeviceIds =>
      parse(_rawFromEnvironment, isDebugMode: kDebugMode);

  /// Registers [testDeviceIds] with the Mobile Ads SDK.
  ///
  /// No-op in release builds and when the define is absent/blank.
  static Future<void> apply() => applyIds(testDeviceIds);

  /// Registers [ids] via `MobileAds.updateRequestConfiguration`, sending only
  /// `testDeviceIds` so the native side keeps every other request
  /// configuration field (tags, content rating) as previously set.
  ///
  /// No-op when [ids] is `null`.
  @visibleForTesting
  static Future<void> applyIds(List<String>? ids) async {
    if (ids == null) return;

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ids),
    );
  }
}
