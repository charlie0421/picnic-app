import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/storage.dart';

// LocalStorage 인터페이스의 Mock 구현
class MockLocalStorage extends Mock implements LocalStorage {}

// Storage 인터페이스의 Mock 구현
class MockStorage extends Mock implements Storage {}

// LocalStorage 인터페이스를 수동으로 구현한 테스트용 클래스
class InMemoryLocalStorage implements LocalStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> saveData(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    return _store[key] ?? defaultValue;
  }

  @override
  Future<void> removeData(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    _store.clear();
  }
}

// Storage 인터페이스를 수동으로 구현한 테스트용 클래스
class InMemoryStorage implements Storage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_store);
  }
}

void main() {
  group('LocalStorage 인터페이스', () {
    late InMemoryLocalStorage storage;

    setUp(() {
      storage = InMemoryLocalStorage();
    });

    group('saveData / loadData', () {
      test('데이터를 저장하고 불러올 수 있다', () async {
        await storage.saveData('key1', 'value1');
        final result = await storage.loadData('key1', null);
        expect(result, 'value1');
      });

      test('같은 키로 덮어쓰기할 수 있다', () async {
        await storage.saveData('key1', 'old');
        await storage.saveData('key1', 'new');
        final result = await storage.loadData('key1', null);
        expect(result, 'new');
      });

      test('존재하지 않는 키는 defaultValue를 반환한다', () async {
        final result = await storage.loadData('nonexistent', 'default');
        expect(result, 'default');
      });

      test('존재하지 않는 키에 defaultValue가 null이면 null을 반환한다', () async {
        final result = await storage.loadData('nonexistent', null);
        expect(result, isNull);
      });

      test('빈 문자열도 저장할 수 있다', () async {
        await storage.saveData('empty', '');
        final result = await storage.loadData('empty', 'default');
        expect(result, '');
      });

      test('긴 문자열을 저장하고 불러올 수 있다', () async {
        final longValue = 'a' * 10000;
        await storage.saveData('long', longValue);
        final result = await storage.loadData('long', null);
        expect(result, longValue);
      });

      test('한글 데이터를 저장하고 불러올 수 있다', () async {
        await storage.saveData('korean', '안녕하세요');
        final result = await storage.loadData('korean', null);
        expect(result, '안녕하세요');
      });

      test('JSON 문자열을 저장하고 불러올 수 있다', () async {
        const jsonString = '{"name":"test","value":123}';
        await storage.saveData('json', jsonString);
        final result = await storage.loadData('json', null);
        expect(result, jsonString);
      });
    });

    group('removeData', () {
      test('저장된 데이터를 삭제할 수 있다', () async {
        await storage.saveData('key1', 'value1');
        await storage.removeData('key1');
        final result = await storage.loadData('key1', null);
        expect(result, isNull);
      });

      test('존재하지 않는 키를 삭제해도 에러가 발생하지 않는다', () async {
        await expectLater(
          storage.removeData('nonexistent'),
          completes,
        );
      });

      test('삭제 후 다른 키의 데이터는 영향받지 않는다', () async {
        await storage.saveData('key1', 'value1');
        await storage.saveData('key2', 'value2');
        await storage.removeData('key1');

        final result1 = await storage.loadData('key1', null);
        final result2 = await storage.loadData('key2', null);
        expect(result1, isNull);
        expect(result2, 'value2');
      });
    });

    group('clearStorage', () {
      test('모든 데이터를 삭제할 수 있다', () async {
        await storage.saveData('key1', 'value1');
        await storage.saveData('key2', 'value2');
        await storage.saveData('key3', 'value3');

        await storage.clearStorage();

        final result1 = await storage.loadData('key1', null);
        final result2 = await storage.loadData('key2', null);
        final result3 = await storage.loadData('key3', null);
        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      test('빈 스토리지를 clear해도 에러가 발생하지 않는다', () async {
        await expectLater(storage.clearStorage(), completes);
      });
    });
  });

  group('Storage 인터페이스', () {
    late InMemoryStorage storage;

    setUp(() {
      storage = InMemoryStorage();
    });

    group('write / read', () {
      test('데이터를 쓰고 읽을 수 있다', () async {
        await storage.write(key: 'token', value: 'abc123');
        final result = await storage.read(key: 'token');
        expect(result, 'abc123');
      });

      test('null 값을 쓰면 해당 키가 삭제된다', () async {
        await storage.write(key: 'token', value: 'abc123');
        await storage.write(key: 'token', value: null);
        final result = await storage.read(key: 'token');
        expect(result, isNull);
      });

      test('존재하지 않는 키를 읽으면 null을 반환한다', () async {
        final result = await storage.read(key: 'nonexistent');
        expect(result, isNull);
      });

      test('같은 키로 덮어쓰기할 수 있다', () async {
        await storage.write(key: 'key', value: 'first');
        await storage.write(key: 'key', value: 'second');
        final result = await storage.read(key: 'key');
        expect(result, 'second');
      });
    });

    group('delete', () {
      test('저장된 데이터를 삭제할 수 있다', () async {
        await storage.write(key: 'token', value: 'abc123');
        await storage.delete(key: 'token');
        final result = await storage.read(key: 'token');
        expect(result, isNull);
      });

      test('존재하지 않는 키를 삭제해도 에러가 발생하지 않는다', () async {
        await expectLater(
          storage.delete(key: 'nonexistent'),
          completes,
        );
      });
    });

    group('readAll', () {
      test('모든 저장된 데이터를 읽을 수 있다', () async {
        await storage.write(key: 'key1', value: 'value1');
        await storage.write(key: 'key2', value: 'value2');

        final all = await storage.readAll();
        expect(all.length, 2);
        expect(all['key1'], 'value1');
        expect(all['key2'], 'value2');
      });

      test('빈 스토리지에서 readAll은 빈 맵을 반환한다', () async {
        final all = await storage.readAll();
        expect(all, isEmpty);
      });

      test('readAll의 반환값을 수정해도 원본에 영향이 없다', () async {
        await storage.write(key: 'key1', value: 'value1');

        final all = await storage.readAll();
        all['key1'] = 'modified';

        final original = await storage.read(key: 'key1');
        expect(original, 'value1');
      });
    });
  });

  group('Mock 클래스 타입 검증', () {
    test('MockLocalStorage는 LocalStorage 인터페이스를 구현한다', () {
      final mock = MockLocalStorage();
      expect(mock, isA<LocalStorage>());
    });

    test('MockStorage는 Storage 인터페이스를 구현한다', () {
      final mock = MockStorage();
      expect(mock, isA<Storage>());
    });

    test('InMemoryLocalStorage는 LocalStorage 인터페이스를 구현한다', () {
      final storage = InMemoryLocalStorage();
      expect(storage, isA<LocalStorage>());
    });

    test('InMemoryStorage는 Storage 인터페이스를 구현한다', () {
      final storage = InMemoryStorage();
      expect(storage, isA<Storage>());
    });
  });
}
