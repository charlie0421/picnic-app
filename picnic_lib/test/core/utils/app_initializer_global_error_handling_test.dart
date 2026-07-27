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
/// Three further properties are pinned because nothing else does:
///
///  3. a `silent` framework error produces **no** Sentry event. Dropping the
///     handler's own `Sentry.captureException` also dropped these, since
///     `FlutterErrorIntegration` skips them. That is a deliberate decision, not
///     a side effect — see
///     [AppInitializerHelper.reportSilentFlutterErrors], which both production
///     and the test below read, so flipping it turns this red;
///  4. delegation goes through the *live* [FlutterError.presentError] when we
///     wrapped the framework default, so DevTools toggling structured errors
///     mid-session is honoured rather than pinned to an install-time snapshot;
///  5. the two `logger.e` calls happen, and happen exactly once — they are the
///     whole reason this handler still exists next to the Sentry integrations,
///     and installing twice must not double them.
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/app_initializer_helper.dart';
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
      // Read the production decision rather than restating it: if this flips to
      // true, the "silent errors are not reported" test below fails.
      ..reportSilentFlutterErrors =
          AppInitializerHelper.reportSilentFlutterErrors
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
  // Installation is idempotent in production, so every test that wants to
  // install has to clear the flag first.
  AppInitializer.resetGlobalErrorHandlingForTest();
  var done = false;
  void restore() {
    if (done) return;
    done = true;
    FlutterError.onError = flutterOnError;
    FlutterError.presentError = presentError;
    PlatformDispatcher.instance.onError = platformOnError;
    AppInitializer.resetGlobalErrorHandlingForTest();
  }

  addTearDown(restore);
  return restore;
}

/// Everything `logger` writes while [body] runs.
///
/// `logger` is a top-level final in `picnic_lib/core/utils/logger.dart` with no
/// seam, but its `ConsoleOutput` goes through `print`, which resolves against
/// `Zone.current` — so a zone with a `print` handler captures it.
List<String> _capturePrints(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

/// A [FlutterErrorDetails] shaped like the one the framework builds, used by the
/// tests that invoke `FlutterError.onError` directly instead of going through a
/// real render failure.
FlutterErrorDetails _details(Object exception, {bool silent = false}) {
  return FlutterErrorDetails(
    exception: exception,
    stack: StackTrace.current,
    library: silent ? 'image resource service' : 'rendering library',
    context: ErrorDescription(
      silent ? 'resolving an image codec' : 'during layout',
    ),
    silent: silent,
  );
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

    testWidgets(
      'a silent framework error is deliberately not reported to Sentry',
      (tester) async {
        final restoreGlobals = _snapshotGlobals();

        final sentry = _SentryHarness();
        await sentry.start();
        addTearDown(sentry.stop);

        FlutterError.onError = FlutterError.presentError;
        await AppInitializer.initializeGlobalErrorHandling();
        final integration = FlutterErrorIntegration();
        integration.call(HubAdapter(), sentry.options);
        addTearDown(integration.close);

        // Shaped like what MultiFrameImageStreamCompleter reports when the
        // image CDN fails: image_stream.dart:910/985/998/1085 and
        // image_provider.dart:403 all pass `silent: true`.
        FlutterError.onError!(_details(StateError('image codec'), silent: true));
        await tester.runAsync(() => Future<void>.delayed(_settleDelay));
        restoreGlobals();

        expect(
          sentry.capturedEvents,
          isEmpty,
          reason: 'silent framework errors are intentionally not reported - '
              'see AppInitializerHelper.reportSilentFlutterErrors for why. '
              'Flipping that constant must fail this test, not change '
              'behaviour quietly.',
        );
        expect(sentry.transport.envelopes, isEmpty);
      },
    );

    testWidgets(
      'delegates through the live presentError so a later swap is honoured',
      (tester) async {
        final restoreGlobals = _snapshotGlobals();

        // Production state at install time: `FlutterError.onError` still holds
        // the snapshot of `presentError` taken when the static was initialised.
        FlutterError.onError = FlutterError.presentError;
        await AppInitializer.initializeGlobalErrorHandling();

        // What WidgetInspectorService does when DevTools toggles
        // `ext.flutter.inspector.structuredErrors` on, i.e. after we installed.
        final presented = <FlutterErrorDetails>[];
        FlutterError.presentError = presented.add;

        FlutterError.onError!(_details(StateError('probe')));
        restoreGlobals();

        expect(
          presented,
          hasLength(1),
          reason: 'holding the install-time snapshot would send this to the '
              'old dumpErrorToConsole and silently ignore the swap',
        );
      },
    );

    testWidgets('keeps an explicitly installed handler over presentError',
        (tester) async {
      final restoreGlobals = _snapshotGlobals();

      final received = <FlutterErrorDetails>[];
      final presented = <FlutterErrorDetails>[];
      FlutterError.onError = received.add;
      await AppInitializer.initializeGlobalErrorHandling();
      FlutterError.presentError = presented.add;

      FlutterError.onError!(_details(StateError('probe')));
      restoreGlobals();

      expect(received, hasLength(1));
      expect(
        presented,
        isEmpty,
        reason: 'the live-presentError path is only for the framework default; '
            'a deliberately installed handler must not be bypassed',
      );
    });

    testWidgets('logs the framework error through logger.e exactly once',
        (tester) async {
      final restoreGlobals = _snapshotGlobals();

      FlutterError.onError = (_) {};
      await AppInitializer.initializeGlobalErrorHandling();
      // Installation is idempotent: a second call must not wrap the first, or
      // every framework error would be logged twice.
      await AppInitializer.initializeGlobalErrorHandling();

      final printed = _capturePrints(() {
        FlutterError.onError!(_details(StateError('flutter-log-probe')));
      });
      restoreGlobals();

      final output = printed.join('\n');
      expect(
        output,
        contains('Flutter Error'),
        reason: 'the structured on-device log is the reason this handler is '
            'not handed wholesale to the Sentry integrations',
      );
      expect(
        'flutter-log-probe'.allMatches(output),
        hasLength(1),
        reason: 'a second installGlobalErrorHandling must be a no-op',
      );
    });
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

    test('logs the async error through logger.e exactly once', () async {
      final restoreGlobals = _snapshotGlobals();

      PlatformDispatcher.instance.onError = null;
      await AppInitializer.initializeGlobalErrorHandling();
      await AppInitializer.initializeGlobalErrorHandling();

      final printed = _capturePrints(() {
        PlatformDispatcher.instance.onError!(
          StateError('async-log-probe'),
          StackTrace.current,
        );
      });
      restoreGlobals();

      final output = printed.join('\n');
      expect(output, contains('Unhandled Asynchronous Error'));
      expect(
        'async-log-probe'.allMatches(output),
        hasLength(1),
        reason: 'a second installGlobalErrorHandling must be a no-op',
      );
    });
  });
}
