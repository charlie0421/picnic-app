import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/l10n/app_localizations_bn.dart';
import 'package:picnic_lib/l10n/app_localizations_en.dart';
import 'package:picnic_lib/l10n/app_localizations_es.dart';
import 'package:picnic_lib/l10n/app_localizations_fil.dart';
import 'package:picnic_lib/l10n/app_localizations_id.dart';
import 'package:picnic_lib/l10n/app_localizations_ja.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/l10n/app_localizations_my.dart';
import 'package:picnic_lib/l10n/app_localizations_th.dart';
import 'package:picnic_lib/l10n/app_localizations_vi.dart';
import 'package:picnic_lib/l10n/app_localizations_zh.dart';

void main() {
  group('_AppLocalizationsDelegate', () {
    test('isSupported returns true for all supported language codes', () {
      final delegate = AppLocalizations.delegate;
      for (final code in [
        'bn', 'en', 'es', 'fil', 'id', 'ja', 'ko', 'my', 'th', 'vi', 'zh'
      ]) {
        expect(delegate.isSupported(Locale(code)), isTrue,
            reason: '$code should be supported');
      }
    });

    test('isSupported returns false for unsupported language codes', () {
      final delegate = AppLocalizations.delegate;
      for (final code in ['fr', 'de', 'ru', 'pt', 'ar', 'hi']) {
        expect(delegate.isSupported(Locale(code)), isFalse,
            reason: '$code should not be supported');
      }
    });

    test('shouldReload returns false', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.shouldReload(AppLocalizations.delegate), isFalse);
    });

    test('load returns SynchronousFuture', () {
      final delegate = AppLocalizations.delegate;
      final future = delegate.load(const Locale('ko'));
      // SynchronousFuture completes synchronously
      expect(future, isA<Future<AppLocalizations>>());
    });

    test('load resolves each supported locale', () async {
      final delegate = AppLocalizations.delegate;

      expect(await delegate.load(const Locale('ko')), isA<AppLocalizationsKo>());
      expect(await delegate.load(const Locale('en')), isA<AppLocalizationsEn>());
      expect(await delegate.load(const Locale('ja')), isA<AppLocalizationsJa>());
      expect(await delegate.load(const Locale('es')), isA<AppLocalizationsEs>());
      expect(await delegate.load(const Locale('zh')), isA<AppLocalizationsZh>());
      expect(await delegate.load(const Locale('id')), isA<AppLocalizationsId>());
      expect(await delegate.load(const Locale('th')), isA<AppLocalizationsTh>());
      expect(await delegate.load(const Locale('vi')), isA<AppLocalizationsVi>());
      expect(await delegate.load(const Locale('my')), isA<AppLocalizationsMy>());
      expect(await delegate.load(const Locale('bn')), isA<AppLocalizationsBn>());
      expect(await delegate.load(const Locale('fil')), isA<AppLocalizationsFil>());
    });
  });

  group('lookupAppLocalizations', () {
    test('returns correct type for each base locale', () {
      expect(lookupAppLocalizations(const Locale('ko')), isA<AppLocalizationsKo>());
      expect(lookupAppLocalizations(const Locale('en')), isA<AppLocalizationsEn>());
      expect(lookupAppLocalizations(const Locale('es')), isA<AppLocalizationsEs>());
      expect(lookupAppLocalizations(const Locale('fil')), isA<AppLocalizationsFil>());
      expect(lookupAppLocalizations(const Locale('id')), isA<AppLocalizationsId>());
      expect(lookupAppLocalizations(const Locale('ja')), isA<AppLocalizationsJa>());
      expect(lookupAppLocalizations(const Locale('my')), isA<AppLocalizationsMy>());
      expect(lookupAppLocalizations(const Locale('th')), isA<AppLocalizationsTh>());
      expect(lookupAppLocalizations(const Locale('vi')), isA<AppLocalizationsVi>());
      expect(lookupAppLocalizations(const Locale('bn')), isA<AppLocalizationsBn>());
      expect(lookupAppLocalizations(const Locale('zh')), isA<AppLocalizationsZh>());
    });

    test('returns bn_BD variant for Locale(bn, BD)', () {
      final l10n = lookupAppLocalizations(
          const Locale.fromSubtags(languageCode: 'bn', countryCode: 'BD'));
      expect(l10n, isA<AppLocalizationsBn>());
      expect(l10n, isA<AppLocalizationsBnBd>());
    });

    test('returns zh_CN variant for Locale(zh, CN)', () {
      final l10n = lookupAppLocalizations(
          const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'));
      expect(l10n, isA<AppLocalizationsZh>());
      expect(l10n, isA<AppLocalizationsZhCn>());
    });

    test('returns zh_TW variant for Locale(zh, TW)', () {
      final l10n = lookupAppLocalizations(
          const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'));
      expect(l10n, isA<AppLocalizationsZh>());
      expect(l10n, isA<AppLocalizationsZhTw>());
    });

    test('bn with unknown country code falls through to base bn', () {
      final l10n = lookupAppLocalizations(
          const Locale.fromSubtags(languageCode: 'bn', countryCode: 'US'));
      expect(l10n, isA<AppLocalizationsBn>());
    });

    test('zh with unknown country code falls through to base zh', () {
      final l10n = lookupAppLocalizations(
          const Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'));
      expect(l10n, isA<AppLocalizationsZh>());
    });

    test('throws FlutterError for unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });

    test('throws FlutterError for unsupported locale with country code', () {
      expect(
        () => lookupAppLocalizations(
            const Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR')),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('AppLocalizations.supportedLocales', () {
    test('has 14 supported locales', () {
      expect(AppLocalizations.supportedLocales.length, 14);
    });

    test('contains bn and bn_BD', () {
      expect(
          AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == 'bn' && l.countryCode == null),
          isTrue);
      expect(
          AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == 'bn' && l.countryCode == 'BD'),
          isTrue);
    });

    test('contains zh, zh_CN, and zh_TW', () {
      expect(
          AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == 'zh' && l.countryCode == null),
          isTrue);
      expect(
          AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == 'zh' && l.countryCode == 'CN'),
          isTrue);
      expect(
          AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == 'zh' && l.countryCode == 'TW'),
          isTrue);
    });
  });

  group('AppLocalizations.localizationsDelegates', () {
    test('contains 4 delegates', () {
      expect(AppLocalizations.localizationsDelegates.length, 4);
    });

    test('first delegate is AppLocalizations.delegate', () {
      expect(
          AppLocalizations.localizationsDelegates.first, AppLocalizations.delegate);
    });
  });

  group('AppLocalizations.of integration', () {
    testWidgets('resolves Korean localizations from context', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isA<AppLocalizationsKo>());
      expect(l10n.localeName, 'ko');
    });

    testWidgets('resolves English localizations from context', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isA<AppLocalizationsEn>());
      expect(l10n.localeName, 'en');
    });

    testWidgets('resolves zh_CN localizations from context', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(
              languageCode: 'zh', countryCode: 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isA<AppLocalizationsZhCn>());
    });

    testWidgets('resolves bn_BD localizations from context', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(
              languageCode: 'bn', countryCode: 'BD'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isA<AppLocalizationsBnBd>());
    });
  });
}
