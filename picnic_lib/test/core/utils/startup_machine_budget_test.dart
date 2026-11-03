import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/startup_machine_budget.dart';

void main() {
  group('StartupMachineBudget', () {
    test('sequential machine operations consume one cumulative deadline', () {
      fakeAsync((async) {
        final budget = StartupMachineBudget(
          limit: const Duration(seconds: 5),
          elapsed: () => async.elapsed,
        );
        var firstCompleted = false;
        Object? secondError;

        budget
            .run(
              () => Future<void>.delayed(const Duration(seconds: 3)),
              stage: 'first',
            )
            .then((_) => firstCompleted = true);
        async.elapse(const Duration(seconds: 3));

        expect(firstCompleted, isTrue);
        expect(budget.remaining, const Duration(seconds: 2));

        budget
            .run(
              () => Future<void>.delayed(const Duration(seconds: 3)),
              stage: 'second',
            )
            .then<void>((_) {}, onError: (Object error) => secondError = error);
        async.elapse(const Duration(milliseconds: 1999));
        expect(secondError, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(secondError, isA<TimeoutException>());
        expect(budget.remaining, Duration.zero);

        // Drain the ignored result from the timed-out operation.
        async.elapse(const Duration(seconds: 1));
      });
    });

    test('time between machine operations does not consume the budget', () {
      fakeAsync((async) {
        final budget = StartupMachineBudget(
          limit: const Duration(seconds: 5),
          elapsed: () => async.elapsed,
        );
        var firstCompleted = false;
        var secondCompleted = false;

        budget
            .run(
              () => Future<void>.delayed(const Duration(seconds: 1)),
              stage: 'before-user-decision',
            )
            .then((_) => firstCompleted = true);
        async.elapse(const Duration(seconds: 1));
        expect(firstCompleted, isTrue);

        // Represents time spent waiting on a visible user decision.
        async.elapse(const Duration(minutes: 1));
        expect(budget.remaining, const Duration(seconds: 4));

        budget
            .run(
              () => Future<void>.delayed(const Duration(seconds: 3)),
              stage: 'after-user-decision',
            )
            .then((_) => secondCompleted = true);
        async.elapse(const Duration(seconds: 3));

        expect(secondCompleted, isTrue);
        expect(budget.remaining, const Duration(seconds: 1));
      });
    });
  });
}
