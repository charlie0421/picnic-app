import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_consent.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/shortform_playback_consent_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the disclosed optional control grants and revokes measurement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final consent = ShortformPlaybackConsent();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShortformPlaybackConsentTile(
            ownerUserId: 'owner',
            consent: consent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shortform viewing analysis (optional)'), findsOneWidget);
    expect(find.textContaining('Ad rewards are unaffected.'), findsOneWidget);
    expect(
      find.textContaining('until the app restarts or for 24 hours'),
      findsOneWidget,
    );
    expect(consent.isAllowed('owner'), false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(consent.isAllowed('owner'), true);
    expect(consent.isAllowed('other'), false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(consent.isAllowed('owner'), false);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('localized disclosure and save failure for $locale', (
      tester,
    ) async {
      final consent = ShortformPlaybackConsent(
        preferences: () async => throw StateError('unavailable'),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ShortformPlaybackConsentTile(
              ownerUserId: 'owner',
              consent: consent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ShortformPlaybackConsentTile));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.shortform_playback_consent_title), findsOneWidget);
      expect(
        find.text(l10n.shortform_playback_consent_description),
        findsOneWidget,
      );
      if (locale.languageCode != 'en') {
        expect(
          find.text('Shortform viewing analysis (optional)'),
          findsNothing,
        );
      }
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(l10n.shortform_playback_consent_error),
        findsOneWidget,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        false,
      );
      expect(consent.isAllowed('owner'), false);
    });
  }

  testWidgets('the visible control turns off when session consent expires', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var now = Duration.zero;
    final consent = ShortformPlaybackConsent(elapsed: () => now);
    await consent.setAllowed('owner', true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShortformPlaybackConsentTile(
            ownerUserId: 'owner',
            consent: consent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      true,
    );
    now = const Duration(hours: 24);
    await tester.pump(const Duration(hours: 24));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'account replacement clears busy state and ignores a stale save',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final first = Completer<SharedPreferences>();
      final consent = ShortformPlaybackConsent(preferences: () => first.future);
      Widget page(String owner) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShortformPlaybackConsentTile(
            ownerUserId: owner,
            consent: consent,
          ),
        ),
      );
      await tester.pumpWidget(page('owner-a'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pumpWidget(page('owner-b'));
      await tester.pump();
      var tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, false);
      expect(tile.onChanged, isNotNull);
      first.complete(await SharedPreferences.getInstance());
      await tester.pumpAndSettle();
      tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, false);
      expect(consent.isAllowed('owner-b'), false);
    },
  );
}
