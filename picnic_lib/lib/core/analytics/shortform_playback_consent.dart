import 'package:shared_preferences/shared_preferences.dart';

/// A separate optional permission for first-party shortform playback analysis.
/// ATT/UMP ad permission and merely watching a rewarded ad do not grant this.
/// Selection is local to this installation, account, and disclosure version.
class ShortformPlaybackConsent {
  ShortformPlaybackConsent({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static final instance = ShortformPlaybackConsent();
  static String storageKey(String owner) =>
      'shortform_playback_analysis_v1:$owner';
  final Future<SharedPreferences> Function() _preferences;
  final Map<String, bool> _allowed = {};
  final Map<String, int> _generation = {};

  bool isAllowed(String owner) => owner.isNotEmpty && _allowed[owner] == true;

  Future<void> load(String owner) async {
    // A failed local write must not resurrect the previous persisted opt-in
    // when another ad route asks to load this account in the same process.
    if (owner.isEmpty || _allowed.containsKey(owner)) return;
    final generation = _generation[owner] ?? 0;
    try {
      final prefs = await _preferences().timeout(const Duration(seconds: 2));
      if ((_generation[owner] ?? 0) == generation) {
        _allowed[owner] = prefs.getBool(storageKey(owner)) == true;
      }
    } catch (_) {
      if ((_generation[owner] ?? 0) == generation) _allowed[owner] = false;
    }
  }

  /// Only the explicit settings control calls this method.
  Future<bool> setAllowed(String owner, bool allowed) async {
    if (owner.isEmpty) return false;
    final generation = (_generation[owner] ?? 0) + 1;
    _generation[owner] = generation;
    _allowed[owner] = false;
    try {
      final prefs = await _preferences().timeout(const Duration(seconds: 2));
      final saved = await prefs
          .setBool(storageKey(owner), allowed)
          .timeout(const Duration(seconds: 2));
      if (_generation[owner] == generation) _allowed[owner] = saved && allowed;
      return saved;
    } catch (_) {
      return false;
    }
  }
}
