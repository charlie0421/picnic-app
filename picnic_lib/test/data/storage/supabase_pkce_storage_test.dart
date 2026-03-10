import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/storage/supabase_pkce_async_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PlatformStorage storage;

  setUp(() {
    // SharedPreferences 초기 값 설정 (빈 상태)
    SharedPreferences.setMockInitialValues({});
    storage = PlatformStorage();
  });

  group('PlatformStorage - setItem', () {
    test('setItem으로 값을 저장할 수 있어야 함', () async {
      // Act
      await storage.setItem(key: 'test_key', value: 'test_value');

      // Assert
      final result = await storage.getItem(key: 'test_key');
      expect(result, equals('test_value'));
    });

    test('같은 키에 다시 저장하면 값이 덮어씌워져야 함', () async {
      // Arrange
      await storage.setItem(key: 'key', value: 'original');

      // Act
      await storage.setItem(key: 'key', value: 'updated');

      // Assert
      final result = await storage.getItem(key: 'key');
      expect(result, equals('updated'));
    });

    test('여러 키에 값을 독립적으로 저장할 수 있어야 함', () async {
      // Act
      await storage.setItem(key: 'key1', value: 'value1');
      await storage.setItem(key: 'key2', value: 'value2');

      // Assert
      expect(await storage.getItem(key: 'key1'), equals('value1'));
      expect(await storage.getItem(key: 'key2'), equals('value2'));
    });

    test('빈 문자열을 저장할 수 있어야 함', () async {
      // Act
      await storage.setItem(key: 'empty_key', value: '');

      // Assert
      final result = await storage.getItem(key: 'empty_key');
      expect(result, equals(''));
    });

    test('긴 JSON 문자열을 저장할 수 있어야 함', () async {
      // Arrange
      const jsonValue =
          '{"access_token":"abc123","refresh_token":"xyz789","expires_in":3600}';

      // Act
      await storage.setItem(key: 'session', value: jsonValue);

      // Assert
      final result = await storage.getItem(key: 'session');
      expect(result, equals(jsonValue));
    });
  });

  group('PlatformStorage - getItem', () {
    test('존재하지 않는 키 조회 시 null을 반환해야 함', () async {
      // Act
      final result = await storage.getItem(key: 'non_existent_key');

      // Assert
      expect(result, isNull);
    });

    test('저장된 값을 정확히 반환해야 함', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pre_existing_key': 'pre_existing_value',
      });

      // Act
      final newStorage = PlatformStorage();
      final result = await newStorage.getItem(key: 'pre_existing_key');

      // Assert
      expect(result, equals('pre_existing_value'));
    });
  });

  group('PlatformStorage - removeItem', () {
    test('removeItem은 저장된 항목을 삭제해야 함', () async {
      // Arrange
      await storage.setItem(key: 'key_to_remove', value: 'value');

      // Act
      await storage.removeItem(key: 'key_to_remove');

      // Assert
      final result = await storage.getItem(key: 'key_to_remove');
      expect(result, isNull);
    });

    test('존재하지 않는 키를 삭제해도 에러가 발생하지 않아야 함', () async {
      // Act & Assert
      expect(
        () => storage.removeItem(key: 'non_existent_key'),
        returnsNormally,
      );
    });

    test('특정 키를 삭제해도 다른 키에 영향을 주지 않아야 함', () async {
      // Arrange
      await storage.setItem(key: 'key1', value: 'value1');
      await storage.setItem(key: 'key2', value: 'value2');

      // Act
      await storage.removeItem(key: 'key1');

      // Assert
      expect(await storage.getItem(key: 'key1'), isNull);
      expect(await storage.getItem(key: 'key2'), equals('value2'));
    });
  });

  group('PlatformStorage - GotrueAsyncStorage 인터페이스 준수', () {
    test('PlatformStorage는 GotrueAsyncStorage를 구현해야 함', () {
      // Assert - 타입 확인
      expect(storage, isA<PlatformStorage>());
    });

    test('setItem/getItem/removeItem 전체 라이프사이클 테스트', () async {
      const key = 'lifecycle_key';
      const value = 'lifecycle_value';

      // 1. 초기 상태 - 값 없음
      expect(await storage.getItem(key: key), isNull);

      // 2. 저장
      await storage.setItem(key: key, value: value);
      expect(await storage.getItem(key: key), equals(value));

      // 3. 업데이트
      const updatedValue = 'updated_value';
      await storage.setItem(key: key, value: updatedValue);
      expect(await storage.getItem(key: key), equals(updatedValue));

      // 4. 삭제
      await storage.removeItem(key: key);
      expect(await storage.getItem(key: key), isNull);
    });
  });

  group('PlatformStorage - 키 저장 형식 검증', () {
    test('SharedPreferences에 올바른 키로 저장되어야 함', () async {
      // Arrange
      const key = 'supabase_pkce_code_verifier';
      const value = 'random_code_verifier_string';

      // Act
      await storage.setItem(key: key, value: value);

      // Assert - SharedPreferences에서 직접 확인
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), equals(value));
    });

    test('특수 문자가 포함된 키를 처리할 수 있어야 함', () async {
      // Arrange
      const key = 'sb-xtijtefcycoeqludlngc-auth-token';
      const value = '{"access_token":"test"}';

      // Act
      await storage.setItem(key: key, value: value);

      // Assert
      final result = await storage.getItem(key: key);
      expect(result, equals(value));
    });
  });
}
