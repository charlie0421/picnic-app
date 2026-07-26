/// Pins the behaviour of [AppInitializer.initializeGlobalErrorHandling].
///
/// A regression here is invisible: global error handling only misbehaves once
/// something *else* breaks, and the symptom is missing information rather than
/// a failure. These tests therefore assert on the two properties that were
/// actually lost when the handler simply replaced [FlutterError.onError]:
///
///  1. the full [FlutterErrorDetails] — `context`, `library` and above all
///     `informationCollector`, which carries the `debugCreator` widget chain —
///     still reaches the handler that was installed before ours, and
///  2. one framework error still produces exactly **one** Sentry capture.
///
/// ## Why these tests use sentry_flutter internals
///
/// The handler's correctness is entirely about how it *composes* with the two
/// integrations `SentryFlutter.init` installs — `FlutterErrorIntegration` and
/// `OnErrorIntegration` — both of which chain to the handler that is current
/// at init time. Neither is reachable through the public API here:
///
///  * `SentryFlutter.init` needs native platform channels and would replace
///    the transport with `FileSystemTransport`, so it cannot run under
///    `flutter test`;
///  * `FlutterErrorIntegration` is not exported by `package:sentry_flutter`;
///  * `OnErrorIntegration`'s default dispatcher wrapper writes through
///    `WidgetsBinding.instance.platformDispatcher`, and flutter_test's
///    `TestPlatformDispatcher.onError` setter is a no-op — it reads the getter
///    and discards the value (flutter_test/lib/src/window.dart). The real
///    `PlatformDispatcher.instance` therefore has to be wrapped explicitly.
///
/// Using the real integration classes is deliberate: a hand-rolled stand-in
/// would only prove that the stand-in behaves as written. If a future
/// sentry_flutter upgrade moves or changes these classes this file stops
/// compiling, which is the correct signal — the fix depends on their chaining
/// behaviour.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'package:sentry_flutter/src/integrations/flutter_error_integration.dart';
import 'package:sentry_flutter/src/utils/platform_dispatcher_wrapper.dart';

/// Wall-clock time given to Sentry's in-memory capture pipeline before the
/// event count is asserted. Long enough that a *second*, unwanted capture
/// would also have landed — the assertions are `hasLength(1)`, so a too-short
/// wait would hide double reporting rather than expose it.
const _settleDelay = Duration(milliseconds: 300);

class _RecordingTransport implements Transport {
  final List<SentryEnvelope> envelopes = [];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return envelope.header.eventId;
  }
}

/// Harness around a real Sentry hub whose only stand-in is the HTTP transport.
class _SentryHarness {
  _SentryHarness();

  final transport = _RecordingTransport();
  final capturedEvents = <SentryEvent>[];
  late final SentryFlutterOptions options;

  Future<void> start() async {
    options = SentryFlutterOptions()
      ..dsn = 'https://public@o0.ingest.sentry.io/0'
      ..automatedTestMode = true
      ..transport = transport
      ..autoInitializeNativeSdk = false
      ..enableDartSymbolication = false
      // Deduplication is ON in production and would silently swallow a second
      // capture of the same exception object. Turning it off here is what makes
      // "exactly one capture" measure the captures our code *issues* rather
      // than the ones that happen to survive a race inside the SDK.
      ..enableDeduplication = false
      ..beforeSend = (event, hint) {
        capturedEvents.add(event);
        return event;
      };

    await Sentry.init((o) => o.debug = false, options: options);
  }

  Future<void> stop() => Sentry.close();
}

/// A widget whose name must show up in the diagnostics of the overflow it
/// causes. `Row` is given 300px of content inside a 50px box.
class _OverflowProbe extends StatelessWidget {
  const _OverflowProbe();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 50,
          child: Row(children: [SizedBox(width: 300, height: 10)]),
        ),
      ),
    );
  }
}

/// Renders `details.informationCollector` exactly the way
/// `FlutterErrorIntegration` does before putting it on the Sentry event, so
/// assertions here describe what an engineer would actually see.
String _renderInformation(FlutterErrorDetails details) {
  final nodes = details.informationCollector?.call().toList() ?? const [];
  return (StringBuffer()..writeAll(nodes, '\n')).toString();
}

/// Snapshots every global this suite mutates and returns an idempotent
/// restore callback, also registered as a tear-down.
///
/// Callers must invoke the returned callback **before** their first `expect`:
/// while `FlutterError.onError` is redirected, flutter_test cannot route a
/// failed expectation and reports an unrelated "A test overrode
/// FlutterError.onError…" assertion instead of the real failure.
VoidCallback _snapshotGlobals() {
  final flutterOnError = FlutterError.onError;
  final presentError = FlutterError.presentError;
  final platformOnError = PlatformDispatcher.instance.onError;
  var done = false;
  void restore() {
    if (done) return;
    done = true;
    FlutterError.onError = flutterOnError;
    FlutterError.presentError = presentError;
    PlatformDispatcher.instance.onError = platformOnError;
  }

  addTearDown(restore);
  return restore;
}

