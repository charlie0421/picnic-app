import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';

/// 자체숏폼 로드 실패 리포트의 분류 규칙.
///
/// 이 규칙이 깨지면 Sentry 태그로 "타임아웃 vs 플랫폼 오류 vs 빈 URL" 을
/// 가를 수 없어, QnA 395 처럼 원인 후보를 좁히지 못한 채 CS 가 반복된다.
void main() {
  AdShortformLoadFailure classify(
    Object error, {
    AdShortformLoadStage stage = AdShortformLoadStage.initialize,
    Duration elapsed = const Duration(seconds: 15),
    String? videoUrl,
    List<ConnectivityResult>? connectivity,
  }) => AdShortformLoadFailure.classify(
    error: error,
    stage: stage,
    elapsed: elapsed,
    videoUrl: videoUrl,
    connectivity: connectivity,
  );

  group('reason', () {
    test('TimeoutException is reported as timeout', () {
      final f = classify(TimeoutException('initialize'));
      expect(f.reason, 'timeout');
    });

    test('PlatformException carries its code', () {
      final f = classify(PlatformException(code: 'VideoError', message: 'x'));
      expect(f.reason, 'platform:VideoError');
    });

    test('StateError (empty url / missing owner) is reported as state', () {
      final f = classify(
        StateError('ad-shortform: empty video_url'),
        stage: AdShortformLoadStage.emptyUrl,
      );
      expect(f.reason, 'state');
    });

    test('anything else is reported as other', () {
      final f = classify(Exception('boom'));
      expect(f.reason, 'other');
    });
  });

  group('videoUrl sanitizing', () {
    test('query and fragment are dropped, scheme/host/path kept', () {
      final f = classify(
        TimeoutException('x'),
        videoUrl:
            'https://cdn.example.com/videos/output/abc/master.m3u8?token=secret#t=1',
      );
      expect(
        f.videoUrl,
        'https://cdn.example.com/videos/output/abc/master.m3u8',
      );
    });

    test('empty url becomes null', () {
      expect(classify(TimeoutException('x'), videoUrl: '').videoUrl, isNull);
    });
  });

  group('network', () {
    test('null connectivity is unknown', () {
      expect(classify(TimeoutException('x')).network, 'unknown');
    });

    test('wifi wins over vpn', () {
      final f = classify(
        TimeoutException('x'),
        connectivity: [ConnectivityResult.vpn, ConnectivityResult.wifi],
      );
      expect(f.network, 'wifi');
    });

    test('mobile', () {
      final f = classify(
        TimeoutException('x'),
        connectivity: [ConnectivityResult.mobile],
      );
      expect(f.network, 'mobile');
    });

    test('none and empty list are none', () {
      expect(
        classify(
          TimeoutException('x'),
          connectivity: [ConnectivityResult.none],
        ).network,
        'none',
      );
      expect(classify(TimeoutException('x'), connectivity: []).network, 'none');
    });
  });

  group('withConnectivity', () {
    test('replaces only the network, keeping the rest', () {
      final base = classify(
        TimeoutException('x'),
        stage: AdShortformLoadStage.play,
        videoUrl: 'https://cdn.example.com/a/master.m3u8',
      );
      final f = base.withConnectivity([ConnectivityResult.wifi]);
      expect(f.network, 'wifi');
      expect(f.stage, AdShortformLoadStage.play);
      expect(f.reason, 'timeout');
      expect(f.videoUrl, base.videoUrl);
      expect(base.network, 'unknown', reason: 'original is untouched');
    });
  });

  group('sentry exception', () {
    // 리뷰 지적: ExoPlayer 의 PlatformException.message 에는 서명된 원본 URL 이
    // 그대로 들어온다. 원본 예외를 Sentry 에 보내면 정제한 video_url 과 별개로
    // 토큰이 샌다. 그리고 loadAd 의 FunctionException 은 앱의 beforeSend 필터가
    // 버리므로 원본 타입으로 보내면 발급 실패가 기록되지 않는다.
    test('does not carry the raw message or URL, only stage and reason', () {
      final f = classify(
        PlatformException(
          code: 'VideoError',
          message:
              'Source error https://cdn.example.com/a/master.m3u8?token=secret',
        ),
        videoUrl: 'https://cdn.example.com/a/master.m3u8?token=secret',
      );
      final e = f.toSentryException();
      expect(e, isA<AdShortformLoadException>());
      expect(e.toString(), isNot(contains('token=secret')));
      expect(e.toString(), isNot(contains('https://')));
      expect(e.toString(), contains('initialize'));
      expect(e.toString(), contains('platform:VideoError'));
    });

    test('a platform code carrying a signed URL is not passed through', () {
      // 재검증 지적: message 만 정제하면 code 로 들어온 URL 이 reason 을 거쳐
      // 예외 문자열과 ad_reason 태그로 샌다.
      final f = classify(
        PlatformException(
          code: 'https://cdn.example.com/a/master.m3u8?token=secret',
          message: 'x',
        ),
      );
      expect(f.reason, 'platform:invalid');
      expect(f.toSentryException().toString(), isNot(contains('token')));
      expect(f.tags['ad_reason'], 'platform:invalid');
    });

    test('a well-formed platform code is kept', () {
      final f = classify(PlatformException(code: 'VideoError-1.2_x'));
      expect(f.reason, 'platform:VideoError-1.2_x');
    });

    test('is never the original exception instance', () {
      final original = Exception('FunctionException 503');
      expect(classify(original).toSentryException(), isNot(same(original)));
    });
  });

  group('sentry payload', () {
    test(
      'tags carry stage, reason and network; extras carry elapsed and url',
      () {
        final f = classify(
          TimeoutException('x'),
          stage: AdShortformLoadStage.watchdog,
          elapsed: const Duration(milliseconds: 35010),
          videoUrl: 'https://cdn.example.com/a/master.m3u8',
          connectivity: [ConnectivityResult.mobile],
        );
        expect(f.tags, {
          'ad_stage': 'watchdog',
          'ad_reason': 'timeout',
          'network': 'mobile',
        });
        expect(f.extras['elapsed_ms'], 35010);
        expect(f.extras['video_url'], 'https://cdn.example.com/a/master.m3u8');
      },
    );
  });
}
