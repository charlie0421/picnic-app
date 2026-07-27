import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Builds the app-level language code for a [Locale] using the same
/// `lang` / `lang_COUNTRY` convention as [Setting.supportedLanguages].
String _appLanguageCode(Locale locale) {
  final country = locale.countryCode;
  return (country == null || country.isEmpty)
      ? locale.languageCode
      : '${locale.languageCode}_$country';
}

void main() {
  group('language label lookup is total over supported locales', () {
    // AppLocalizations.supportedLocales is generated from the ARB files, so it
    // grows automatically when a translator drops in a new locale. languageMap
    // is hand-maintained and does not. This pins the two together: a locale
    // added without a label fails here instead of at LoginPage build time.
    test('every AppLocalizations.supportedLocales entry has a real label', () {
      final missing = <String>[];

      for (final locale in AppLocalizations.supportedLocales) {
        final code = _appLanguageCode(locale);
        if (!languageMap.containsKey(canonicalLanguageCode(code))) {
          missing.add(code);
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'These supported locales have no entry in languageMap (and no '
            'canonical alias that does): $missing. Add a label to languageMap '
            'in constants.dart, or map the code to a regional variant in '
            'canonicalLanguageCode().',
      );
    });

    test('every Setting.supportedLanguages code has a real label', () {
      // Setting.load() accepts and stores any code in supportedLanguages, and
      // AppSetting.setLanguage() does not validate at all, so every one of
      // these can end up in appSettingState.language and must be renderable.
      for (final code in Setting.supportedLanguages) {
        expect(
          languageMap.containsKey(canonicalLanguageCode(code)),
          isTrue,
          reason: '"$code" is storable but has no display label',
        );
      }
    });

    test('languageLabel never returns an empty string', () {
      for (final locale in AppLocalizations.supportedLocales) {
        expect(languageLabel(_appLanguageCode(locale)), isNotEmpty);
      }
    });

    test('bare zh / bn resolve to their regional labels', () {
      // Matches the migration Setting.load() already performs on stored values.
      expect(canonicalLanguageCode('zh'), 'zh_CN');
      expect(canonicalLanguageCode('bn'), 'bn_BD');
      expect(languageLabel('zh'), languageMap['zh_CN']);
      expect(languageLabel('bn'), languageMap['bn_BD']);
    });

    test('regional and unknown codes pass through unchanged', () {
      expect(canonicalLanguageCode('zh_TW'), 'zh_TW');
      expect(canonicalLanguageCode('ko'), 'ko');
      expect(canonicalLanguageCode('pt'), 'pt');
      // Last-resort fallback: never throws, never renders blank.
      expect(languageLabel('pt'), 'pt');
    });
  });

  group('LoginPage renders a language label for every supported locale', () {
    late void Function() restore;

    setUp(() {
      initTestColors();
      setupMockSupabase({});
      restore = suppressImageErrors();
    });

    tearDown(() {
      restore();
      tearDownMockSupabase();
    });

    Future<void> pumpLoginPageWithLanguage(
      WidgetTester tester,
      String language,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          setting: Setting(language: language),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
    }

    // Regression: languageMap has 12 keys, AppLocalizations.supportedLocales
    // has 14 (it also carries bare `zh` and bare `bn`). The selector used to do
    // `languageMap[appSettingState.language]!`, so either bare code threw a
    // null-check error and replaced the whole login screen with an ErrorWidget.
    for (final entry in const {'zh': 'zh_CN', 'bn': 'bn_BD'}.entries) {
      testWidgets('language "${entry.key}" does not crash the login screen',
          (WidgetTester tester) async {
        await pumpLoginPageWithLanguage(tester, entry.key);

        expect(
          find.byType(ErrorWidget),
          findsNothing,
          reason: 'LoginPage build threw for language "${entry.key}"',
        );
        expect(find.byType(LoginPage), findsOneWidget);
        // And the label is meaningful, not the raw code.
        expect(find.text(languageMap[entry.value]!), findsOneWidget);
        expect(find.text(entry.key), findsNothing);
      });
    }

    // One case per generated locale, so adding a locale to the ARB set
    // automatically adds a render case for it.
    for (final locale in AppLocalizations.supportedLocales) {
      final code = _appLanguageCode(locale);
      testWidgets('supported locale "$code" renders a label', (
        WidgetTester tester,
      ) async {
        await pumpLoginPageWithLanguage(tester, code);

        expect(
          find.byType(ErrorWidget),
          findsNothing,
          reason: 'LoginPage build threw for language "$code"',
        );
        expect(
          find.text(languageLabel(code)),
          findsOneWidget,
          reason: 'no language label rendered for "$code"',
        );
      });
    }
  });
}
