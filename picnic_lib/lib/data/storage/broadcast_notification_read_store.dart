import 'dart:async';
import 'dart:convert';

import 'package:picnic_lib/data/storage/local_storage.dart';

class BroadcastNotificationReadStore {
  BroadcastNotificationReadStore({LocalStorage? storage})
    : _storage = storage ?? LocalStorage();

  static const String _keyPrefix = 'broadcast_notification_reads_v1';
  static final Map<String, Future<void>> _operationTails = {};

  final LocalStorage _storage;

  String _key(String? accountId) {
    final scope = accountId == null ? 'guest' : 'user:$accountId';
    return '$_keyPrefix.${base64Url.encode(utf8.encode(scope))}';
  }

  Future<T> _serialized<T>(String key, Future<T> Function() operation) {
    final previous = _operationTails[key] ?? Future<void>.value();
    final result = previous.catchError((_) {}).then((_) => operation());
    late final Future<void> tracked;
    tracked = result.then<void>((_) {}, onError: (_, _) {}).whenComplete(() {
      if (identical(_operationTails[key], tracked)) {
        _operationTails.remove(key);
      }
    });
    _operationTails[key] = tracked;
    return result;
  }

  Future<Set<int>> readIds(String? accountId) {
    final key = _key(accountId);
    return _serialized(key, () => _read(key));
  }

  Future<void> markRead(String? accountId, int notificationId) {
    final key = _key(accountId);
    return _serialized(key, () async {
      final ids = (await _read(key))..add(notificationId);
      await _write(key, ids);
    });
  }

  Future<void> markAllRead(String? accountId, Iterable<int> notificationIds) {
    final key = _key(accountId);
    return _serialized(key, () async {
      final ids = (await _read(key))..addAll(notificationIds);
      await _write(key, ids);
    });
  }

  Future<Set<int>> _read(String key) async {
    final raw = await _storage.loadData(key, '[]') ?? '[]';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>{};
      return decoded
          .map((value) => value is int ? value : int.tryParse('$value'))
          .whereType<int>()
          .toSet();
    } on FormatException {
      return <int>{};
    }
  }

  Future<void> _write(String key, Set<int> ids) async {
    final sorted = ids.toList()..sort();
    await _storage.saveData(key, jsonEncode(sorted));
  }
}
