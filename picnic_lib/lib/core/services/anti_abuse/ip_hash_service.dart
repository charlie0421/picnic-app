import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Anti-abuse IP hash 발급/캐시 서비스.
///
/// 앱 시작 시 [fetchAndCache] 1회 → 메모리 캐시. 보호 대상 호출(광고/출석/아티스트요청)에서
/// [current] 로 hint 송신. 서버 [track-country] edge fn 이 server-side hashing 후 64자 hex 반환.
///
/// 실패는 silent fallback (null). 클라이언트 흐름을 절대 차단하지 않음 — anti-abuse 가드는
/// 어디까지나 best-effort hint 이고, 실제 차단 권한은 서버에 있음.
class IpHashService {
  final SupabaseClient _client;
  String? _cached;

  IpHashService(this._client);

  /// 현재 캐시값. fetch 전이거나 실패한 경우 null.
  String? get current => _cached;

  Future<String?> fetchAndCache({bool force = false}) async {
    if (_cached != null && !force) return _cached;
    try {
      final res = await _client.functions.invoke('track-country', body: {});
      final data = res.data;
      if (data is Map) {
        final hash = data['ip_hash'];
        if (hash is String && hash.isNotEmpty && hash != 'unknown') {
          _cached = hash;
          return _cached;
        }
      }
      return null;
    } catch (e, s) {
      logger.w('ip_hash fetch failed (silent fallback)',
          error: e, stackTrace: s);
      return null;
    }
  }

  void clearCache() => _cached = null;
}
