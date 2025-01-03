import 'supabase_pkce_async_storage.dart';

class MobileStorage implements PlatformStorage {
  final PKCEMobile _storage = PKCEMobile();

  @override
  Future<String?> getItem({required String key}) => _storage.getItem(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.setItem(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.removeItem(key: key);
}

PlatformStorage createPlatformStorage() => MobileStorage();
