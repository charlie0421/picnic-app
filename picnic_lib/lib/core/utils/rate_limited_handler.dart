import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 보호 대상 호출(광고/출석/가입/아티스트요청)의 catch 블록에서 사용.
///
/// 매칭되면 [AntiAbuseException] 또는 [AntiAbusePermissionException], 아니면 null.
/// 반환값이 null 이면 anti-abuse 와 무관한 에러이므로 호출자가 그대로 rethrow 하면 됨.
///
/// 매칭 패턴:
///   - DB trigger `RAISE EXCEPTION 'RATE_LIMITED:<channel>' USING ERRCODE='P0001'`
///   - SECURITY DEFINER RPC 의 권한 가드(ERRCODE 42501)
///   - Edge function 의 429 + body `{code: RATE_LIMITED, reason: '<channel>_ip_quota'}`
Object? mapToAntiAbuseException(dynamic error) {
  if (error == null) return null;

  if (error is PostgrestException) {
    if (error.code == 'P0001' && error.message.startsWith('RATE_LIMITED:')) {
      final channel = error.message.substring('RATE_LIMITED:'.length);
      return AntiAbuseException(
        channel,
        rawCode: error.code,
        original: error,
      );
    }
    if (error.code == '42501') {
      String? requiredKey;
      try {
        final m = RegExp(r'permission denied:\s*([\w.]+)')
            .firstMatch(error.message);
        requiredKey = m?.group(1);
      } catch (_) {
        // best-effort
      }
      return AntiAbusePermissionException(
        requiredKey: requiredKey,
        original: error,
      );
    }
  }

  if (error is FunctionException && error.status == 429) {
    final details = error.details;
    if (details is Map && details['code'] == 'RATE_LIMITED') {
      final reason = (details['reason'] as String?) ?? '';
      final channel = reason.replaceAll('_ip_quota', '');
      return AntiAbuseException(
        channel,
        rawCode: 'RATE_LIMITED',
        original: error,
      );
    }
  }

  return null;
}
