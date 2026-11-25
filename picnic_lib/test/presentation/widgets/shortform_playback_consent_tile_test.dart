import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_consent.dart';
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
    expect(consent.isAllowed('owner'), false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(consent.isAllowed('owner'), true);
    expect(consent.isAllowed('other'), false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(consent.isAllowed('owner'), false);
  });
}
