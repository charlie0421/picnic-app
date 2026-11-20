import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../../helpers/test_app.dart';

class _TestAdPlatform extends AdPlatform {
  _TestAdPlatform(super.ref, super.context, super.id);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showAd() async {}

  @override
  Future<void> handleError(dynamic error, StackTrace? stackTrace) async {}

  bool showFailure(PlatformException error) =>
      showAdLoadFailureDialog('Pangle', error, error.toString());
}

void main() {
  late List<SentryEvent> capturedEvents;
  late Completer<void> firstEvent;

  setUp(() async {
    initTestEnvironment();
    capturedEvents = <SentryEvent>[];
    firstEvent = Completer<void>();
    await Sentry.init((options) {
      options
        ..dsn = 'https://public@o0.ingest.sentry.io/0'
        ..debug = false
        ..enableDeduplication = false
        ..beforeSend = (event, hint) {
          capturedEvents.add(event);
          if (!firstEvent.isCompleted) firstEvent.complete();
          // Record capture attempts and stop them before any network transport.
          return null;
        };
    });
  });

  tearDown(() async {
    await Sentry.close();
  });

  Future<_TestAdPlatform> buildPlatform(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      buildTestApp(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _TestAdPlatform(capturedRef, capturedContext, 'pangle');
  }

  Future<void> waitForReports(
    WidgetTester tester, {
    bool expectReport = false,
  }) async {
    await tester.runAsync(() async {
      // logAdLoadFailure starts captureException without awaiting its result.
      if (expectReport) {
        await firstEvent.future.timeout(const Duration(seconds: 5));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
  }

  const cases = <String, (String, String, bool)>{
    'region unsupported': (
      'The country/region is currently not supported by Pangle.',
      'unavailable',
      false,
    ),
    'low CPR': (
      'the fill rate for this placement was restricted temporarily due to the low CPR.',
      'unavailable',
      false,
    ),
    'no-fill': (
      'request was not filled because of the lack of suitable ads.',
      'exhausted',
      false,
    ),
    'GDPR': (
      'Prohibit request ads by compliance. Please check the GDPR consent status.',
      'error',
      true,
    ),
    'internal error': ('internal service error', 'error', true),
  };

  for (final entryPoint in ['logAdLoadFailure', 'showAdLoadFailureDialog']) {
    cases.forEach((label, fixture) {
      testWidgets('$entryPoint: $label 안내 1회와 보고 여부', (tester) async {
        final platform = await buildPlatform(tester);
        final l10n = AppLocalizations.of(platform.context);
        final (message, expectedDialog, shouldReport) = fixture;
        final error = PlatformException(code: 'LoadFailed', message: message);

        if (entryPoint == 'logAdLoadFailure') {
          platform.logAdLoadFailure(
            'Pangle',
            error,
            'test-placement',
            error.toString(),
            StackTrace.current,
          );
        } else {
          final reportable = platform.showFailure(error);
          expect(reportable, shouldReport);
          // This entry point delegates reporting to its caller (e.g. Tapjoy).
          expect(capturedEvents, isEmpty);
          if (reportable) {
            await tester.runAsync(() => Sentry.captureException(error));
          }
        }
        await tester.pumpAndSettle();
        await waitForReports(tester, expectReport: shouldReport);

        expect(find.byType(Dialog), findsOneWidget);
        final expectedText = switch (expectedDialog) {
          'unavailable' => l10n.label_ads_temporarily_unavailable,
          'exhausted' => l10n.dialog_content_ads_exhausted,
          _ => l10n.label_ads_load_fail,
        };
        expect(find.text(expectedText), findsOneWidget);
        expect(
          find.byIcon(Icons.error_outline),
          shouldReport ? findsOneWidget : findsNothing,
        );
        if (expectedDialog == 'exhausted') {
          expect(find.text(l10n.dialog_title_ads_exhausted), findsOneWidget);
        } else {
          expect(find.text(l10n.dialog_title_ads_exhausted), findsNothing);
        }
        expect(capturedEvents, hasLength(shouldReport ? 1 : 0));
        platform.dispose();
      });
    });

    for (final message in cases.values.take(2).map((fixture) => fixture.$1)) {
      for (final unmount in [false, true]) {
        testWidgets('$entryPoint: dispose/unmount=$unmount 뒤 안내 없음: $message', (
          tester,
        ) async {
          final platform = await buildPlatform(tester);
          if (unmount) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            expect(platform.context.mounted, isFalse);
          } else {
            platform.dispose();
            expect(platform.context.mounted, isTrue);
          }
          final error = PlatformException(code: 'LoadFailed', message: message);
          if (entryPoint == 'logAdLoadFailure') {
            platform.logAdLoadFailure(
              'Pangle',
              error,
              'test-placement',
              error.toString(),
              null,
            );
          } else {
            expect(platform.showFailure(error), isFalse);
          }
          await tester.pumpAndSettle();
          await waitForReports(tester);
          expect(find.byType(Dialog), findsNothing);
          expect(capturedEvents, isEmpty);
          if (unmount) platform.dispose();
        });
      }
    }
  }
}
