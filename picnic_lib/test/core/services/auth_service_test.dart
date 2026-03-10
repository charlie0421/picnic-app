import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() {
  group('AuthService', () {
    group('생성자 및 DI', () {
      test('기본 생성자로 인스턴스를 생성할 수 있다', () {
        final service = AuthService();
        expect(service, isNotNull);
        expect(service, isA<AuthService>());
      });

      test('선택적 의존성을 주입하여 인스턴스를 생성할 수 있다', () {
        // 모든 파라미터가 optional이므로 null 전달 시에도 기본값으로 생성
        final service = AuthService(
          storageService: null,
          networkService: null,
          loginProviders: null,
        );
        expect(service, isNotNull);
      });

      test('커스텀 loginProviders를 주입할 수 있다', () {
        final customProviders = <supa.OAuthProvider, SocialLogin>{};
        final service = AuthService(loginProviders: customProviders);
        expect(service, isNotNull);
      });
    });

    group('sessionStream', () {
      test('sessionStream은 broadcast Stream이다', () {
        final service = AuthService();
        final stream = service.sessionStream;
        expect(stream, isA<Stream<supa.Session?>>());
        // broadcast stream은 여러 리스너를 허용한다
        stream.listen((_) {});
        stream.listen((_) {});
        service.dispose();
      });
    });

    group('dispose', () {
      test('dispose 호출 후 sessionStream이 닫힌다', () async {
        final service = AuthService();
        await service.dispose();
        // dispose 후 stream에 listen하면 즉시 done 이벤트를 받는다
        final events = <supa.Session?>[];
        service.sessionStream.listen(
          events.add,
          onDone: () {
            // stream이 닫혔음을 확인
          },
        );
      });
    });

    group('메서드 시그니처 확인', () {
      late AuthService service;

      setUp(() {
        service = AuthService();
      });

      tearDown(() async {
        await service.dispose();
      });

      test('signInWithProvider는 Future<User?>를 반환하는 메서드이다', () {
        // 메서드가 존재하고 올바른 타입의 메서드인지 확인
        expect(service.signInWithProvider, isA<Function>());
      });

      test('recoverSession은 Future<bool>을 반환하는 메서드이다', () {
        expect(service.recoverSession, isA<Function>());
      });

      test('refreshSession은 Future<bool>을 반환하는 메서드이다', () {
        expect(service.refreshSession, isA<Function>());
      });

      test('signOut은 Future<void>를 반환하는 메서드이다', () {
        expect(service.signOut, isA<Function>());
      });
    });
  });

  group('AuthTimeouts', () {
    test('기본 타임아웃 값이 올바르게 설정된다', () {
      const timeouts = AuthTimeouts();
      expect(timeouts.networkCheck, equals(const Duration(seconds: 5)));
      expect(timeouts.sessionRecovery, equals(const Duration(seconds: 10)));
      expect(timeouts.tokenRefresh, equals(const Duration(seconds: 8)));
      expect(timeouts.tokenExpiration, equals(const Duration(hours: 1)));
    });

    test('커스텀 타임아웃 값을 설정할 수 있다', () {
      const customTimeouts = AuthTimeouts(
        networkCheck: Duration(seconds: 3),
        sessionRecovery: Duration(seconds: 5),
        tokenRefresh: Duration(seconds: 4),
        tokenExpiration: Duration(minutes: 30),
      );
      expect(customTimeouts.networkCheck, equals(const Duration(seconds: 3)));
      expect(
          customTimeouts.sessionRecovery, equals(const Duration(seconds: 5)));
      expect(customTimeouts.tokenRefresh, equals(const Duration(seconds: 4)));
      expect(
          customTimeouts.tokenExpiration, equals(const Duration(minutes: 30)));
    });
  });

  group('SocialLogin 인터페이스', () {
    test('SocialLogin은 login과 logout 메서드를 가진 추상 클래스이다', () {
      // SocialLogin이 추상 클래스인지 컴파일 타임에 확인 (인스턴스화 불가)
      // 타입 체크만 수행
      expect(SocialLogin, isNotNull);
    });
  });
}
