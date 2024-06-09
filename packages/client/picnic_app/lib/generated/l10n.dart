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

  /// `구독`
  String get nav_subscription {
    return Intl.message(
      '구독',
      name: 'nav_subscription',
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

  /// `Celeb Gallery.`
  String get label_celeb_gallery {
    return Intl.message(
      'Celeb Gallery.',
      name: 'label_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Chance to win a random image`
  String get label_draw_image {
    return Intl.message(
      'Chance to win a random image',
      name: 'label_draw_image',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed ownership of 1 image from the entire gallery`
  String get text_draw_image {
    return Intl.message(
      'Confirmed ownership of 1 image from the entire gallery',
      name: 'text_draw_image',
      desc: '',
      args: [],
    );
  }

  /// `Articles`
  String get label_gallery_tab_article {
    return Intl.message(
      'Articles',
      name: 'label_gallery_tab_article',
      desc: '',
      args: [],
    );
  }

  /// `Chat`
  String get label_gallery_tab_chat {
    return Intl.message(
      'Chat',
      name: 'label_gallery_tab_chat',
      desc: '',
      args: [],
    );
  }

  /// `Replying to a reply`
  String get label_reply {
    return Intl.message(
      'Replying to a reply',
      name: 'label_reply',
      desc: '',
      args: [],
    );
  }

  /// `{day} days ago`
  String label_time_ago_day(Object day) {
    return Intl.message(
      '$day days ago',
      name: 'label_time_ago_day',
      desc: '',
      args: [day],
    );
  }

  /// `{hour} hours ago`
  String label_time_ago_hour(Object hour) {
    return Intl.message(
      '$hour hours ago',
      name: 'label_time_ago_hour',
      desc: '',
      args: [hour],
    );
  }

  /// `{minute} minutes ago`
  String label_time_ago_minute(Object minute) {
    return Intl.message(
      '$minute minutes ago',
      name: 'label_time_ago_minute',
      desc: '',
      args: [minute],
    );
  }

  /// `Just a moment ago`
  String get label_time_ago_right_now {
    return Intl.message(
      'Just a moment ago',
      name: 'label_time_ago_right_now',
      desc: '',
      args: [],
    );
  }

  /// `More comments`
  String get label_read_more_comment {
    return Intl.message(
      'More comments',
      name: 'label_read_more_comment',
      desc: '',
      args: [],
    );
  }

  /// `Make a report`
  String get label_title_report {
    return Intl.message(
      'Make a report',
      name: 'label_title_report',
      desc: '',
      args: [],
    );
  }

  /// `Want to report?`
  String get message_report_confirm {
    return Intl.message(
      'Want to report?',
      name: 'message_report_confirm',
      desc: '',
      args: [],
    );
  }

  /// `The report is complete.`
  String get message_report_ok {
    return Intl.message(
      'The report is complete.',
      name: 'message_report_ok',
      desc: '',
      args: [],
    );
  }

  /// `Comments`
  String get label_title_comment {
    return Intl.message(
      'Comments',
      name: 'label_title_comment',
      desc: '',
      args: [],
    );
  }

  /// `Leave a comment.`
  String get label_hint_comment {
    return Intl.message(
      'Leave a comment.',
      name: 'label_hint_comment',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get button_ok {
    return Intl.message(
      'Confirm',
      name: 'button_ok',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get button_cancel {
    return Intl.message(
      'Cancel',
      name: 'button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Libraries`
  String get label_library_tab_library {
    return Intl.message(
      'Libraries',
      name: 'label_library_tab_library',
      desc: '',
      args: [],
    );
  }

  /// `PRAME`
  String get label_library_tab_pic {
    return Intl.message(
      'PRAME',
      name: 'label_library_tab_pic',
      desc: '',
      args: [],
    );
  }

  /// `AI Photos`
  String get label_library_tab_ai_photo {
    return Intl.message(
      'AI Photos',
      name: 'label_library_tab_ai_photo',
      desc: '',
      args: [],
    );
  }

  /// `Be the first to comment!`
  String get label_article_comment_empty {
    return Intl.message(
      'Be the first to comment!',
      name: 'label_article_comment_empty',
      desc: '',
      args: [],
    );
  }

  /// `Save the library`
  String get label_library_save {
    return Intl.message(
      'Save the library',
      name: 'label_library_save',
      desc: '',
      args: [],
    );
  }

  /// `Add a new album`
  String get label_album_add {
    return Intl.message(
      'Add a new album',
      name: 'label_album_add',
      desc: '',
      args: [],
    );
  }

  /// `Add a new album`
  String get title_dialog_library_add {
    return Intl.message(
      'Add a new album',
      name: 'title_dialog_library_add',
      desc: '',
      args: [],
    );
  }

  /// `Album name`
  String get hint_library_add {
    return Intl.message(
      'Album name',
      name: 'hint_library_add',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get button_complete {
    return Intl.message(
      'Done',
      name: 'button_complete',
      desc: '',
      args: [],
    );
  }

  /// `vote`
  String get label_vote_screen_title {
    return Intl.message(
      'vote',
      name: 'label_vote_screen_title',
      desc: '',
      args: [],
    );
  }

  /// `birthday vote`
  String get label_vote_tab_birthday {
    return Intl.message(
      'birthday vote',
      name: 'label_vote_tab_birthday',
      desc: '',
      args: [],
    );
  }

  /// `P-RAME Voting`
  String get label_vote_tab_pic {
    return Intl.message(
      'P-RAME Voting',
      name: 'label_vote_tab_pic',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get nav_setting {
    return Intl.message(
      'Settings',
      name: 'nav_setting',
      desc: '',
      args: [],
    );
  }

  /// `투표하기`
  String get page_title_vote_detail {
    return Intl.message(
      '투표하기',
      name: 'page_title_vote_detail',
      desc: '',
      args: [],
    );
  }

  /// `마이페이지`
  String get page_title_mypage {
    return Intl.message(
      '마이페이지',
      name: 'page_title_mypage',
      desc: '',
      args: [],
    );
  }

  /// `환경설정`
  String get page_title_setting {
    return Intl.message(
      '환경설정',
      name: 'page_title_setting',
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
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
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
