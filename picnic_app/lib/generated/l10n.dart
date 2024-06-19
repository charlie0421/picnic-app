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

  /// `Subscription`
  String get nav_subscription {
    return Intl.message(
      'Subscription',
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

  /// `Frame`
  String get label_library_tab_pic {
    return Intl.message(
      'Frame',
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

  /// `Vote`
  String get page_title_vote_detail {
    return Intl.message(
      'Vote',
      name: 'page_title_vote_detail',
      desc: '',
      args: [],
    );
  }

  /// `My Page`
  String get page_title_mypage {
    return Intl.message(
      'My Page',
      name: 'page_title_mypage',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get page_title_setting {
    return Intl.message(
      'Settings',
      name: 'page_title_setting',
      desc: '',
      args: [],
    );
  }

  /// `Vote`
  String get nav_vote {
    return Intl.message(
      'Vote',
      name: 'nav_vote',
      desc: '',
      args: [],
    );
  }

  /// `PicChart`
  String get nav_picchart {
    return Intl.message(
      'PicChart',
      name: 'nav_picchart',
      desc: '',
      args: [],
    );
  }

  /// `Media`
  String get nav_media {
    return Intl.message(
      'Media',
      name: 'nav_media',
      desc: '',
      args: [],
    );
  }

  /// `Store`
  String get nav_store {
    return Intl.message(
      'Store',
      name: 'nav_store',
      desc: '',
      args: [],
    );
  }

  /// `Notice`
  String get label_mypage_notice {
    return Intl.message(
      'Notice',
      name: 'label_mypage_notice',
      desc: '',
      args: [],
    );
  }

  /// `Charge History`
  String get label_mypage_charge_history {
    return Intl.message(
      'Charge History',
      name: 'label_mypage_charge_history',
      desc: '',
      args: [],
    );
  }

  /// `Customer Center`
  String get label_mypage_customer_center {
    return Intl.message(
      'Customer Center',
      name: 'label_mypage_customer_center',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get label_mypage_setting {
    return Intl.message(
      'Settings',
      name: 'label_mypage_setting',
      desc: '',
      args: [],
    );
  }

  /// `Vote History`
  String get label_mypage_vote_history {
    return Intl.message(
      'Vote History',
      name: 'label_mypage_vote_history',
      desc: '',
      args: [],
    );
  }

  /// `My Star`
  String get label_mypage_mystar {
    return Intl.message(
      'My Star',
      name: 'label_mypage_mystar',
      desc: '',
      args: [],
    );
  }

  /// `Membership History`
  String get label_mypage_membership_history {
    return Intl.message(
      'Membership History',
      name: 'label_mypage_membership_history',
      desc: '',
      args: [],
    );
  }

  /// `Alarm`
  String get label_setting_alarm {
    return Intl.message(
      'Alarm',
      name: 'label_setting_alarm',
      desc: '',
      args: [],
    );
  }

  /// `Push Notifications`
  String get label_setting_push_alarm {
    return Intl.message(
      'Push Notifications',
      name: 'label_setting_push_alarm',
      desc: '',
      args: [],
    );
  }

  /// `Event Notifications`
  String get label_setting_event_alarm {
    return Intl.message(
      'Event Notifications',
      name: 'label_setting_event_alarm',
      desc: '',
      args: [],
    );
  }

  /// `Events & activities`
  String get label_setting_event_alarm_desc {
    return Intl.message(
      'Events & activities',
      name: 'label_setting_event_alarm_desc',
      desc: '',
      args: [],
    );
  }

  /// `Language Settings`
  String get label_setting_language {
    return Intl.message(
      'Language Settings',
      name: 'label_setting_language',
      desc: '',
      args: [],
    );
  }

  /// `Manage Storage`
  String get label_setting_storage {
    return Intl.message(
      'Manage Storage',
      name: 'label_setting_storage',
      desc: '',
      args: [],
    );
  }

  /// `Clear Cache`
  String get label_setting_remove_cache {
    return Intl.message(
      'Clear Cache',
      name: 'label_setting_remove_cache',
      desc: '',
      args: [],
    );
  }

  /// `App Info`
  String get label_setting_appinfo {
    return Intl.message(
      'App Info',
      name: 'label_setting_appinfo',
      desc: '',
      args: [],
    );
  }

  /// `Current Version`
  String get label_setting_current_version {
    return Intl.message(
      'Current Version',
      name: 'label_setting_current_version',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get label_setting_update {
    return Intl.message(
      'Update',
      name: 'label_setting_update',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get label_tabbar_picchart_daily {
    return Intl.message(
      'Daily',
      name: 'label_tabbar_picchart_daily',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get label_tabbar_picchart_weekly {
    return Intl.message(
      'Weekly',
      name: 'label_tabbar_picchart_weekly',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get label_tabbar_picchart_monthly {
    return Intl.message(
      'Monthly',
      name: 'label_tabbar_picchart_monthly',
      desc: '',
      args: [],
    );
  }

  /// `Reward List`
  String get label_vote_reward_list {
    return Intl.message(
      'Reward List',
      name: 'label_vote_reward_list',
      desc: '',
      args: [],
    );
  }

  /// `Save to Gallery`
  String get label_pic_pic_save_gallery {
    return Intl.message(
      'Save to Gallery',
      name: 'label_pic_pic_save_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get button_pic_pic_save {
    return Intl.message(
      'Save',
      name: 'button_pic_pic_save',
      desc: '',
      args: [],
    );
  }

  /// `Initializing camera...`
  String get label_pic_pic_initializing_camera {
    return Intl.message(
      'Initializing camera...',
      name: 'label_pic_pic_initializing_camera',
      desc: '',
      args: [],
    );
  }

  /// `Synthesizing image...`
  String get label_pic_pic_synthesizing_image {
    return Intl.message(
      'Synthesizing image...',
      name: 'label_pic_pic_synthesizing_image',
      desc: '',
      args: [],
    );
  }

  /// `Saved successfully.`
  String get message_pic_pic_save_success {
    return Intl.message(
      'Saved successfully.',
      name: 'message_pic_pic_save_success',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save.`
  String get message_pic_pic_save_fail {
    return Intl.message(
      'Failed to save.',
      name: 'message_pic_pic_save_fail',
      desc: '',
      args: [],
    );
  }

  /// `Rank in the reward`
  String get text_vote_rank_in_reward {
    return Intl.message(
      'Rank in the reward',
      name: 'text_vote_rank_in_reward',
      desc: '',
      args: [],
    );
  }

  /// `Where is my bias?`
  String get text_vote_where_is_my_bias {
    return Intl.message(
      'Where is my bias?',
      name: 'text_vote_where_is_my_bias',
      desc: '',
      args: [],
    );
  }

  /// `Collecting votes`
  String get label_vote_vote_gather {
    return Intl.message(
      'Collecting votes',
      name: 'label_vote_vote_gather',
      desc: '',
      args: [],
    );
  }

  /// `In Progress`
  String get label_tabbar_vote_active {
    return Intl.message(
      'In Progress',
      name: 'label_tabbar_vote_active',
      desc: '',
      args: [],
    );
  }

  /// `End`
  String get label_tabbar_vote_end {
    return Intl.message(
      'End',
      name: 'label_tabbar_vote_end',
      desc: '',
      args: [],
    );
  }

  /// `Collecting votes`
  String get page_title_vote_gather {
    return Intl.message(
      'Collecting votes',
      name: 'page_title_vote_gather',
      desc: '',
      args: [],
    );
  }

  /// `Image cropping`
  String get label_pic_image_cropping {
    return Intl.message(
      'Image cropping',
      name: 'label_pic_image_cropping',
      desc: '',
      args: [],
    );
  }

  /// `th`
  String get text_vote_rank_surffix {
    return Intl.message(
      'th',
      name: 'text_vote_rank_surffix',
      desc: '',
      args: [],
    );
  }

  /// `1st`
  String get text_vote_1st {
    return Intl.message(
      '1st',
      name: 'text_vote_1st',
      desc: '',
      args: [],
    );
  }

  /// `2nd`
  String get text_vote_2nd {
    return Intl.message(
      '2nd',
      name: 'text_vote_2nd',
      desc: '',
      args: [],
    );
  }

  /// `3rd`
  String get text_vote_3rd {
    return Intl.message(
      '3rd',
      name: 'text_vote_3rd',
      desc: '',
      args: [],
    );
  }

  /// `Recharge`
  String get label_button_recharge {
    return Intl.message(
      'Recharge',
      name: 'label_button_recharge',
      desc: '',
      args: [],
    );
  }

  /// `Use all`
  String get label_checkbox_entire_use {
    return Intl.message(
      'Use all',
      name: 'label_checkbox_entire_use',
      desc: '',
      args: [],
    );
  }

  /// `Input`
  String get label_input_input {
    return Intl.message(
      'Input',
      name: 'label_input_input',
      desc: '',
      args: [],
    );
  }

  /// `Need to recharge`
  String get text_need_recharge {
    return Intl.message(
      'Need to recharge',
      name: 'text_need_recharge',
      desc: '',
      args: [],
    );
  }

  /// `Vote`
  String get label_button_vote {
    return Intl.message(
      'Vote',
      name: 'label_button_vote',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get label_button_clse {
    return Intl.message(
      'Close',
      name: 'label_button_clse',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get dialog_button_ok {
    return Intl.message(
      'OK',
      name: 'dialog_button_ok',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get dialog_button_cancel {
    return Intl.message(
      'Cancel',
      name: 'dialog_button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Vote failed`
  String get dialog_title_vote_fail {
    return Intl.message(
      'Vote failed',
      name: 'dialog_title_vote_fail',
      desc: '',
      args: [],
    );
  }

  /// `The amount of votes should not be 0.`
  String get text_dialog_vote_amount_should_not_zero {
    return Intl.message(
      'The amount of votes should not be 0.',
      name: 'text_dialog_vote_amount_should_not_zero',
      desc: '',
      args: [],
    );
  }

  /// `No search results.`
  String get text_no_search_result {
    return Intl.message(
      'No search results.',
      name: 'text_no_search_result',
      desc: '',
      args: [],
    );
  }

  /// `Buy Star Candy`
  String get label_tab_buy_star_candy {
    return Intl.message(
      'Buy Star Candy',
      name: 'label_tab_buy_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `Free Charging Station`
  String get label_tab_free_charge_station {
    return Intl.message(
      'Free Charging Station',
      name: 'label_tab_free_charge_station',
      desc: '',
      args: [],
    );
  }

  /// `Recent`
  String get label_dropdown_recent {
    return Intl.message(
      'Recent',
      name: 'label_dropdown_recent',
      desc: '',
      args: [],
    );
  }

  /// `Oldest`
  String get label_dropdown_oldest {
    return Intl.message(
      'Oldest',
      name: 'label_dropdown_oldest',
      desc: '',
      args: [],
    );
  }

  /// `Star Candy`
  String get text_star_candy {
    return Intl.message(
      'Star Candy',
      name: 'text_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `Vote complete`
  String get text_vote_complete {
    return Intl.message(
      'Vote complete',
      name: 'text_vote_complete',
      desc: '',
      args: [],
    );
  }

  /// `This time vote`
  String get text_this_time_vote {
    return Intl.message(
      'This time vote',
      name: 'text_this_time_vote',
      desc: '',
      args: [],
    );
  }

  /// `Save the voting paper`
  String get label_button_save_vote_paper {
    return Intl.message(
      'Save the voting paper',
      name: 'label_button_save_vote_paper',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get label_button_share {
    return Intl.message(
      'Share',
      name: 'label_button_share',
      desc: '',
      args: [],
    );
  }

  /// `Watch and charge`
  String get label_button_watch_and_charge {
    return Intl.message(
      'Watch and charge',
      name: 'label_button_watch_and_charge',
      desc: '',
      args: [],
    );
  }

  /// `Watch ads`
  String get label_watch_ads {
    return Intl.message(
      'Watch ads',
      name: 'label_watch_ads',
      desc: '',
      args: [],
    );
  }

  /// `Bonus`
  String get label_bonus {
    return Intl.message(
      'Bonus',
      name: 'label_bonus',
      desc: '',
      args: [],
    );
  }

  /// `Star Candy Usage Policy`
  String get text_star_candy_usage_policy_title {
    return Intl.message(
      'Star Candy Usage Policy',
      name: 'text_star_candy_usage_policy_title',
      desc: '',
      args: [],
    );
  }

  /// `*Bonuses will disappear the month after you earn them! ⓘ`
  String get text_star_candy_usage_policy_guide {
    return Intl.message(
      '*Bonuses will disappear the month after you earn them! ⓘ',
      name: 'text_star_candy_usage_policy_guide',
      desc: '',
      args: [],
    );
  }

  /// `### Expiration Date\n\n- Purchase Candy: None (unlimited)\n- Bonus Star Candy: Expires in batches on the 15th of the month after earned\n\n### Redeem Star Candy\n\n- Star Candies that are about to expire will be used first.\n- If they have the same expiration date, the earliest one will be used.`
  String get text_star_candy_usage_policy {
    return Intl.message(
      '### Expiration Date\n\n- Purchase Candy: None (unlimited)\n- Bonus Star Candy: Expires in batches on the 15th of the month after earned\n\n### Redeem Star Candy\n\n- Star Candies that are about to expire will be used first.\n- If they have the same expiration date, the earliest one will be used.',
      name: 'text_star_candy_usage_policy',
      desc: '',
      args: [],
    );
  }

  /// `Star Candy received`
  String get text_dialog_star_candy_received {
    return Intl.message(
      'Star Candy received',
      name: 'text_dialog_star_candy_received',
      desc: '',
      args: [],
    );
  }

  /// `*VAT included`
  String get text_purchase_vat_included {
    return Intl.message(
      '*VAT included',
      name: 'text_purchase_vat_included',
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
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
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
