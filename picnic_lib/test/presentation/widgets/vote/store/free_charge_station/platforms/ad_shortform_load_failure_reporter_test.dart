import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure_reporter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 기본 리포터: 연결 종류를 붙여 전송하되, 어떤 실패도 호출자에게 던지지 않는다.
/// 이 리포터는 에러 다이얼로그 표시 경로에서 `unawaited` 로 불리므로,
/// 여기서 던지면 다이얼로그 대신 미처리 예외가 된다.
void main() {
  AdShortformLoadFailure failure() => AdShortformLoadFailure.classify(
    error: TimeoutException('initialize'),
    stage: AdShortformLoadStage.initialize,
    elapsed: const Duration(seconds: 30),
    videoUrl: 'https://cdn.example.com/a/master.m3u8',
  );

  test('attaches the connectivity result before sending', () async {
    AdShortformLoadFailure? sent;
    await reportAdShortformLoadFailure(
      failure(),
      checkConnectivity: () async => [ConnectivityResult.mobile],
      send: (f) async => sent = f,
    );
    expect(sent?.network, 'mobile');
    expect(sent?.reason, 'timeout');
  });

  test('connectivity lookup failure sends with network unknown', () async {
    AdShortformLoadFailure? sent;
    await reportAdShortformLoadFailure(
      failure(),
      checkConnectivity: () async => throw StateError('no plugin'),
      send: (f) async => sent = f,
    );
    expect(sent?.network, 'unknown');
  });

  test(
    'a connectivity lookup that never answers drops the report without a timer',
    () async {
      // 헤드리스 테스트·플러그인 미등록 환경. 타이머를 남기면 페이지가 닫힌
      // 뒤 "pending timer" 로 위젯 테스트가 깨진다(기존 렌더 테스트 5건).
      AdShortformLoadFailure? sent;
      unawaited(
        reportAdShortformLoadFailure(
          failure(),
          checkConnectivity: () => Completer<List<ConnectivityResult>>().future,
          send: (f) async => sent = f,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(sent, isNull);
    },
  );

  test('send failure is swallowed', () async {
    await expectLater(
      reportAdShortformLoadFailure(
        failure(),
        checkConnectivity: () async => [ConnectivityResult.wifi],
        send: (_) async => throw Exception('sentry down'),
      ),
      completes,
    );
  });

  for (final scenario in <(String, Object)>[
    ('function:429', const FunctionException(status: 429)),
    ('function:503', const FunctionException(status: 503)),
    ('network', const SocketException('synthetic connection failure')),
  ]) {
    test('${scenario.$1} keeps the loadAd fingerprint even offline', () async {
      final events = <SentryEvent>[];
      await Sentry.init((options) {
        options
          ..dsn = 'https://public@o0.ingest.sentry.io/0'
          ..debug = false
          ..enableDartSymbolication = false
          ..enableDeduplication = false
          ..beforeSend = (event, hint) {
            events.add(event);
            return null;
          };
      });
      addTearDown(Sentry.close);

      await reportAdShortformLoadFailure(
        AdShortformLoadFailure.classify(
          error: scenario.$2,
          stage: AdShortformLoadStage.loadAd,
          elapsed: const Duration(seconds: 1),
        ),
        checkConnectivity: () async => [ConnectivityResult.none],
      );

      expect(events, hasLength(1));
      expect(events.single.fingerprint, [
        'ad-shortform-load-failure',
        'loadAd',
      ]);
      expect(events.single.tags?['ad_reason'], scenario.$1);
      expect(events.single.tags?['network'], 'none');
    });
  }
}
