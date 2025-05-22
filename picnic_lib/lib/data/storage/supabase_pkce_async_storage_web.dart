import 'package:web/web.dart' as web;

import 'package:picnic_lib/data/storage/supabase_pkce_async_storage.dart';

class PKCEWebStorage implements PlatformStorage {
  @override
  Future<String?> getItem({required String key}) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    web.window.localStorage.removeItem(key);
  }
}

PlatformStorage createPlatformStorage() => PKCEWebStorage();
