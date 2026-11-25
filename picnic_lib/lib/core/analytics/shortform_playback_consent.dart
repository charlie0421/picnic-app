import 'package:shared_preferences/shared_preferences.dart';

/// A separate optional permission for first-party shortform playback analysis.
/// ATT/UMP ad permission and merely watching a rewarded ad do not grant this.
/// Positive permission is memory-only, per account, for at most 24 hours.
/// Restart always requires a new explicit opt-in, even if storage has failed.
class ShortformPlaybackConsent {
  ShortformPlaybackConsent({
    Future<SharedPreferences> Function()? preferences,
    Duration Function()? elapsed,
  }) : _preferences = preferences ?? SharedPreferences.getInstance {
    final watch = Stopwatch()..start();
    _elapsed = elapsed ?? (() => watch.elapsed);
  }

  static final instance = ShortformPlaybackConsent();
  static String storageKey(String owner) =>
      'shortform_playback_analysis_v1:$owner';
  final Future<SharedPreferences> Function() _preferences;
  late final Duration Function() _elapsed;
  final Map<String, Duration> _expiresAt = {};
  final Map<String, int> _generation = {};

  bool isAllowed(String owner) => remaining(owner) > Duration.zero;

  Duration remaining(String owner) {
    final expiry = _expiresAt[owner];
    if (owner.isEmpty || expiry == null) return Duration.zero;
    final left = expiry - _elapsed();
    return left > Duration.zero ? left : Duration.zero;
  }

  Future<void> load(String owner) async {
    // Intentionally never restore affirmative preferences from older versions.
    // A route may call load repeatedly without extending a session's permission.
  }

  /// Only the explicit settings control calls this method.
  Future<bool> setAllowed(String owner, bool allowed) async {
    if (owner.isEmpty) return false;
    final generation = (_generation[owner] ?? 0) + 1;
    _generation[owner] = generation;
    _expiresAt.remove(owner);
    try {
      final prefs = await _preferences().timeout(const Duration(seconds: 2));
      final saved = await prefs
          // Clear any legacy grant, never persist a new affirmative grant.
          .setBool(storageKey(owner), false)
          .timeout(const Duration(seconds: 2));
      if (_generation[owner] != generation) return false;
      if (saved && allowed) {
        _expiresAt[owner] = _elapsed() + const Duration(hours: 24);
      }
      return saved;
    } catch (_) {
      return false;
    }
  }
}
