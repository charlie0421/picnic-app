// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Home`
  String get nav_home {
    return Intl.message(
      'Home',
      name: 'nav_home',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get nav_gallery {
    return Intl.message(
      'Gallery',
      name: 'nav_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Library`
  String get nav_library {
    return Intl.message(
      'Library',
      name: 'nav_library',
      desc: '',
      args: [],
    );
  }

  /// `Purchases`
  String get nav_purchases {
    return Intl.message(
      'Purchases',
      name: 'nav_purchases',
      desc: '',
      args: [],
    );
  }

  /// `Ads`
  String get nav_ads {
    return Intl.message(
      'Ads',
      name: 'nav_ads',
      desc: '',
      args: [],
    );
  }

  /// `My Purchases`
  String get mypage_purchases {
    return Intl.message(
      'My Purchases',
      name: 'mypage_purchases',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get mypage_setting {
    return Intl.message(
      'Settings',
      name: 'mypage_setting',
      desc: '',
      args: [],
    );
  }

  /// `Subscription Info`
  String get mypage_subscription {
    return Intl.message(
      'Subscription Info',
      name: 'mypage_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Comment Management`
  String get mypage_comment {
    return Intl.message(
      'Comment Management',
      name: 'mypage_comment',
      desc: '',
      args: [],
    );
  }

  /// `Language Settings`
  String get mypage_language {
    return Intl.message(
      'Language Settings',
      name: 'mypage_language',
      desc: '',
      args: [],
    );
  }

  /// `Language selection`
  String get title_select_language {
    return Intl.message(
      'Language selection',
      name: 'title_select_language',
      desc: '',
      args: [],
    );
  }

  /// `Current language`
  String get label_current_language {
    return Intl.message(
      'Current language',
      name: 'label_current_language',
      desc: '',
      args: [],
    );
  }

  /// `My Celeb`
  String get lable_my_celeb {
    return Intl.message(
      'My Celeb',
      name: 'lable_my_celeb',
      desc: '',
      args: [],
    );
  }

  /// `Celebrity recommendations`
  String get label_celeb_recommend {
    return Intl.message(
      'Celebrity recommendations',
      name: 'label_celeb_recommend',
      desc: '',
      args: [],
    );
  }

  /// `Search for celebrities.`
  String get text_hint_search {
    return Intl.message(
      'Search for celebrities.',
      name: 'text_hint_search',
      desc: '',
      args: [],
    );
  }

  /// `You can add up to 5 My Celebrities.`
  String get toast_max_5_celeb {
    return Intl.message(
      'You can add up to 5 My Celebrities.',
      name: 'toast_max_5_celeb',
      desc: '',
      args: [],
    );
  }

  /// `Go to the Celebrity Gallery`
  String get label_moveto_celeb_gallery {
    return Intl.message(
      'Go to the Celebrity Gallery',
      name: 'label_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Navigates to the selected celebrity's home.`
  String get text_moveto_celeb_gallery {
    return Intl.message(
      'Navigates to the selected celebrity\'s home.',
      name: 'text_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Viewing ads and collecting random images.`
  String get text_ads_random {
    return Intl.message(
      'Viewing ads and collecting random images.',
      name: 'text_ads_random',
      desc: '',
      args: [],
    );
  }

  /// `Find more celebrities`
  String get label_find_celeb {
    return Intl.message(
      'Find more celebrities',
      name: 'label_find_celeb',
      desc: '',
      args: [],
    );
  }

  /// `You don't have any celebrities bookmarked yet!.`
  String get label_no_celeb {
    return Intl.message(
      'You don\'t have any celebrities bookmarked yet!.',
      name: 'label_no_celeb',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
