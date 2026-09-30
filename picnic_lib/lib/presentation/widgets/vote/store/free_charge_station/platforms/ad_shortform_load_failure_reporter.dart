import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_load_failure.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 자체숏폼 로드 실패를 Sentry 로 보낸다.
///
/// 에러 다이얼로그를 띄우는 자리에서 `unawaited` 로 불리므로 **절대 던지지
/// 않는다** — 연결 조회 실패, Sentry 전송 실패 전부 삼킨다.
///
/// 연결 조회에 타이머 기반 타임아웃을 두지 않는다. 플러그인이 응답하지 않는
/// 환경(헤드리스 위젯 테스트, 플러그인 미등록)에서는 리포트가 조용히 사라지는
/// 쪽을 택한다. 타임아웃 타이머를 두면 그 환경에서 페이지가 닫힌 뒤에도
/// 타이머가 살아남아 "pending timer" 로 테스트를 깨뜨리고, 실기기에서는
/// `checkConnectivity` 가 밀리초 안에 돌아오므로 얻는 것이 없다.
///
/// [checkConnectivity] 와 [send] 는 테스트 seam 이다.
Future<void> reportAdShortformLoadFailure(
  AdShortformLoadFailure failure, {
  Future<List<ConnectivityResult>> Function()? checkConnectivity,
  Future<void> Function(AdShortformLoadFailure failure)? send,
}) async {
  List<ConnectivityResult>? connectivity;
  try {
    connectivity = await (checkConnectivity ?? Connectivity().checkConnectivity)
        .call();
  } catch (_) {
    connectivity = null;
  }
  try {
    await (send ?? _sendToSentry)(failure.withConnectivity(connectivity));
  } catch (_) {
    // 통계용 전송이 광고 흐름을 깨서는 안 된다.
  }
}

Future<void> _sendToSentry(AdShortformLoadFailure failure) async {
  await Sentry.captureException(
    failure.error,
    stackTrace: failure.stackTrace,
    withScope: (scope) {
      failure.tags.forEach(scope.setTag);
      scope.setContexts('ad_shortform_load', failure.extras);
      scope.fingerprint = ['ad-shortform-load-failure', failure.stage.name];
    },
  );
}
