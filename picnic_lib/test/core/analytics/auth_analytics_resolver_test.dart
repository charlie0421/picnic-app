import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_resolver.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';

void main() {
  group('resolveMethod', () {
    test('Supabase app_metadata.provider 값이 스펙 예시값과 그대로 일치한다', () {
      expect(AuthAnalyticsResolver.resolveMethod('apple'),
          Ga4LoginMethod.apple);
      expect(AuthAnalyticsResolver.resolveMethod('google'),
          Ga4LoginMethod.google);
      expect(AuthAnalyticsResolver.resolveMethod('kakao'),
          Ga4LoginMethod.kakao);
    });

    test('대소문자/공백을 정규화한다', () {
      expect(AuthAnalyticsResolver.resolveMethod(' Google '),
          Ga4LoginMethod.google);
      expect(AuthAnalyticsResolver.resolveMethod('KAKAO'),
          Ga4LoginMethod.kakao);
    });

    test('값이 없으면 undefined 로 대체한다', () {
      expect(AuthAnalyticsResolver.resolveMethod(null), Ga4Value.undefined);
      expect(AuthAnalyticsResolver.resolveMethod(''), Ga4Value.undefined);
      expect(AuthAnalyticsResolver.resolveMethod('  '), Ga4Value.undefined);
    });

    test('스펙 외 provider 는 원문을 유지해 대행사가 발견할 수 있게 한다', () {
      expect(AuthAnalyticsResolver.resolveMethod('email'), 'email');
    });
  });

  group('isFreshSignUp', () {
    test('created_at 과 last_sign_in_at 이 같은 순간이면 신규 가입', () {
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: '2026-08-07T01:00:00.000Z',
          lastSignInAt: '2026-08-07T01:00:00.100Z',
        ),
        isTrue,
      );
    });

    test('30초 창 경계값은 신규 가입으로 본다', () {
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: '2026-08-07T01:00:00.000Z',
          lastSignInAt: '2026-08-07T01:00:30.000Z',
        ),
        isTrue,
      );
    });

    test('가입 이후 다시 로그인한 사용자는 신규 가입이 아니다', () {
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: '2026-01-01T00:00:00.000Z',
          lastSignInAt: '2026-08-07T01:00:00.000Z',
        ),
        isFalse,
      );
    });

    test('타임존 표기가 달라도 UTC 로 비교한다', () {
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: '2026-08-07T10:00:00+09:00',
          lastSignInAt: '2026-08-07T01:00:01.000Z',
        ),
        isTrue,
      );
    });

    test('파싱 실패 시 false — 잘못된 sign_up 폭주보다 1건 누락이 낫다', () {
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: null,
          lastSignInAt: '2026-08-07T01:00:00.000Z',
        ),
        isFalse,
      );
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: '2026-08-07T01:00:00.000Z',
          lastSignInAt: null,
        ),
        isFalse,
      );
      expect(
        AuthAnalyticsResolver.isFreshSignUp(
          createdAt: 'not-a-date',
          lastSignInAt: 'also-not-a-date',
        ),
        isFalse,
      );
    });
  });

  group('buildLoginSignature', () {
    test('userId 와 last_sign_in_at 을 결합한다', () {
      expect(
        AuthAnalyticsResolver.buildLoginSignature(
          userId: 'u1',
          lastSignInAt: '2026-08-07T01:00:00.000Z',
        ),
        'u1|2026-08-07T01:00:00.000Z',
      );
    });

    test('last_sign_in_at 이 없으면 userId 만으로 서명한다', () {
      expect(
        AuthAnalyticsResolver.buildLoginSignature(
          userId: 'u1',
          lastSignInAt: null,
        ),
        'u1|',
      );
    });
  });

  group('decide', () {
    AuthAnalyticsDecision decide({
      String? persistedLoginSignature,
      bool signUpAlreadyLogged = false,
      String createdAt = '2026-01-01T00:00:00.000Z',
      String lastSignInAt = '2026-08-07T01:00:00.000Z',
      String? provider = 'kakao',
    }) {
      return AuthAnalyticsResolver.decide(
        userId: 'u1',
        provider: provider,
        createdAt: createdAt,
        lastSignInAt: lastSignInAt,
        persistedLoginSignature: persistedLoginSignature,
        signUpAlreadyLogged: signUpAlreadyLogged,
      );
    }

    test('최초 로그인(기존 사용자)은 login 만 보낸다', () {
      final d = decide();
      expect(d.shouldLogLogin, isTrue);
      expect(d.shouldLogSignUp, isFalse);
      expect(d.method, Ga4LoginMethod.kakao);
    });

    test('신규 가입은 sign_up 과 login 을 모두 보낸다', () {
      final d = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.500Z',
      );
      expect(d.shouldLogSignUp, isTrue);
      expect(d.shouldLogLogin, isTrue);
    });

    test('앱 재시작 세션 복원(같은 서명)은 login 을 보내지 않는다', () {
      final first = decide();
      final second = decide(persistedLoginSignature: first.loginSignature);

      expect(second.shouldLogLogin, isFalse);
      expect(second.shouldLogSignUp, isFalse);
    });

    test('같은 사용자가 실제로 재로그인하면 서명이 바뀌어 login 이 다시 나간다', () {
      final first = decide(lastSignInAt: '2026-08-07T01:00:00.000Z');
      final second = decide(
        lastSignInAt: '2026-08-07T05:00:00.000Z',
        persistedLoginSignature: first.loginSignature,
      );

      expect(second.shouldLogLogin, isTrue);
      expect(second.shouldLogSignUp, isFalse);
    });

    test('이미 sign_up 을 보낸 사용자는 시각 조건을 만족해도 다시 보내지 않는다', () {
      final d = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:10.000Z',
        signUpAlreadyLogged: true,
      );

      expect(d.shouldLogSignUp, isFalse);
      expect(d.shouldLogLogin, isTrue);
    });

    test('중복 로그인 판정은 sign_up 재시도를 막지 않는다', () {
      // 최초 signedIn 에서 sign_up outbox 저장만 실패하고 login 저장은 성공하면
      // 서명이 남는다. 그때 sign_up 을 login 중복과 함께 억제하면 outbox 에
      // signup 항목이 없으므로 영구 누락이다. 재발송 방지는 마커와 outbox 의
      // `signup:<userId>` dedup 이 담당하므로 여기서는 true 여야 한다.
      final first = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.500Z',
      );
      final second = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.500Z',
        persistedLoginSignature: first.loginSignature,
      );

      expect(second.shouldLogSignUp, isTrue);
      expect(second.shouldLogLogin, isFalse);
    });

    test('중복 로그인이라도 sign_up 마커가 있으면 sign_up 은 나가지 않는다', () {
      final first = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.500Z',
      );
      final second = decide(
        createdAt: '2026-08-07T01:00:00.000Z',
        lastSignInAt: '2026-08-07T01:00:00.500Z',
        persistedLoginSignature: first.loginSignature,
        signUpAlreadyLogged: true,
      );

      expect(second.shouldLogSignUp, isFalse);
      expect(second.shouldLogLogin, isFalse);
    });

    test('provider 를 알 수 없으면 method 는 undefined', () {
      expect(decide(provider: null).method, Ga4Value.undefined);
    });
  });
}
