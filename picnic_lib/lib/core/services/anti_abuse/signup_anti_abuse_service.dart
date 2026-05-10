import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Anti-abuse signup precheck → verify (Plan 7) 와이어링.
///
/// 흐름:
///   1. [runPrecheck] — `anti-abuse-signup-precheck` (no auth) 호출.
///      - 200 + sig 발급 → [SignupHint] 반환.
///      - 200 + skipped (server salt/secret 미설정) → null (skip verify).
///      - 429 → [AntiAbuseException] throw — 호출자 dialog 표시.
///   2. (caller 가 signInWithIdToken 수행)
///   3. [runVerify] — `anti-abuse-signup-verify` (auth required) 호출, fire-and-forget.
///      - 200 → server 가 signup_pending → signup_verified 마킹.
///      - 422 → server 가 signup_unverified 마킹 (사용자에겐 invisible — 후속 entry-point 에서 차단).
///      - 401 / 503 / 네트워크 → 무시 (silent). 사용자는 signup_pending 으로 남고 Phase 3 grace 적용.
///
/// 본 서비스는 sign-up 흐름의 단일 진입점에서 호출 (`AuthService.signInWithProvider`).
class SignupAntiAbuseService {
  final SupabaseClient _client;

  SignupAntiAbuseService(this._client);

  /// Precheck 호출. 429 시 [AntiAbuseException] throw.
  /// 통과 시 [SignupHint] (sig 발급 case) 또는 null (skipped case).
  Future<SignupHint?> runPrecheck() async {
    try {
      final res = await _client.functions.invoke(
        'anti-abuse-signup-precheck',
        method: HttpMethod.post,
        body: {},
      );
      final data = res.data;
      if (data is! Map) {
        logger.w('signup-precheck: unexpected payload shape, treating as skip');
        return null;
      }
      final inner = data['data'];
      if (inner is! Map) {
        logger.w('signup-precheck: missing data.data, treating as skip');
        return null;
      }
      final skipped = inner['skipped'] == true;
      final ipHash = inner['ip_hash'];
      final sig = inner['sig'];
      final exp = inner['exp'];
      if (skipped || sig == null || exp == null) {
        logger.w('signup-precheck: skipped/missing sig — verify will be skipped');
        return null;
      }
      if (ipHash is! String || sig is! String || exp is! int) {
        logger.w('signup-precheck: malformed fields, treating as skip');
        return null;
      }
      return SignupHint(ipHash: ipHash, sig: sig, exp: exp);
    } catch (e, s) {
      final aa = mapToAntiAbuseException(e);
      if (aa is AntiAbuseException) {
        // signup channel 으로 표면화. caller (UI) 가 catch 후 RateLimitedDialog 표시.
        throw AntiAbuseException(
          'signup',
          rawCode: aa.rawCode,
          original: aa.original,
        );
      }
      // 기타 에러 — 가입 흐름은 깨뜨리지 않고 진행 (precheck 는 best-effort).
      logger.w('signup-precheck failed (silent fallback)',
          error: e, stackTrace: s);
      return null;
    }
  }

  /// Verify 호출 — fire-and-forget. 실패해도 가입 흐름에 영향 없음 (server 가 마크만 함).
  Future<void> runVerify(SignupHint hint) async {
    try {
      await _client.functions.invoke(
        'anti-abuse-signup-verify',
        method: HttpMethod.post,
        body: {
          'ip_hash': hint.ipHash,
          'sig': hint.sig,
          'exp': hint.exp,
        },
      );
    } catch (e, s) {
      // 422 (sig invalid 등) 는 server 가 signup_unverified 마킹 — 사용자에겐 invisible.
      // 401 / 503 / 네트워크 — server 마크 없음, 사용자는 signup_pending 으로 남음.
      // Phase 3 의 grace window 가 적용될 때까지는 모두 통과.
      logger.w('signup-verify failed (non-fatal)', error: e, stackTrace: s);
    }
  }
}

/// Precheck 결과 — verify 호출 시 그대로 echo back.
class SignupHint {
  final String ipHash;
  final String sig;
  final int exp;

  const SignupHint({
    required this.ipHash,
    required this.sig,
    required this.exp,
  });

  @override
  String toString() => 'SignupHint(ipHash: $ipHash, exp: $exp)';
}
