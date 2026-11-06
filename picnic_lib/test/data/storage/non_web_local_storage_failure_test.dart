import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/storage/non_web_local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ControllablePreferencesStore extends SharedPreferencesStorePlatform {
  _ControllablePreferencesStore(Map<String, Object> initial)
    : values = Map.of(initial);

  final Map<String, Object> values;
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    if (failReads) throw StateError('platform read failed');
    return Map.of(values);
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

void main() {
  test(
    'a false platform write restores the last persisted cache value',
    () async {
      final platform = _ControllablePreferencesStore({'flutter.reads': '[1]'});
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = platform;
      final storage = NonWebLocalStorage();
      expect(await storage.loadData('reads', null), '[1]');
      platform.failWrites = true;

      await expectLater(storage.saveData('reads', '[1,2]'), throwsStateError);

      expect(await storage.loadData('reads', null), '[1]');
      expect(platform.values['flutter.reads'], '[1]');
    },
  );

  // 아래 테스트들은 위 테스트가 만든 SharedPreferences 캐시를 공유할 수 있다
  // (NonWebLocalStorage._prefs 는 정적 필드). 그래서 각자 새 플랫폼을 꽂고,
  // 서로 겹치지 않는 키만 쓴다.
  _ControllablePreferencesStore installPlatform([
    Map<String, Object> initial = const {},
  ]) {
    final platform = _ControllablePreferencesStore(initial);
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = platform;
    return platform;
  }

  test('a successful write is stored and readable', () async {
    final platform = installPlatform();
    final storage = NonWebLocalStorage();

    await storage.saveData('ok_key', 'value-1');

    expect(await storage.loadData('ok_key', null), 'value-1');
    expect(platform.values['flutter.ok_key'], 'value-1');
  });

  test('a failed first write leaves no cached value behind', () async {
    final platform = installPlatform();
    final storage = NonWebLocalStorage();
    platform.failWrites = true;

    await expectLater(storage.saveData('fresh_key', 'value'), throwsStateError);

    expect(await storage.loadData('fresh_key', null), isNull);
    expect(platform.values.containsKey('flutter.fresh_key'), isFalse);
  });

  test('when reload also fails the previous cache value is restored', () async {
    final platform = installPlatform();
    final storage = NonWebLocalStorage();
    await storage.saveData('rollback_key', 'before');
    platform
      ..failWrites = true
      ..failReads = true;

    await expectLater(
      storage.saveData('rollback_key', 'after'),
      throwsStateError,
    );

    expect(await storage.loadData('rollback_key', null), 'before');
  });

  group('failure message never carries the storage key', () {
    // 사용자별 키는 `prefix:<식별자>` 형태다. 식별자가 UUID 가 아니어도(영숫자만,
    // 인코딩된 값, 임의 동적 키) 오류 문구에 남으면 Sentry 로 그대로 올라간다.
    // 모두 합성 값이다.
    const identities = <String>[
      '0f1e2d3c-4b5a-4968-8776-5a4b3c2d1e0f',
      'abcDEF0123456789xyz',
      'dXNlci1zeW50aGV0aWMtMDE=',
      'synthetic.person+tag@example.test',
    ];
    final keys = <String>[
      for (final identity in identities) 'pending_ad_rewards_v1:$identity',
      'profile_cache_${identities[1]}',
      identities[2],
    ];

    test('for every per-user or dynamic key shape', () async {
      final platform = installPlatform();
      final storage = NonWebLocalStorage();
      platform.failWrites = true;
      final messages = <String>[];

      for (final key in keys) {
        try {
          await storage.saveData(key, 'synthetic-value');
          fail('saveData must throw when the platform write fails');
        } on StateError catch (error) {
          messages.add(error.toString());
        }
      }

      for (final message in messages) {
        for (final identity in identities) {
          expect(message, isNot(contains(identity)));
        }
        for (final key in keys) {
          expect(message, isNot(contains(key)));
        }
        expect(message, isNot(contains('synthetic-value')));
      }
      // 키에서 일부라도 뽑아 쓰면(앞부분 자르기·정규식) 키마다 문구가 달라진다.
      expect(messages.toSet(), hasLength(1));
    });
  });
}
