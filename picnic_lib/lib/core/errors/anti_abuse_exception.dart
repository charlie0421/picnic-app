/// Anti-abuse 채널: 'ad_watch' | 'signup' | 'attendance' | 'artist_request' (스펙 §9 기준).
/// 알 수 없는 새 채널이 들어올 때를 위해 String 으로 받음 — 다이얼로그 측에서 default 분기 처리.
class AntiAbuseException implements Exception {
  final String channel;
  final String? rawCode;
  final dynamic original;

  AntiAbuseException(this.channel, {this.rawCode, this.original});

  @override
  String toString() => 'AntiAbuseException(channel: $channel, code: $rawCode)';
}

/// SECURITY DEFINER RPC 의 anti-abuse 권한 거부(ERRCODE 42501).
/// 일반 사용자에게는 '권한이 없습니다' 정도로만 노출.
class AntiAbusePermissionException implements Exception {
  final String? requiredKey;
  final dynamic original;

  AntiAbusePermissionException({this.requiredKey, this.original});

  @override
  String toString() =>
      'AntiAbusePermissionException(requiredKey: $requiredKey)';
}
