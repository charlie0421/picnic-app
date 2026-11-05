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
      // 키는 문구에 넣지 않는다. 사용자별 키(`prefix:<사용자 ID>`)가 그대로
      // Sentry 로 올라간다. 어느 저장인지는 호출 스택이 알려 준다.
      throw StateError('SharedPreferences failed to persist a value');
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
