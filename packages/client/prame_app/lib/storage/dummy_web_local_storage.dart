import 'local_storage.dart';

class WebLocalStorage implements LocalStorage {
  @override
  Future<void> saveData(String key, String value) async {}

  @override
  Future<String?> loadData(String key) async {
    return null;
  }

  @override
  Future<void> removeData(String key) async {}

  @override
  Future<void> clearStorage() async {}
}
