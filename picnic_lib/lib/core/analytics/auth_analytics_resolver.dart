import 'package:flutter/foundation.dart';

import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';

/// `login` / `sign_up` 을 발송할지, 어떤 `method` 로 발송할지 판정하는 순수 로직.
///
/// Firebase·Supabase·저장소에 의존하지 않으므로 단위 테스트로 전 경우를 덮을 수
/// 있다. 호출부(app_initializer 의 auth 리스너)는 여기 결과를 그대로 따른다.
@immutable
class AuthAnalyticsDecision {
  const AuthAnalyticsDecision({
    required this.shouldLogLogin,
    required this.shouldLogSignUp,
    required this.method,
    required this.loginSignature,
  });

  /// `login` 이벤트를 보내야 하는가.
  final bool shouldLogLogin;

  /// `sign_up` 이벤트를 보내야 하는가.
  ///
  /// login 중복(세션 복원) 판정과는 독립이다 — 함께 억제하면 sign_up outbox
  /// 저장만 실패하고 login 저장은 성공한 최초 가입이 영구 누락된다.
  /// 중복 발송 방지는 [AuthAnalyticsResolver.decide] 의 signUpAlreadyLogged
  /// 마커와 outbox 의 `signup:<userId>` id dedup 두 겹이 담당한다.
  final bool shouldLogSignUp;

  /// `method` 파라미터 값 (`apple` / `google` / `kakao`, 판별 불가 시 `undefined`).
  final String method;

  /// 이번 로그인 세션의 서명. 발송 후 저장해두면 다음 실행에서 중복을 막는다.
  final String loginSignature;

  @override
  String toString() =>
      'AuthAnalyticsDecision(login=$shouldLogLogin, '
      'signUp=$shouldLogSignUp, method=$method, signature=$loginSignature)';
}

class AuthAnalyticsResolver {
  const AuthAnalyticsResolver._();

  /// 신규 가입 판정 허용 오차.
  ///
  /// Supabase 는 최초 가입 시 `created_at` 을 기록하고, 같은 요청에서
  /// `last_sign_in_at` 을 세팅한다. 두 값은 같은 트랜잭션에서 찍히므로
  /// 실제로는 밀리초 단위 차이지만, 서버 시각 반올림·재시도를 감안해
  /// 여유를 둔다. 이 창을 크게 잡으면 "가입 직후 재로그인"이 sign_up 으로
  /// 오분류되지만, 그 경우는 [signUpAlreadyLogged] 마커가 한 번 더 막는다.
  static const Duration signUpWindow = Duration(seconds: 30);

  /// Supabase user 의 `app_metadata.provider` 를 스펙의 `method` 값으로 매핑한다.
  ///
  /// 실제 코드 확인 결과 `AuthService.signInWithProvider` 는
  /// `supa.OAuthProvider.{google,apple,kakao}` 로 `signInWithIdToken` 을 호출하고,
  /// Supabase 는 `app_metadata.provider` 에 그 enum 의 이름을 그대로
  /// (`'google'` / `'apple'` / `'kakao'`) 기록한다. 즉 스펙 예시값과 동일해서
  /// 별도 매핑 테이블이 필요 없다. 다만 향후 provider 가 추가되거나
  /// (`'email'`, `'phone'`) 값이 비면 스펙 §2 규칙대로 `'undefined'` 로 보낸다.
  static String resolveMethod(String? provider) {
    final normalized = provider?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return Ga4Value.undefined;
    if (Ga4LoginMethod.all.contains(normalized)) return normalized;
    return normalized.length <= 100 ? normalized : Ga4Value.undefined;
  }

  /// 세션 서명. 같은 사용자라도 실제 로그인을 다시 하면 `last_sign_in_at` 이
  /// 갱신되므로 서명이 바뀐다. 앱 재시작으로 세션이 복원돼 `signedIn` 이
  /// 재발화하는 경우에는 두 값이 모두 그대로라 서명이 동일하다 → 중복 차단.
  ///
  /// `last_sign_in_at` 이 없는 예외 상황에서는 userId 만으로 서명을 만든다.
  /// 이때는 "로그아웃 시 저장된 서명을 지운다"는 규칙이 중복 차단을 대신한다.
  static String buildLoginSignature({
    required String userId,
    required String? lastSignInAt,
  }) {
    return '$userId|${lastSignInAt ?? ''}';
  }

  /// `created_at` 과 `last_sign_in_at` 이 [signUpWindow] 안에 있으면 신규 가입.
  ///
  /// 파싱 실패(둘 중 하나라도 없음/형식 오류)는 **false** 로 본다.
  /// 잘못 true 를 내면 매 로그인마다 sign_up 이 나가서 가입 지표가 무의미해지는
  /// 반면, false 로 놓치면 가입 1건이 빠질 뿐이라 피해가 훨씬 작다.
  static bool isFreshSignUp({
    required String? createdAt,
    required String? lastSignInAt,
    Duration window = signUpWindow,
  }) {
    final created = _parseUtc(createdAt);
    final signedIn = _parseUtc(lastSignInAt);
    if (created == null || signedIn == null) return false;

    final delta = signedIn.difference(created).abs();
    return delta <= window;
  }

  /// 최종 판정.
  ///
  /// [persistedLoginSignature] 는 직전에 `login` 을 발송했을 때 저장해둔 서명.
  /// [signUpAlreadyLogged] 는 이 사용자에 대해 이미 `sign_up` 을 보냈는지 여부.
  static AuthAnalyticsDecision decide({
    required String userId,
    required String? provider,
    required String? createdAt,
    required String? lastSignInAt,
    required String? persistedLoginSignature,
    required bool signUpAlreadyLogged,
    Duration window = signUpWindow,
  }) {
    final signature = buildLoginSignature(
      userId: userId,
      lastSignInAt: lastSignInAt,
    );

    // 앱 재시작 후 세션 복원으로 signedIn 이 재발화한 경우 서명이 같다.
    final isDuplicate =
        persistedLoginSignature != null && persistedLoginSignature == signature;

    // sign_up 판정은 login 중복(세션 복원) 판정과 독립이다. isDuplicate 로
    // sign_up 까지 억제하면, 최초 signedIn 에서 sign_up outbox 저장만 실패하고
    // login 저장은 성공한 사용자의 sign_up 이 영원히 재시도되지 않는다 —
    // login 서명이 남아 이후 모든 signedIn 이 통째로 걸러지고, outbox 에는
    // signup 항목이 없기 때문이다. 세션 복원 재발화의 sign_up 중복 방지는
    // signUpAlreadyLogged 마커와 outbox 의 `signup:<userId>` id dedup
    // (pending/delivered 양쪽 검사)이 담당한다. 마커 저장이 실패해도 outbox
    // dedup 이 재추가를 막고, 이 경로가 마커 저장 자체를 다시 시도한다.
    final isNew =
        !signUpAlreadyLogged &&
        isFreshSignUp(
          createdAt: createdAt,
          lastSignInAt: lastSignInAt,
          window: window,
        );

    return AuthAnalyticsDecision(
      shouldLogLogin: !isDuplicate,
      shouldLogSignUp: isNew,
      method: resolveMethod(provider),
      loginSignature: signature,
    );
  }

  static DateTime? _parseUtc(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
