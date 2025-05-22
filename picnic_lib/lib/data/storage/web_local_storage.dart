import 'package:web/web.dart' as web;

import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:universal_platform/universal_platform.dart';

LocalStorage getInstance() => WebLocalStorage();

class WebLocalStorage implements LocalStorage {
  @override
  Future<void> saveData(String key, String value) async {
    if (UniversalPlatform.isWeb) {
      web.window.localStorage.setItem(key, value);
    }
  }

  @override
  Future<String?> loadData(String key, dynamic defaultVale) async {
    return web.window.localStorage.getItem(key) ?? defaultVale;
  }

  @override
  Future<void> removeData(String key) async {
    web.window.localStorage.removeItem(key);
  }

  @override
  Future<void> clearStorage() async {
    web.window.localStorage.clear();
  }
}
