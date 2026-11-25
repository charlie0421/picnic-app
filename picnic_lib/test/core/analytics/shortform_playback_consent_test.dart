import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'missing selection is off and explicit opt-in is scoped to one owner',
    () async {
      final consent = ShortformPlaybackConsent();
      await consent.load('owner');
      expect(consent.isAllowed('owner'), false);
      expect(await consent.setAllowed('owner', true), true);
      expect(consent.isAllowed('owner'), true);
      expect(consent.isAllowed('other'), false);
      final reloaded = ShortformPlaybackConsent();
      await reloaded.load('owner');
      expect(reloaded.isAllowed('owner'), true);
      await reloaded.setAllowed('owner', false);
      expect(reloaded.isAllowed('owner'), false);
    },
  );
  test('storage failure never enables measurement', () async {
    final consent = ShortformPlaybackConsent(
      preferences: () async => throw StateError('unavailable'),
    );
    await consent.load('owner');
    expect(await consent.setAllowed('owner', true), false);
    expect(consent.isAllowed('owner'), false);
  });
}
