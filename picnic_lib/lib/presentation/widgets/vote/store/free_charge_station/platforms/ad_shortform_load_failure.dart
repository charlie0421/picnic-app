import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

/// 자체숏폼 광고가 "광고 로드에 실패했습니다" 로 끝난 지점.
enum AdShortformLoadStage {
  /// `loadAd`(토큰 발급) 자체가 던졌다.
  loadAd,

  /// 발급은 됐지만 video_url 이 비어 있었다(anti-abuse 차단은 제외).
  emptyUrl,

  /// `VideoPlayerController.initialize()` 가 실패하거나 타임아웃됐다.
  initialize,

  /// `play()` 가 실패했다.
  play,

  /// 컨트롤러가 워치독 시간 안에 준비되지 않았다.
  watchdog,
}

/// 로드 실패 한 건을 Sentry 태그·extra 로 옮길 수 있게 분류한 값.
///
/// 이 리포트가 없을 때는 사용자가 "재생이 안 된다"고 문의해도 서버에는
/// 발급 행(`ad_impressions`)만 남아, 타임아웃인지 디코더 오류인지 빈 URL 인지
/// 가릴 방법이 없었다(QnA 395). 분류는 순수 함수라 위젯 없이 테스트한다.
class AdShortformLoadFailure {
  const AdShortformLoadFailure({
    required this.stage,
    required this.reason,
    required this.elapsed,
    required this.network,
    required this.error,
    this.videoUrl,
    this.stackTrace,
  });

  factory AdShortformLoadFailure.classify({
    required Object error,
    required AdShortformLoadStage stage,
    required Duration elapsed,
    String? videoUrl,
    List<ConnectivityResult>? connectivity,
    StackTrace? stackTrace,
  }) {
    return AdShortformLoadFailure(
      stage: stage,
      reason: describeReason(error),
      elapsed: elapsed,
      network: describeNetwork(connectivity),
      error: error,
      videoUrl: sanitizeVideoUrl(videoUrl),
      stackTrace: stackTrace,
    );
  }

  final AdShortformLoadStage stage;

  /// `timeout` · `platform:<code>` · `state` · `other`.
  final String reason;
  final Duration elapsed;

  /// `wifi` · `mobile` · `ethernet` · `vpn` · `none` · `unknown`.
  final String network;
  final Object error;
  final StackTrace? stackTrace;

  /// 쿼리·프래그먼트를 뗀 URL. 서명 토큰이 붙어 있어도 Sentry 로 새지 않는다.
  final String? videoUrl;

  /// 연결 종류만 바꾼 사본. 페이지는 연결 조회를 기다릴 수 없으므로
  /// `unknown` 으로 만들고, 리포터가 조회 뒤 이걸로 채운다.
  AdShortformLoadFailure withConnectivity(
    List<ConnectivityResult>? connectivity,
  ) => AdShortformLoadFailure(
    stage: stage,
    reason: reason,
    elapsed: elapsed,
    network: describeNetwork(connectivity),
    error: error,
    videoUrl: videoUrl,
    stackTrace: stackTrace,
  );

  /// Sentry 로 보낼 전용 예외. 원본 예외는 보내지 않는다.
  ///
  /// ExoPlayer 의 `PlatformException.message` 에는 서명된 원본 URL 이 들어
  /// 있어 그대로 보내면 정제한 `video_url` 과 별개로 토큰이 샌다. 또 발급
  /// 실패의 `FunctionException` 은 앱의 Sentry beforeSend 필터가 버리므로
  /// 원본 타입으로는 기록되지 않는다. 그래서 단계·사유·원본 타입 이름만 담은
  /// 예외를 새로 만든다. 원본은 [error] 로 후크 안에서만 쓸 수 있다.
  AdShortformLoadException toSentryException() => AdShortformLoadException(
    stage: stage,
    reason: reason,
    originalType: error.runtimeType.toString(),
  );

  Map<String, String> get tags => {
    'ad_stage': stage.name,
    'ad_reason': reason,
    'network': network,
  };

  Map<String, Object?> get extras => {
    'elapsed_ms': elapsed.inMilliseconds,
    'video_url': videoUrl,
  };

  /// 플랫폼 오류 코드로 허용하는 형태. ExoPlayer/AVFoundation 코드는
  /// `VideoError` 같은 짧은 식별자다. 그 밖의 값(URL 등)은 태그로 새지 않게
  /// `invalid` 로 접는다.
  static final RegExp _platformCodePattern = RegExp(r'^[A-Za-z0-9_.\-]{1,64}$');

  static String describeReason(Object error) {
    if (error is TimeoutException) return 'timeout';
    if (error is PlatformException) {
      final code = _platformCodePattern.hasMatch(error.code)
          ? error.code
          : 'invalid';
      return 'platform:$code';
    }
    if (error is StateError) return 'state';
    return 'other';
  }

  static String? sanitizeVideoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // `Uri.replace(query: null)` 은 "그대로 둔다" 라 쿼리를 못 뗀다.
    final stripped = url.split('?').first.split('#').first;
    return stripped.isEmpty ? null : stripped;
  }

  /// 연결 목록 가운데 사용자가 체감하는 망 하나로 줄인다. vpn 은 그 아래 실제
  /// 망(wifi/mobile)이 같이 오므로 실제 망을 우선한다.
  static String describeNetwork(List<ConnectivityResult>? connectivity) {
    if (connectivity == null) return 'unknown';
    const priority = [
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
      ConnectivityResult.mobile,
      ConnectivityResult.vpn,
    ];
    for (final candidate in priority) {
      if (connectivity.contains(candidate)) return candidate.name;
    }
    return 'none';
  }
}

/// [AdShortformLoadFailure.toSentryException] 이 만드는 예외. 메시지에 URL·
/// 원본 예외 본문이 없어 그대로 Sentry 이슈 제목이 돼도 안전하다.
class AdShortformLoadException implements Exception {
  const AdShortformLoadException({
    required this.stage,
    required this.reason,
    required this.originalType,
  });

  final AdShortformLoadStage stage;
  final String reason;
  final String originalType;

  @override
  String toString() =>
      'AdShortformLoadException(stage=${stage.name}, reason=$reason, '
      'original=$originalType)';
}
