import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

/// The '더보기' click is reported at most once per view, but "at most once"
/// must mean *one successful report*, not *one attempt*. The server stamp is
/// idempotent, so a retry after a failed attempt costs nothing and is the only
/// way a transient failure does not silently drop the click.
void main() {
  group('AdCtaClickReporter', () {
    test('a successful report happens once and is not repeated', () async {
      var calls = 0;
      final reporter = AdCtaClickReporter(() async {
        calls++;
        return true;
      });

      await reporter.call();
      await reporter.call();

      expect(calls, 1);
      expect(reporter.reported, isTrue);
    });

    test('a failed report can be retried', () async {
      var calls = 0;
      final reporter = AdCtaClickReporter(() async {
        calls++;
        return calls > 1;
      });

      await reporter.call();
      expect(reporter.reported, isFalse, reason: 'first attempt failed');

      // The user comes back from the browser and taps 더보기 again.
      await reporter.call();

      expect(calls, 2);
      expect(reporter.reported, isTrue);
    });

    test('a second tap while the first is still in flight is dropped', () async {
      var calls = 0;
      final gate = Completer<bool>();
      final reporter = AdCtaClickReporter(() {
        calls++;
        return gate.future;
      });

      final first = reporter.call();
      final second = reporter.call();
      await pumpEventQueue();

      expect(calls, 1, reason: 'no duplicate request while one is open');

      gate.complete(true);
      await first;
      await second;
      expect(reporter.reported, isTrue);
    });

    test('a throwing report leaves the reporter retryable', () async {
      var calls = 0;
      final reporter = AdCtaClickReporter(() async {
        calls++;
        if (calls == 1) throw StateError('disposed');
        return true;
      });

      await expectLater(reporter.call(), throwsStateError);
      expect(reporter.reported, isFalse);

      // The in-flight latch must not stay stuck after a throw.
      await reporter.call();
      expect(calls, 2);
      expect(reporter.reported, isTrue);
    });
  });
}
