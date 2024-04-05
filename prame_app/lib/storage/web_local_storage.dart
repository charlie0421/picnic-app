import 'dart:html';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:prame_app/storage/local_storage.dart';

LocalStorage getInstance() => WebLocalStorage();

class WebLocalStorage implements LocalStorage {
  @override
  Future<void> saveData(String key, String value) async {
    if (kIsWeb) {
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
