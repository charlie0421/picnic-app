import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_reporter.dart';

void main() {
  const impression = '00000000-0000-4000-8000-000000000402';
  test('sends cumulative maximum without duplicate statements', () async {
    final sent = <int>[];
    final reporter = ShortformPlaybackReporter(
      eligible: () => true,
      send: (ms) async {
        sent.add(ms);
      },
    );
    reporter.update(500);
    await reporter.flush();
    reporter.update(500);
    await reporter.flush();
    reporter.update(100);
    await reporter.flush();
    expect(sent, [500]);
    reporter.stop();
  });
  test('serializes concurrent reports and flushes the final maximum', () {
    fakeAsync((time) {
      final sent = <int>[];
      final first = Completer<void>();
      final reporter = ShortformPlaybackReporter(
        eligible: () => true,
        elapsed: () => time.elapsed,
        send: (ms) {
          sent.add(ms);
          return sent.length == 1 ? first.future : Future.value();
        },
      );
      reporter.update(500);
      unawaited(reporter.flush());
      reporter.update(1000);
      unawaited(reporter.close());
      expect(sent, [500]);
      first.complete();
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 1));
      expect(sent, [500, 1000]);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
  test('retries the same cumulative value after a transient failure', () {
    fakeAsync((time) {
      final sent = <int>[];
      final reporter = ShortformPlaybackReporter(
        eligible: () => true,
        elapsed: () => time.elapsed,
        send: (ms) async {
          sent.add(ms);
          if (sent.length == 1) throw StateError('offline');
        },
      );
      reporter.update(750);
      unawaited(reporter.close());
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 1));
      expect(sent, [750, 750]);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
  test('repeated failures stop after three attempts and release timers', () {
    fakeAsync((time) {
      var attempts = 0;
      final reporter = ShortformPlaybackReporter(
        eligible: () => true,
        elapsed: () => time.elapsed,
        send: (_) async {
          attempts++;
          throw StateError('offline');
        },
      );
      reporter.update(500);
      unawaited(reporter.close());
      time.elapse(const Duration(minutes: 1));
      expect(attempts, 3);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
  test('revocation or an owner change cancels pending retries', () {
    fakeAsync((time) {
      var eligible = true;
      var attempts = 0;
      final reporter = ShortformPlaybackReporter(
        eligible: () => eligible,
        elapsed: () => time.elapsed,
        send: (_) async {
          attempts++;
          throw StateError('offline');
        },
      );
      reporter.update(500);
      unawaited(reporter.flush());
      time.flushMicrotasks();
      eligible = false;
      time.elapse(const Duration(seconds: 10));
      expect(attempts, 1);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
  test('explicit stop cancels retries and discards queued work', () {
    fakeAsync((time) {
      var attempts = 0;
      final reporter = ShortformPlaybackReporter(
        eligible: () => true,
        elapsed: () => time.elapsed,
        send: (_) async {
          attempts++;
          throw StateError('offline');
        },
      );
      reporter.update(500);
      unawaited(reporter.flush());
      time.flushMicrotasks();
      reporter.stop();
      time.elapse(const Duration(minutes: 1));
      reporter.update(1000);
      unawaited(reporter.flush());
      expect(attempts, 1);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
  test(
    'RPC payload contains only the impression and cumulative milliseconds',
    () async {
      final calls = <Map<String, dynamic>>[];
      final reporter = ShortformPlaybackReporter.forImpression(
        impressionId: impression,
        ownerUserId: 'owner',
        currentOwner: () => 'owner',
        hasConsent: () => true,
        invoke: (name, params) async {
          expect(name, 'record_kpop_playback');
          calls.add(params);
        },
      );
      reporter.update(1234);
      await reporter.close();
      expect(calls, [
        {'p_impression': impression, 'p_watched_ms': 1234},
      ]);
    },
  );
  test('missing impression consent or current owner sends nothing', () async {
    var calls = 0;
    for (final value in [
      (impression, 'owner', false),
      ('', 'owner', true),
      (impression, 'other-owner', true),
    ]) {
      final reporter = ShortformPlaybackReporter.forImpression(
        impressionId: value.$1,
        ownerUserId: 'owner',
        currentOwner: () => value.$2,
        hasConsent: () => value.$3,
        invoke: (_, _) async {
          calls++;
        },
      );
      reporter.update(500);
      await reporter.close();
    }
    expect(calls, 0);
  });
}
