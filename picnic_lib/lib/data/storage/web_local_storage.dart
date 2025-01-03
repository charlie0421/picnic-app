// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:universal_platform/universal_platform.dart';

LocalStorage getInstance() => WebLocalStorage();

class WebLocalStorage implements LocalStorage {
  @override
  Future<void> saveData(String key, String value) async {
    if (UniversalPlatform.isWeb) {
      window.localStorage[key] = value;
    }
  }

  @override
  Future<String?> loadData(String key, dynamic defaultVale) async {
    return window.localStorage[key] ?? defaultVale;
  }

  @override
  Future<void> removeData(String key) async {
    window.localStorage.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    window.localStorage.clear();
  }
}

//web_platform.dart
