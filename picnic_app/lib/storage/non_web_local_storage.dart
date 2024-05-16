import 'package:picnic_app/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

NonWebLocalStorage getInstance() => NonWebLocalStorage();

class NonWebLocalStorage implements LocalStorage {
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  @override
  Future<void> saveData(String key, String value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(key, value);
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
