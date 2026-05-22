// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ThrowingFlutterSecureStoragePlatform extends FlutterSecureStoragePlatform {
  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      false;

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {}

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {}

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async =>
      null;

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    // PICNIC-APP-58P 의 Android Keystore NPE/PlatformException 시뮬레이션
    throw PlatformException(
      code: 'Exception encountered, write',
      message: "java.lang.NullPointerException: Attempt to invoke virtual method "
          "'byte[] TF0.a(byte[])' on a null object reference",
    );
  }
}

void main() {
  late FlutterSecureStorage storage;
  late SecureStorageService service;

  setUp(() {
    // FlutterSecureStorage의 테스트용 mock 초기값 설정
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    service = SecureStorageService(storage);
  });

  group('SecureStorageService - getSession', () {
    test('저장된 세션이 없으면 null을 반환해야 함', () async {
      // Act
      final result = await service.getSession();

      // Assert
      expect(result, isNull);
    });

    test('유효한 세션 JSON이 저장되어 있으면 Session 객체를 반환해야 함', () async {
      // Arrange - 유효한 Supabase Session JSON을 직접 저장
      const validSessionJson = '{'
          '"access_token":"test_access_token",'
          '"token_type":"bearer",'
          '"expires_in":3600,'
          '"refresh_token":"test_refresh_token",'
          '"user":{"id":"test-user-id","app_metadata":{},"user_metadata":{},"aud":"authenticated","created_at":"2024-01-01T00:00:00.000Z"}'
          '}';
      await storage.write(key: 'session', value: validSessionJson);

      // Act
      final result = await service.getSession();

      // Assert
      expect(result, isNotNull);
      expect(result!.accessToken, equals('test_access_token'));
      expect(result.refreshToken, equals('test_refresh_token'));
      expect(result.tokenType, equals('bearer'));
    });

    test('잘못된 JSON이 저장되어 있으면 null을 반환해야 함', () async {
      // Arrange
      await storage.write(key: 'session', value: 'invalid_json{{{');

      // Act
      final result = await service.getSession();

      // Assert - catch 블록에서 null 반환
      expect(result, isNull);
    });
  });

  group('SecureStorageService - saveSession/getSession 라운드트립', () {
    test('saveSession으로 저장한 세션을 getSession으로 조회할 수 있어야 함', () async {
      // Arrange - 유효한 세션을 저장소에 넣어 Session 객체를 생성
      const sessionJson = '{'
          '"access_token":"roundtrip_token",'
          '"token_type":"bearer",'
          '"expires_in":7200,'
          '"refresh_token":"roundtrip_refresh",'
          '"user":{"id":"rt-user-id","app_metadata":{},"user_metadata":{},"aud":"authenticated","created_at":"2024-01-01T00:00:00.000Z"}'
          '}';
      await storage.write(key: 'session', value: sessionJson);

      // Act - Session 객체 로드
      final session = await service.getSession();
      expect(session, isNotNull);

      // saveSession으로 다시 저장
      await service.saveSession(session!);

      // 다시 조회
      final reloaded = await service.getSession();

      // Assert
      expect(reloaded, isNotNull);
      expect(reloaded!.accessToken, equals('roundtrip_token'));
      expect(reloaded.refreshToken, equals('roundtrip_refresh'));
    });
  });

  group('SecureStorageService - clearSession', () {
    test('clearSession은 세션 데이터를 삭제해야 함', () async {
      // Arrange
      await storage.write(key: 'session', value: '{"data": true}');
      final before = await storage.read(key: 'session');
      expect(before, isNotNull);

      // Act
      await service.clearSession();

      // Assert
      final after = await storage.read(key: 'session');
      expect(after, isNull);
    });

    test('삭제 후 getSession은 null을 반환해야 함', () async {
      // Arrange - 유효한 세션 저장
      const sessionJson = '{'
          '"access_token":"to_delete",'
          '"token_type":"bearer",'
          '"expires_in":3600,'
          '"refresh_token":"del_refresh",'
          '"user":{"id":"del-id","app_metadata":{},"user_metadata":{},"aud":"authenticated","created_at":"2024-01-01T00:00:00.000Z"}'
          '}';
      await storage.write(key: 'session', value: sessionJson);

      // 저장 확인
      final beforeDelete = await service.getSession();
      expect(beforeDelete, isNotNull);

      // Act
      await service.clearSession();

      // Assert
      final afterDelete = await service.getSession();
      expect(afterDelete, isNull);
    });

    test('세션이 없는 상태에서 clearSession을 호출해도 에러가 발생하지 않아야 함', () async {
      // Act & Assert
      expect(() => service.clearSession(), returnsNormally);
    });
  });

  group('SecureStorageService - 생성자', () {
    test('storage를 주입하지 않으면 기본 FlutterSecureStorage를 사용해야 함', () {
      expect(() => SecureStorageService(), returnsNormally);
    });

    test('커스텀 storage를 주입할 수 있어야 함', () {
      FlutterSecureStorage.setMockInitialValues({});
      final customStorage = const FlutterSecureStorage();
      final customService = SecureStorageService(customStorage);
      expect(customService, isNotNull);
    });
  });

  group('SecureStorageService - saveSession 의 keystore 실패 swallow (PICNIC-APP-58P)', () {
    test('write 가 PlatformException 을 throw 해도 rethrow 하지 않아야 함', () async {
      // Arrange — 일부 Android 단말의 Keystore NPE 재현
      FlutterSecureStoragePlatform.instance = _ThrowingFlutterSecureStoragePlatform();
      final throwingService = SecureStorageService(const FlutterSecureStorage());

      final session = Session.fromJson({
        'access_token': 'test',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'test_refresh',
        'user': {
          'id': 'u',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2024-01-01T00:00:00.000Z',
        },
      })!;

      // Act & Assert — rethrow 하지 않고 정상 return
      await expectLater(throwingService.saveSession(session), completes);
    });
  });

  group('SecureStorageService - 초기값이 있는 경우', () {
    test('초기값으로 설정된 세션을 읽을 수 있어야 함', () async {
      // Arrange - 초기값에 유효한 세션 JSON 포함
      const sessionJson = '{'
          '"access_token":"initial_token",'
          '"token_type":"bearer",'
          '"expires_in":3600,'
          '"refresh_token":"initial_refresh",'
          '"user":{"id":"init-id","app_metadata":{},"user_metadata":{},"aud":"authenticated","created_at":"2024-01-01T00:00:00.000Z"}'
          '}';
      FlutterSecureStorage.setMockInitialValues({
        'session': sessionJson,
      });
      final initService = SecureStorageService(const FlutterSecureStorage());

      // Act
      final result = await initService.getSession();

      // Assert
      expect(result, isNotNull);
      expect(result!.accessToken, equals('initial_token'));
    });
  });
}
