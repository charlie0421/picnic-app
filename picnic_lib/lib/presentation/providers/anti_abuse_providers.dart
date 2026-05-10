import 'package:picnic_lib/core/services/anti_abuse/ip_hash_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/anti_abuse_providers.g.dart';

/// IpHashService singleton — anti-abuse hint 캐시.
///
/// 앱 부팅 직후 [IpHashService.fetchAndCache] 1회 prefetch (App._initializeAppBasics 에서
/// fire-and-forget) 후 보호 대상 호출에서 [IpHashService.current] 으로 조회.
@Riverpod(keepAlive: true)
IpHashService ipHashService(Ref ref) {
  return IpHashService(supabase);
}
