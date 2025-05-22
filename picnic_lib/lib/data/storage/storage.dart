import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;

abstract class Storage {
  Future<void> write({required String key, required String? value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});

  Future<Map<String, String>> readAll();
}

class SecureStorage implements Storage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}

class WebStorage implements Storage {
  @override
  Future<void> write({required String key, required String? value}) async {
    html.window.localStorage[key] = value ?? '';
  }

  @override
  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(html.window.localStorage);
  }
}
