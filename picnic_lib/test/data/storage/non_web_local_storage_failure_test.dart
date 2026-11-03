import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/storage/non_web_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ControllablePreferencesStore extends SharedPreferencesStorePlatform {
  _ControllablePreferencesStore(Map<String, Object> initial)
    : values = Map.of(initial);

  final Map<String, Object> values;
  bool failWrites = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async => Map.of(values);

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

void main() {
  test(
    'a false platform write restores the last persisted cache value',
    () async {
      final platform = _ControllablePreferencesStore({'flutter.reads': '[1]'});
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = platform;
      final storage = NonWebLocalStorage();
      expect(await storage.loadData('reads', null), '[1]');
      platform.failWrites = true;

      await expectLater(storage.saveData('reads', '[1,2]'), throwsStateError);

      expect(await storage.loadData('reads', null), '[1]');
      expect(platform.values['flutter.reads'], '[1]');
    },
  );
}
