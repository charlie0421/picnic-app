import 'package:picnic_lib/data/storage/local_storage_factory.dart'
    if (dart.library.html) './web_local_storage.dart'
    if (dart.library.io) './non_web_local_storage.dart';

abstract class LocalStorage {
  factory LocalStorage() => getInstance();

  Future<void> saveData(String key, String value);

  Future<String?> loadData(String key, String? defaultValue);

  Future<void> removeData(String key);

  Future<void> clearStorage();
}