void main() {
  group('initializeGlobalErrorHandling - FlutterError.onError', () {
    testWidgets(
      'forwards the complete FlutterErrorDetails to the previous handler',
      (tester) async {
        final restoreGlobals = _snapshotGlobals();

        final received = <FlutterErrorDetails>[];
        // Stands in for whatever is installed before AppInitializer runs; in
        // production that is FlutterError.presentError.
        FlutterError.onError = received.add;

        await AppInitializer.initializeGlobalErrorHandling();

        await tester.pumpWidget(const _OverflowProbe());
        await tester.pump();
        restoreGlobals();

        expect(
          received,
          hasLength(1),
          reason: 'the handler installed before ours must still be invoked - '
              'replacing FlutterError.onError instead of decorating it is the '
              'regression this test exists to catch',
        );

        final details = received.single;
        expect(details.exception.toString(), contains('RenderFlex overflowed'));

        // Everything below is discarded by an `exception`+`stack` only handler.
        expect(details.context?.toDescription(), 'during layout');
        expect(details.library, 'rendering library');

        final information = _renderInformation(details);
        expect(
          information,
          contains('debugCreator'),
          reason: 'the widget creator chain must survive to the handler',
        );
        expect(
          information,
          contains('_OverflowProbe'),
          reason: 'the failing widget must be nameable from the diagnostics',
        );
      },
    );

    testWidgets(
      'falls back to FlutterError.presentError when no handler was installed',
      (tester) async {
        final restoreGlobals = _snapshotGlobals();

        final presented = <FlutterErrorDetails>[];
        FlutterError.onError = null;
        FlutterError.presentError = presented.add;

        await AppInitializer.initializeGlobalErrorHandling();

        await tester.pumpWidget(const _OverflowProbe());
        await tester.pump();
        restoreGlobals();

        expect(presented, hasLength(1));
        expect(
          _renderInformation(presented.single),
          contains('_OverflowProbe'),
        );
      },
    );

    testWidgets(
      'one framework error produces exactly one Sentry capture',
      (tester) async {
        final restoreGlobals = _snapshotGlobals();

        final sentry = _SentryHarness();
        await sentry.start();
        addTearDown(sentry.stop);

        // Reproduce the production init order:
        //   framework default -> AppInitializer -> SentryFlutter.init
        FlutterError.onError = FlutterError.presentError;
        await AppInitializer.initializeGlobalErrorHandling();
        final integration = FlutterErrorIntegration();
        integration.call(HubAdapter(), sentry.options);
        addTearDown(integration.close);

        await tester.pumpWidget(const _OverflowProbe());
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(_settleDelay));
        restoreGlobals();

        expect(
          sentry.capturedEvents,
          hasLength(1),
          reason: 'FlutterErrorIntegration already reports this error; an '
              'extra Sentry.captureException in our handler double-reports',
        );
        expect(
          sentry.transport.envelopes,
          hasLength(1),
          reason: 'a second capture must not reach the transport either',
        );

        // The surviving event must be the rich one from the integration, not a
        // bare captureException without mechanism or widget context.
        final event = sentry.capturedEvents.single;
        expect(event.exceptions?.first.mechanism?.type, 'FlutterError');

        final flutterErrorDetails =
            event.contexts['flutter_error_details'] as Map<String, dynamic>?;
        expect(flutterErrorDetails, isNotNull);
        expect(flutterErrorDetails!['context'], 'thrown during layout');
        expect(flutterErrorDetails['library'], 'rendering library');
        expect(
          flutterErrorDetails['information'] as String,
          contains('_OverflowProbe'),
          reason: 'the widget attribution must reach Sentry, not just the log',
        );
      },
    );
  });

  group('initializeGlobalErrorHandling - PlatformDispatcher.onError', () {
    late _SentryHarness sentry;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      sentry = _SentryHarness();
      await sentry.start();
    });

    tearDown(() => sentry.stop());

    test('chains to the previous handler and reports the error as handled',
        () async {
      final restoreGlobals = _snapshotGlobals();

      final seen = <Object>[];
      PlatformDispatcher.instance.onError = (error, stack) {
        seen.add(error);
        return false;
      };

      await AppInitializer.initializeGlobalErrorHandling();

      final error = StateError('async boom');
      final handled =
          PlatformDispatcher.instance.onError!(error, StackTrace.current);
      restoreGlobals();

      expect(handled, isTrue);
      expect(seen, [same(error)]);

      await Future<void>.delayed(_settleDelay);
      expect(
        sentry.capturedEvents,
        isEmpty,
        reason: 'on non-web OnErrorIntegration owns reporting for this path; '
            'capturing here as well double-reports',
      );
    });

    test('one async error produces exactly one Sentry capture', () async {
      final restoreGlobals = _snapshotGlobals();

      PlatformDispatcher.instance.onError = null;
      await AppInitializer.initializeGlobalErrorHandling();

      final integration = OnErrorIntegration(
        dispatchWrapper: PlatformDispatcherWrapper(PlatformDispatcher.instance),
      );
      integration.call(HubAdapter(), sentry.options);
      addTearDown(integration.close);

      final handled = PlatformDispatcher.instance.onError!(
        StateError('async boom'),
        StackTrace.current,
      );
      await Future<void>.delayed(_settleDelay);
      restoreGlobals();

      expect(handled, isTrue);
      expect(sentry.capturedEvents, hasLength(1));
      expect(sentry.transport.envelopes, hasLength(1));
      expect(
        sentry.capturedEvents.single.exceptions?.first.mechanism?.type,
        'PlatformDispatcher.onError',
      );
    });
  });
}
