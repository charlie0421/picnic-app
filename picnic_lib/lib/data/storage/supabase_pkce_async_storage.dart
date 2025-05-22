// File: lib/storage/supabase_pkce_async_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditionally import dart:html only for web
import 'supabase_pkce_async_storage_web.dart'
    if (dart.library.io) 'supabase_pkce_async_storage_mobile.dart';

// This will be implemented differently for web and mobile
abstract class PlatformStorage implements GotrueAsyncStorage {
  factory PlatformStorage() => createPlatformStorage();
}

class PKCEMobile implements GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

// File: lib/storage/supabase_pkce_async_storage_web.dart
