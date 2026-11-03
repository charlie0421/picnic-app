import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure_reporter.dart';

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
}
