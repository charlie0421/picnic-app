import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/store_launcher.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

import '../../helpers/test_environment.dart';

/// PICNIC-APP-45D: on iOS 27 the force-update button did nothing.
/// `canLaunchUrlString` returned false for the App Store https URL, the
/// handler threw the localized message as a String, the error went to
/// Sentry, and the user saw no feedback on a screen they cannot leave.
void main() {
  const storeUrl = 'https://apps.apple.com/app/id6504887262';
  const message = '앱 스토어를 열 수 없습니다.';

  late List<String> launched;
  late List<(StoreLaunchResult, String)> reports;

  setUp(() {
    initTestColors();
    launched = [];
    reports = [];
    StoreLauncher.debugReporter = (result, surface) =>
        reports.add((result, surface));
  });

  tearDown(() {
    StoreLauncher.debugLauncher = null;
    StoreLauncher.debugReporter = null;
  });

  Future<void> pumpOverlay(WidgetTester tester, {String? url = storeUrl}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ForceUpdateOverlay(
          updateInfo: UpdateInfo(
            status: UpdateStatus.updateRequired,
            currentVersion: '1.3.4',
            latestVersion: '1.3.6',
            forceVersion: '1.3.5',
            url: url,
          ),
        ),
      ),
    );
  }

  Future<void> tapUpdate(WidgetTester tester) async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the store URL directly, without a canLaunch check', (
    tester,
  ) async {
    StoreLauncher.debugLauncher = (url) async {
      launched.add(url);
      return true;
    };
    await pumpOverlay(tester);

    await tapUpdate(tester);

    expect(launched, [storeUrl]);
    expect(find.text(message), findsNothing);
    expect(reports, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused launch shows the message and keeps the button', (
    tester,
  ) async {
    StoreLauncher.debugLauncher = (url) async {
      launched.add(url);
      return false;
    };
    await pumpOverlay(tester);

    await tapUpdate(tester);

    expect(tester.takeException(), isNull, reason: 'must not throw (45D)');
    expect(find.text(message), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(reports, [(StoreLaunchResult.refused, 'force_update')]);

    // Retry works: the next tap launches again.
    StoreLauncher.debugLauncher = (url) async {
      launched.add(url);
      return true;
    };
    await tapUpdate(tester);
    expect(launched, [storeUrl, storeUrl]);
    expect(find.text(message), findsNothing);
  });

  testWidgets('a platform error shows the message and does not throw', (
    tester,
  ) async {
    StoreLauncher.debugLauncher = (url) async =>
        throw PlatformException(code: 'Error', message: 'launch failed');
    await pumpOverlay(tester);

    await tapUpdate(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(message), findsOneWidget);
    expect(reports, [(StoreLaunchResult.failed, 'force_update')]);
  });

  testWidgets(
    'an older attempt that fails late does not hide a newer success',
    (tester) async {
      final first = Completer<bool>();
      var calls = 0;
      StoreLauncher.debugLauncher = (url) {
        calls++;
        return calls == 1 ? first.future : Future.value(true);
      };
      await pumpOverlay(tester);

      await tester.tap(find.byType(ElevatedButton)); // A: pending
      await tester.pump();
      await tapUpdate(tester); // B: opened
      first.complete(false); // A finishes late with a refusal
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text(message), findsNothing);
      expect(reports, isEmpty, reason: 'a superseded attempt is not reported');
    },
  );

  testWidgets('an empty URL does not call the launcher', (tester) async {
    StoreLauncher.debugLauncher = (url) async {
      launched.add(url);
      return true;
    };
    await pumpOverlay(tester, url: null);

    await tapUpdate(tester);

    expect(launched, isEmpty);
    expect(find.text(message), findsOneWidget);
    expect(reports, [(StoreLaunchResult.emptyUrl, 'force_update')]);
  });

  group('StoreLauncher', () {
    test('report values are closed and hold no URL', () {
      expect(StoreLaunchResult.values.map((r) => r.name), [
        'opened',
        'emptyUrl',
        'refused',
        'failed',
      ]);
    });

    test('an unexpected launcher error is not swallowed', () async {
      StoreLauncher.debugLauncher = (url) async => throw StateError('bug');
      await expectLater(StoreLauncher.open(storeUrl), throwsStateError);
    });
  });
}
