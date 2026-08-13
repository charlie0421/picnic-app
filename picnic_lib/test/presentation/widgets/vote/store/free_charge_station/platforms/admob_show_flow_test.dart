import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

typedef LoadedCb = void Function(String ad);
typedef FailedCb = void Function(Object error);

void main() {
  // 각 테스트가 SDK 콜백을 손으로 발화할 수 있도록 캡처해 두는 하네스.
  late LoadedCb sdkOnLoaded;
  late FailedCb sdkOnFailedToLoad;
  void Function()? sdkOnShowed;
  void Function()? sdkOnDismissed;
  late List<String> disposed;
  late List<String> events;

  AdmobShowFlow<String> buildFlow() {
    disposed = [];
    events = [];
    sdkOnShowed = null;
    sdkOnDismissed = null;
    return AdmobShowFlow<String>(
      startLoad: (onLoaded, onFailed) {
        sdkOnLoaded = onLoaded;
        sdkOnFailedToLoad = onFailed;
      },
      attachCallbacksAndShow: (ad, {required onShowed, required onDismissed, required onFailedToShow}) {
        sdkOnShowed = onShowed;
        sdkOnDismissed = onDismissed;
      },
      disposeAd: disposed.add,
    );
  }

  void run(AdmobShowFlow<String> flow) {
    flow.run(
      onLoadTimeout: () => events.add('loadTimeout'),
      onLoadFailed: (e) => events.add('loadFailed'),
      onShowStarted: () => events.add('showStarted'),
      onShowTimeout: () => events.add('showTimeout'),
      onShowFailed: (e) => events.add('showFailed'),
      onDismissed: () => events.add('dismissed'),
    );
  }

  // 시나리오 2: onAdLoaded 도 onAdFailedToLoad 도 안 온다 → 15초 뒤
  // loadTimeout 이 정확히 1회. (현재 코드에는 이 방어가 없어 영구 로딩 — 조사 §1.3)
  test('load 콜백이 전혀 없으면 loadTimeout 으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      async.elapse(const Duration(seconds: 14));
      expect(events, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(events, ['loadTimeout']);
      async.elapse(const Duration(minutes: 10));
      expect(events, ['loadTimeout']); // 더 이상 아무 일도 없다
    });
  });

  // 시나리오 1: 로드 성공 후 show 단계 콜백 전부 유실 → 10초 뒤 showTimeout.
  test('show 콜백이 전혀 없으면 showTimeout 으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 10));
      expect(events, ['showTimeout']);
      // ⚠️ 광고가 떠 있을 수 있으므로 showTimeout 시점에 dispose 하지 않는다.
      expect(disposed, isEmpty);
    });
  });

  // 시나리오 8: showTimeout 뒤 늦게 도착한 dismissed — UI 이벤트는 무시하되
  // 리소스 정리는 수행한다.
  test('타임아웃 후 늦은 dismissed 는 dispose 만 수행한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 10));
      expect(events, ['showTimeout']);
      sdkOnDismissed!();
      expect(events, ['showTimeout']); // dismissed 이벤트는 추가되지 않는다
      expect(disposed, ['ad-1']); // 하지만 광고는 정리된다
    });
  });

  // 시나리오 8 변형: loadTimeout 뒤 늦게 도착한 onAdLoaded → 광고 즉시 폐기,
  // show 로 진행하지 않는다.
  test('타임아웃 후 늦은 onAdLoaded 는 광고를 폐기한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      async.elapse(const Duration(seconds: 15));
      expect(events, ['loadTimeout']);
      sdkOnLoaded('late-ad');
      expect(disposed, ['late-ad']);
      expect(sdkOnShowed, isNull); // attachCallbacksAndShow 미호출
    });
  });

  // 정상 경로: load → showed → dismissed. terminal 은 dismissed 하나뿐이고
  // 워치독은 아무 것도 발화하지 않는다.
  test('정상 시청 경로는 dismissed 한 번으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 3));
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 5)); // 긴 시청 — showed 후엔 시한 없음
      sdkOnDismissed!();
      expect(events, ['showStarted', 'dismissed']);
      expect(disposed, ['ad-1']);
    });
  });

  // 시나리오 3/4 (새 구조 형태): 실패 콜백이 오면 terminal 은 loadFailed
  // 정확히 1회 — 워치독과 중복 발화하지 않는다.
  test('onAdFailedToLoad 는 loadFailed 1회로 끝나고 워치독은 발화하지 않는다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnFailedToLoad(StateError('no fill'));
      async.elapse(const Duration(minutes: 10));
      expect(events, ['loadFailed']);
    });
  });

  // 시나리오 5: showed 는 왔지만 dismissed/failedToShow 가 안 온다 → 스피너는
  // 풀렸고(showStarted), 워치독도 해제됐으므로 추가 이벤트는 없다. pendingAd 는
  // 다음 run() 또는 dispose() 에서 정리된다 — 이 잔류를 명시적으로 고정한다.
  test('showed 후 종결 콜백 유실 시 광고는 다음 attempt 시작 때 정리된다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 10));
      expect(events, ['showStarted']);
      expect(disposed, isEmpty);
      run(flow); // 다음 시도 시작
      expect(disposed, ['ad-1']);
    });
  });

  // 재진입: 시도 중 새 run() 이 시작되면 이전 시도의 늦은 성공은 폐기된다.
  test('새 attempt 시작 후 이전 attempt 의 onAdLoaded 는 폐기된다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      final firstLoaded = sdkOnLoaded;
      run(flow); // 두 번째 시도 — 세대 증가
      firstLoaded('stale-ad');
      expect(disposed, ['stale-ad']);
      expect(events, isEmpty);
    });
  });

  // dispose(): 플랫폼 dispose 시 워치독 해제 + 보류 광고 정리.
  test('dispose 는 워치독을 멈추고 보류 광고를 정리한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      flow.dispose();
      expect(disposed, ['ad-1']);
      async.elapse(const Duration(minutes: 10));
      expect(events, isEmpty); // showTimeout 미발화
    });
  });
}
