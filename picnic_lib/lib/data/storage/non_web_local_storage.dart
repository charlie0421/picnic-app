import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

NonWebLocalStorage getInstance() => NonWebLocalStorage();

class NonWebLocalStorage implements LocalStorage {
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  @override
  Future<void> saveData(String key, String value) async {
    final SharedPreferences prefs = await _prefs;
    final previous = prefs.getString(key);
    final saved = await prefs.setString(key, value);
    if (!saved) {
      try {
        await prefs.reload();
      } catch (_) {
        if (previous == null) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, previous);
        }
      }
      throw StateError('SharedPreferences failed to persist $key');
    }
  }

  @override
  Future<String?> loadData(String key, dynamic defaultVale) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(key) ?? defaultVale;
  }

  @override
  Future<void> removeData(String key) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.clear();
  }
}
