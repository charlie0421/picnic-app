import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

typedef LoadedCb = void Function(String ad);
typedef FailedCb = void Function(Object error);
typedef ShowFailedCb = void Function(Object error);

void main() {
  // 각 테스트가 SDK 콜백을 손으로 발화할 수 있도록 캡처해 두는 하네스.
  late LoadedCb sdkOnLoaded;
  late FailedCb sdkOnFailedToLoad;
  void Function()? sdkOnShowed;
  void Function()? sdkOnDismissed;
  ShowFailedCb? sdkOnFailedToShow;
  late List<String> disposed;
  late List<String> events;

  AdmobShowFlow<String> buildFlow({
    void Function(void Function(String ad) onLoaded,
            void Function(Object error) onFailedToLoad)?
        startLoadOverride,
    void Function(
      String ad, {
      required void Function() onShowed,
      required void Function() onDismissed,
      required void Function(Object error) onFailedToShow,
    })?
        attachCallbacksAndShowOverride,
  }) {
    disposed = [];
    events = [];
    sdkOnShowed = null;
    sdkOnDismissed = null;
    sdkOnFailedToShow = null;
    return AdmobShowFlow<String>(
      startLoad: startLoadOverride ??
          (onLoaded, onFailed) {
            sdkOnLoaded = onLoaded;
            sdkOnFailedToLoad = onFailed;
          },
      attachCallbacksAndShow: attachCallbacksAndShowOverride ??
          (ad,
              {required onShowed,
              required onDismissed,
              required onFailedToShow}) {
            sdkOnShowed = onShowed;
            sdkOnDismissed = onDismissed;
            sdkOnFailedToShow = onFailedToShow;
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
  // 리소스 정리는 수행한다. showTimeout 이 이미 이 attempt 의 UI terminal
  // 이었으므로(onShowed 없이 실패 다이얼로그가 이미 떴다), 늦은 dismissed 는
  // "정상적인 후속 이벤트"가 아니다.
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

  // 정상 경로: load → showed → dismissed. showed 가 이 attempt 의 UI
  // terminal 이고(스피너 해제), dismissed 는 그 뒤에 오는 정상적인 후속
  // 이벤트라 여전히 전달된다. 워치독은 아무 것도 발화하지 않는다.
  test('정상 시청 경로는 showStarted 뒤 dismissed 로 끝난다', () {
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

  // 정상 경로(표시 실패): 로드는 됐지만 onShowed 없이 바로 onFailedToShow —
  // 단일 terminal 로 끝나고 워치독은 발화하지 않는다.
  test('onFailedToShow 는 showFailed 1회로 끝나고 워치독은 발화하지 않는다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      sdkOnFailedToShow!(StateError('show rejected'));
      expect(events, ['showFailed']);
      expect(disposed, ['ad-1']);
      async.elapse(const Duration(minutes: 10));
      expect(events, ['showFailed']); // showTimeout 이 뒤이어 발화하지 않는다
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

  // MAJOR-1: delegate 가 로드 배선 중 동기 throw 하면 로드 실패 단일 경로로
  // 합류해야 한다 — 그러지 않으면 15초 뒤 로드 워치독이 또 발화해 다이얼로그가
  // 두 번 뜬다.
  test('startLoad 동기 throw 는 loadFailed 1회로 끝나고 로드 워치독은 발화하지 않는다',
      () {
    fakeAsync((async) {
      final flow = buildFlow(
        startLoadOverride: (onLoaded, onFailedToLoad) {
          throw StateError('설정 오류로 동기 throw');
        },
      );
      run(flow);
      expect(events, ['loadFailed']);
      async.elapse(const Duration(seconds: 20)); // loadTimeout(15s) 를 넘긴다
      expect(events, ['loadFailed']); // loadTimeout 이 추가로 발화하지 않는다
    });
  });

  // MAJOR-1 변형: delegate 가 표시 배선 중 동기 throw 하면 표시 실패 단일
  // 경로로 합류해야 한다 — 그러지 않으면 10초 뒤 표시 워치독이 또 발화해
  // 다이얼로그가 두 번 뜬다.
  test('attachCallbacksAndShow 동기 throw 는 showFailed 1회로 끝나고 표시 워치독은 발화하지 않는다',
      () {
    fakeAsync((async) {
      final flow = buildFlow(
        attachCallbacksAndShowOverride: (ad,
            {required onShowed,
            required onDismissed,
            required onFailedToShow}) {
          throw StateError('SSV 설정 중 동기 throw');
        },
      );
      run(flow);
      sdkOnLoaded('ad-1');
      expect(events, ['showFailed']);
      expect(disposed, ['ad-1']); // 표시되지 못한 ad 도 정리된다
      async.elapse(const Duration(seconds: 20)); // showTimeout(10s) 를 넘긴다
      expect(events, ['showFailed']); // showTimeout 이 추가로 발화하지 않는다
    });
  });

  // BLOCKER-1: 늦게 도착한 이전 attempt(A) 의 dismissed 가 이미 시작된 다음
  // attempt(B) 의 광고를 건드리면 안 된다. A → 로드 → showed → dismissed 지연
  // → B 가 새 attempt 를 시작해 로드까지 마친 뒤에야 A 의 늦은 dismissed 가
  // 도착한다.
  test('새 attempt(B) 로드 후 이전 attempt(A) 의 늦은 dismissed 는 B 를 건드리지 않는다', () {
    fakeAsync((async) {
      final flow = buildFlow();

      run(flow); // attempt A
      sdkOnLoaded('A');
      sdkOnShowed!();
      expect(events, ['showStarted']);
      final staleDismissed = sdkOnDismissed!; // A 의 dismissed 콜백을 캡처해 둔다

      run(flow); // attempt B — A 는 아직 dismissed 되지 않은 채로 새 attempt 시작
      expect(disposed, ['A']); // run() 의 _disposePending() 이 A 를 정리
      sdkOnLoaded('B');
      expect(sdkOnShowed, isNotNull);

      staleDismissed(); // A 의 늦은 dismissed 가 이제야 도착
      expect(disposed, ['A']); // B 는 재정리(중복 dispose)되지 않는다
      expect(events, ['showStarted']); // A 의 dismissed 가 B 의 이벤트에 섞이지 않는다

      // B 는 여전히 정상 동작한다.
      sdkOnShowed!();
      sdkOnDismissed!();
      expect(events, ['showStarted', 'showStarted', 'dismissed']);
      expect(disposed, ['A', 'B']);
    });
  });

  // BLOCKER-1 변형: onFailedToShow 도 동일한 stale 가드가 적용된다. A 는
  // 표시 결과를 듣기도 전에 B 가 새 attempt 를 시작한다.
  test('새 attempt(B) 로드 후 이전 attempt(A) 의 늦은 onFailedToShow 는 B 를 건드리지 않는다',
      () {
    fakeAsync((async) {
      final flow = buildFlow();

      run(flow); // attempt A
      sdkOnLoaded('A');
      final staleFailedToShow = sdkOnFailedToShow!;

      run(flow); // attempt B — A 는 표시 결과를 듣기 전에 새 attempt 시작
      expect(disposed, ['A']);
      sdkOnLoaded('B');

      staleFailedToShow(StateError('A 의 늦은 표시 실패'));
      expect(disposed, ['A']); // B 는 재정리되지 않는다
      expect(events, isEmpty); // A 의 실패가 B 로 새어나오지 않는다

      sdkOnShowed!(); // B 는 여전히 정상 동작한다
      expect(events, ['showStarted']);
    });
  });

  // 재작성 (BLOCKER-2): showed 자체가 이 attempt 의 UI terminal 이다(스피너는
  // 이미 풀렸다). 예전 버전은 "dismissed/failedToShow 둘 다 유실되면 이
  // attempt 는 terminal 없이 끝난다"를 의도된 동작으로 고정했는데, 이는
  // '모든 attempt 는 정확히 하나의 terminal 로 끝난다'는 계획서 §B 의
  // 불변식과 모순됐다. 지금은 onShowed 가 UI terminal 을 명시적으로
  // 소비한다 — 아래에서 중복 onShowed 가 무시되는 것으로 간접 검증한다.
  // dismissed/failedToShow 가 끝내 오지 않아 남는 `_pendingAd` 는 **광고
  // 리소스 lifecycle** 문제이지 UI terminal 누락이 아니며, 다음 attempt
  // 시작 또는 명시적 dispose() 중 먼저 오는 경로에서 정리된다.
  test(
      'showed 후 dismissed/failedToShow 유실 — showed 가 이미 UI terminal 이고 '
      '광고 정리는 다음 attempt 가 맡는다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 10));
      expect(events, ['showStarted']);
      expect(disposed, isEmpty); // 아직 아무도 정리하지 않았다 — 광고가 떠 있을 수 있다

      // onShowed 가 이미 이 attempt 의 UI terminal 을 소비했음을 간접
      // 검증한다: SDK 가 onShowed 를 한 번 더 불러도(드문 이상 상황) 두
      // 번째 스피너-해제 이벤트를 만들지 않는다.
      sdkOnShowed!();
      expect(events, ['showStarted']);

      run(flow); // 다음 attempt 시작이 leftover 광고를 정리한다
      expect(disposed, ['ad-1']);
    });
  });

  // 위 시나리오의 다른 경로: 다음 attempt 없이 flow 자체가 dispose 될 때도
  // leftover 광고가 정리된다 — AdmobPlatform.dispose() → AdmobShowFlow.dispose()
  // 로 이어지는 실제 위젯 teardown 경로(BLOCKER-3)가 여기로 연결된다.
  test('showed 후 dismissed/failedToShow 유실 — dispose() 도 leftover 광고를 정리한다',
      () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 10));
      expect(disposed, isEmpty);

      flow.dispose();
      expect(disposed, ['ad-1']);
      async.elapse(const Duration(minutes: 10));
      expect(events, ['showStarted']); // dispose 이후 아무 것도 추가 발화하지 않는다
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
