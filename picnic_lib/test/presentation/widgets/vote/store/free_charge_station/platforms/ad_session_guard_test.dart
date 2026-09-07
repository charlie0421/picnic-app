import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart';

/// `showAd()` 는 `await` 없이 발사되고, 그 안의 첫 `await`(safelyExecute 의
/// checkLogin)까지만 동기다. 그 사이에 두 번째 탭이 들어오면 광고 라우트가 둘
/// 열리고, 두 라우트가 같은 인스턴스의 `_viewToken`/`_moreToken` 을 공유해
/// 나중에 끝난 발급이 앞선 라우트의 토큰을 덮어쓴다 (PICNIC-2551).
///
/// 프로덕션 실측(7일): 500ms 이내 연속 발급 38쌍 / 2초 이내 62쌍.
void main() {
  group('AdSessionGuard', () {
    test('세션이 열려 있는 동안 두 번째 호출은 body 를 실행하지 않는다', () async {
      final guard = AdSessionGuard();
      final gate = Completer<void>();
      var runs = 0;

      final first = guard.run(() {
        runs++;
        return gate.future;
      });
      // 첫 세션이 아직 안 끝난 시점 — 연타가 여기로 들어온다.
      final second = await guard.run(() async => runs++);

      expect(second, isFalse);
      expect(runs, 1);
      expect(guard.isOpen, isTrue);

      gate.complete();
      expect(await first, isTrue);
    });

    test('첫 세션이 끝나면 다시 열 수 있다', () async {
      final guard = AdSessionGuard();
      var runs = 0;

      expect(await guard.run(() async => runs++), isTrue);
      expect(guard.isOpen, isFalse);
      // 광고를 보고 나온 뒤 다시 누르는 정상 흐름은 막히면 안 된다.
      expect(await guard.run(() async => runs++), isTrue);

      expect(runs, 2);
    });

    test('body 가 던져도 래치는 풀리고 예외는 전파된다', () async {
      final guard = AdSessionGuard();

      await expectLater(
        guard.run(() async => throw StateError('play failed')),
        throwsStateError,
      );

      // 래치가 물린 채 남으면 사용자는 광고를 영영 못 연다.
      expect(guard.isOpen, isFalse);
      expect(await guard.run(() async {}), isTrue);
    });

    test('동기적으로 잠근다 — 첫 await 이전에 들어온 호출도 막힌다', () async {
      final guard = AdSessionGuard();
      var runs = 0;
      Future<void> body() async {
        runs++;
        await Future<void>.delayed(Duration.zero);
      }

      // await 없이 연달아 호출: 같은 이벤트 루프 턴에서 두 번 들어오는,
      // 실제 연타와 같은 모양이다.
      final a = guard.run(body);
      final b = guard.run(body);
      final c = guard.run(body);

      expect(await a, isTrue);
      expect(await b, isFalse);
      expect(await c, isFalse);
      expect(runs, 1);
    });
  });
}
