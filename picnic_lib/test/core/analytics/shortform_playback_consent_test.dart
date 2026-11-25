import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Exercise native write rejection without changing the production storage API.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
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
      expect(reloaded.isAllowed('owner'), false);
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

  test(
    'failed withdrawal cannot restore a legacy opt-in after restart',
    () async {
      var storageFails = false;
      final consent = ShortformPlaybackConsent(
        preferences: () async {
          if (storageFails) throw StateError('disk unavailable');
          return SharedPreferences.getInstance();
        },
      );
      expect(await consent.setAllowed('owner', true), true);
      final prefs = await SharedPreferences.getInstance();
      // A prior app version may have left an affirmative value on disk.
      await prefs.setBool(ShortformPlaybackConsent.storageKey('owner'), true);
      storageFails = true;
      expect(await consent.setAllowed('owner', false), false);
      expect(consent.isAllowed('owner'), false);
      await consent.load('owner');
      expect(consent.isAllowed('owner'), false);
      final restarted = ShortformPlaybackConsent();
      await restarted.load('owner');
      expect(restarted.isAllowed('owner'), false);
      storageFails = false;
      expect(await consent.setAllowed('owner', false), true);
      expect(
        prefs.getBool(ShortformPlaybackConsent.storageKey('owner')),
        false,
      );
    },
  );

  test(
    'positive consent is never persisted for a future app session',
    () async {
      final consent = ShortformPlaybackConsent();
      expect(await consent.setAllowed('owner', true), true);
      expect(consent.isAllowed('owner'), true);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(ShortformPlaybackConsent.storageKey('owner')),
        false,
      );
    },
  );

  test(
    'session opt-in expires after 24 hours without being renewed by load',
    () async {
      var now = Duration.zero;
      final consent = ShortformPlaybackConsent(elapsed: () => now);
      expect(await consent.setAllowed('owner', true), true);
      now = const Duration(hours: 23, minutes: 59);
      await consent.load('owner');
      expect(consent.isAllowed('owner'), true);
      now = const Duration(hours: 24);
      expect(consent.isAllowed('owner'), false);
      expect(await consent.setAllowed('owner', true), true);
      expect(consent.isAllowed('owner'), true);
    },
  );

  test('native false write result cannot resurrect a disk grant', () async {
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    final store = _RejectWritesStore();
    SharedPreferencesStorePlatform.instance = store;
    final consent = ShortformPlaybackConsent();
    expect(await consent.setAllowed('owner', true), true);
    const diskKey = 'flutter.shortform_playback_analysis_v1:owner';
    await store.setValue('Bool', diskKey, true);
    store.reject = true;
    expect(await consent.setAllowed('owner', false), false);
    expect(consent.isAllowed('owner'), false);
    expect((await store.getAll())[diskKey], true);
    final restarted = ShortformPlaybackConsent();
    await restarted.load('owner');
    expect(restarted.isAllowed('owner'), false);
    expect(await restarted.setAllowed('owner', true), false);
    expect(restarted.isAllowed('owner'), false);
  });

  test('a late enable completion cannot undo a newer withdrawal', () async {
    final first = Completer<SharedPreferences>();
    var calls = 0;
    final consent = ShortformPlaybackConsent(
      preferences: () =>
          ++calls == 1 ? first.future : SharedPreferences.getInstance(),
    );
    final enabling = consent.setAllowed('owner', true);
    expect(await consent.setAllowed('owner', false), true);
    first.complete(await SharedPreferences.getInstance());
    expect(await enabling, false);
    expect(consent.isAllowed('owner'), false);
    final restarted = ShortformPlaybackConsent();
    await restarted.load('owner');
    expect(restarted.isAllowed('owner'), false);
  });
}

class _RejectWritesStore extends InMemorySharedPreferencesStore {
  _RejectWritesStore() : super.empty();
  bool reject = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      reject ? Future.value(false) : super.setValue(valueType, key, value);
}
