import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';

/// [GlobalPurchaseListener]의 `_headlessWork` 직렬화 체인은 화면 없이 도착한
/// 구매 이벤트마다 하나씩 길어진다 - 정산이 도착 속도를 못 따라가면(예:
/// 검증 서버 지연) 큐 깊이가 계속 자란다. 이벤트를 버리는 건 돈이 걸린
/// "purchased" 이벤트를 잃을 수 있어 안전하지 않으므로, 여기서는 자르지
/// 않고 대신 깊이를 관측 가능하게(경고 로그) 만든다.
void main() {
  group('HeadlessQueueDepthTracker', () {
    test('starts at depth 0', () {
      final tracker = HeadlessQueueDepthTracker();
      expect(tracker.depth, 0);
      expect(tracker.peak, 0);
    });

    test('enqueue increments depth, dequeue decrements it', () {
      final tracker = HeadlessQueueDepthTracker();

      tracker.enqueue();
      tracker.enqueue();
      expect(tracker.depth, 2);

      tracker.dequeue();
      expect(tracker.depth, 1);
    });

    test('dequeue never goes negative even if called more than enqueue', () {
      final tracker = HeadlessQueueDepthTracker();

      tracker.dequeue();
      tracker.dequeue();

      expect(
        tracker.depth,
        0,
        reason: '방어적 하한 - 짝이 안 맞는 호출이 있어도 음수 깊이로 상태가 '
            '어긋나면 이후의 경고 판정이 전부 틀어진다',
      );
    });

    test('peak tracks the highest depth ever reached, not the current one',
        () {
      final tracker = HeadlessQueueDepthTracker();

      tracker.enqueue();
      tracker.enqueue();
      tracker.enqueue();
      expect(tracker.peak, 3);

      tracker.dequeue();
      tracker.dequeue();
      expect(
        tracker.depth,
        1,
        reason: '현재 깊이는 내려가도',
      );
      expect(
        tracker.peak,
        3,
        reason: '한 번이라도 도달한 최고 깊이는 유지되어야 나중에 '
            '"이 세션에서 최악에 몇 건까지 밀렸었는지" 를 알 수 있다',
      );
    });

    test('onWarn fires exactly once when depth first reaches the threshold',
        () {
      var warnCount = 0;
      int? warnedAtDepth;
      final tracker = HeadlessQueueDepthTracker(
        warnThreshold: 3,
        onWarn: (depth) {
          warnCount++;
          warnedAtDepth = depth;
        },
      );

      tracker.enqueue(); // 1
      tracker.enqueue(); // 2
      expect(warnCount, 0, reason: '아직 임계값 미만');

      tracker.enqueue(); // 3 - 임계값 도달
      expect(warnCount, 1);
      expect(warnedAtDepth, 3);

      tracker.enqueue(); // 4 - 이미 넘었으니 매 건마다 다시 울리지 않는다
      expect(
        warnCount,
        1,
        reason: '임계값을 넘은 채로 계속 쌓여도 매번 경고하면 로그가 '
            '스팸이 된다 - 처음 도달했을 때 한 번만',
      );
    });

    test('onWarn fires again if depth drains below threshold and climbs '
        'back up', () {
      var warnCount = 0;
      final tracker = HeadlessQueueDepthTracker(
        warnThreshold: 2,
        onWarn: (_) => warnCount++,
      );

      tracker.enqueue();
      tracker.enqueue(); // 경고 1회
      expect(warnCount, 1);

      tracker.dequeue();
      tracker.dequeue(); // 0으로 배출됨 - 밀림이 해소됨
      tracker.enqueue();
      tracker.enqueue(); // 다시 임계값 도달 - 새로운 밀림이므로 다시 경고

      expect(
        warnCount,
        2,
        reason: '큐가 완전히 비워졌다가 다시 밀리기 시작하면 별개의 '
            '지연 사건이므로 다시 경고해야 한다',
      );
    });

    test(
        'onWarn does NOT re-fire on a partial dip below threshold that never '
        'fully drains', () {
      var warnCount = 0;
      final tracker = HeadlessQueueDepthTracker(
        warnThreshold: 10,
        onWarn: (_) => warnCount++,
      );

      for (var i = 0; i < 10; i++) {
        tracker.enqueue();
      }
      expect(warnCount, 1, reason: '10에서 최초 경고');

      // 완전히 비우지 않고 살짝만 내려갔다가(9) 다시 10으로 - 여전히 같은
      // 밀림 사건이다.
      tracker.dequeue();
      tracker.enqueue();

      expect(
        warnCount,
        1,
        reason: '큐가 한 번도 완전히 빠지지 않았다면 여전히 같은 밀림 '
            '사건이다 - depth 가 임계값을 스칠 때마다 다시 경고하면, '
            '9↔10 사이를 오가는 정상적인 처리 흐름만으로도 로그가 '
            '스팸이 된다',
      );
    });
  });
}
