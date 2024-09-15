import 'dart:html' as html;

import 'package:picnic_app/storage/supabase_pkce_async_storage.dart';

class PKCEWebStorage implements PlatformStorage {
  @override
  Future<String?> getItem({required String key}) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    html.window.localStorage.remove(key);
  }
}

PlatformStorage createPlatformStorage() => PKCEWebStorage();

// File: lib/storage/supabase_pkce_async_storage_mobile.dart
