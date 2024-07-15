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

  /// `Picnic`
  String get app_name {
    return Intl.message(
      'Picnic',
      name: 'app_name',
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

  /// `Done`
  String get button_complete {
    return Intl.message(
      'Done',
      name: 'button_complete',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get button_login {
    return Intl.message(
      'Sign in',
      name: 'button_login',
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

  /// `Save`
  String get button_pic_pic_save {
    return Intl.message(
      'Save',
      name: 'button_pic_pic_save',
      desc: '',
      args: [],
    );
  }

  /// `### Validity\n\n- Star Candies are valid for one year from the date of acquisition.\n\n### Earned Star Candy\n\nLogin: 1 per day\n- Votes: 1 per day\nStar Candy Purchases: None (unlimited)\nBonus Star Candy: Expires in batches on the 15th of the month after earned\n\n##### Redeem Star Candy\n\nStar Candies with an expiration date nearing the end of the month will be used first.\nIf they have the same expiration date, the earliest one will be used.`
  String get candy_usage_policy_contents {
    return Intl.message(
      '### Validity\n\n- Star Candies are valid for one year from the date of acquisition.\n\n### Earned Star Candy\n\nLogin: 1 per day\n- Votes: 1 per day\nStar Candy Purchases: None (unlimited)\nBonus Star Candy: Expires in batches on the 15th of the month after earned\n\n##### Redeem Star Candy\n\nStar Candies with an expiration date nearing the end of the month will be used first.\nIf they have the same expiration date, the earliest one will be used.',
      name: 'candy_usage_policy_contents',
      desc: '',
      args: [],
    );
  }

  /// `*Bonuses disappear the month after you earn them! ⓘ`
  String get candy_usage_policy_guide {
    return Intl.message(
      '*Bonuses disappear the month after you earn them! ⓘ',
      name: 'candy_usage_policy_guide',
      desc: '',
      args: [],
    );
  }

  /// `Stardust Usage Policy`
  String get candy_usage_policy_title {
    return Intl.message(
      'Stardust Usage Policy',
      name: 'candy_usage_policy_title',
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

  /// `Confirm`
  String get dialog_button_ok {
    return Intl.message(
      'Confirm',
      name: 'dialog_button_ok',
      desc: '',
      args: [],
    );
  }

  /// `All ads have been exhausted. Please try again next time.`
  String get dialog_content_ads_exhausted {
    return Intl.message(
      'All ads have been exhausted. Please try again next time.',
      name: 'dialog_content_ads_exhausted',
      desc: '',
      args: [],
    );
  }

  /// `Ads are loading.`
  String get dialog_content_ads_loading {
    return Intl.message(
      'Ads are loading.',
      name: 'dialog_content_ads_loading',
      desc: '',
      args: [],
    );
  }

  /// `The ad is reloading. Please try again in a moment.`
  String get dialog_content_ads_retrying {
    return Intl.message(
      'The ad is reloading. Please try again in a moment.',
      name: 'dialog_content_ads_retrying',
      desc: '',
      args: [],
    );
  }

  /// `Login required`
  String get dialog_content_login_required {
    return Intl.message(
      'Login required',
      name: 'dialog_content_login_required',
      desc: '',
      args: [],
    );
  }

  /// `The purchase failed.`
  String get dialog_purchases_fail {
    return Intl.message(
      'The purchase failed.',
      name: 'dialog_purchases_fail',
      desc: '',
      args: [],
    );
  }

  /// `Your purchase is complete.`
  String get dialog_purchases_success {
    return Intl.message(
      'Your purchase is complete.',
      name: 'dialog_purchases_success',
      desc: '',
      args: [],
    );
  }

  /// `Exhausted all ads`
  String get dialog_title_ads_exhausted {
    return Intl.message(
      'Exhausted all ads',
      name: 'dialog_title_ads_exhausted',
      desc: '',
      args: [],
    );
  }

  /// `Voting Failed`
  String get dialog_title_vote_fail {
    return Intl.message(
      'Voting Failed',
      name: 'dialog_title_vote_fail',
      desc: '',
      args: [],
    );
  }

  /// `Let me think about this one more time`
  String get dialog_withdraw_button_cancel {
    return Intl.message(
      'Let me think about this one more time',
      name: 'dialog_withdraw_button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Unsubscribing`
  String get dialog_withdraw_button_ok {
    return Intl.message(
      'Unsubscribing',
      name: 'dialog_withdraw_button_ok',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred during unsubscribe.`
  String get dialog_withdraw_error {
    return Intl.message(
      'An error occurred during unsubscribe.',
      name: 'dialog_withdraw_error',
      desc: '',
      args: [],
    );
  }

  /// `If you cancel your membership, any Star Candy you have on Picnic and your account information will be deleted immediately.`
  String get dialog_withdraw_message {
    return Intl.message(
      'If you cancel your membership, any Star Candy you have on Picnic and your account information will be deleted immediately.',
      name: 'dialog_withdraw_message',
      desc: '',
      args: [],
    );
  }

  /// `The unsubscribe was processed successfully.`
  String get dialog_withdraw_success {
    return Intl.message(
      'The unsubscribe was processed successfully.',
      name: 'dialog_withdraw_success',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to leave?`
  String get dialog_withdraw_title {
    return Intl.message(
      'Are you sure you want to leave?',
      name: 'dialog_withdraw_title',
      desc: '',
      args: [],
    );
  }

  /// `The membership information doesn't exist.`
  String get error_message_no_user {
    return Intl.message(
      'The membership information doesn\'t exist.',
      name: 'error_message_no_user',
      desc: '',
      args: [],
    );
  }

  /// `A member who has unsubscribed.`
  String get error_message_withdrawal {
    return Intl.message(
      'A member who has unsubscribed.',
      name: 'error_message_withdrawal',
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

  /// `Please enter a nickname.`
  String get hint_nickname_input {
    return Intl.message(
      'Please enter a nickname.',
      name: 'hint_nickname_input',
      desc: '',
      args: [],
    );
  }

  /// `The image has been saved.`
  String get image_save_success {
    return Intl.message(
      'The image has been saved.',
      name: 'image_save_success',
      desc: '',
      args: [],
    );
  }

  /// `Consent to the collection and use of personal information`
  String get label_agreement_privacy {
    return Intl.message(
      'Consent to the collection and use of personal information',
      name: 'label_agreement_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Accept the Terms of Use`
  String get label_agreement_terms {
    return Intl.message(
      'Accept the Terms of Use',
      name: 'label_agreement_terms',
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

  /// `Be the first to comment!`
  String get label_article_comment_empty {
    return Intl.message(
      'Be the first to comment!',
      name: 'label_article_comment_empty',
      desc: '',
      args: [],
    );
  }

  /// `Bonuses`
  String get label_bonus {
    return Intl.message(
      'Bonuses',
      name: 'label_bonus',
      desc: '',
      args: [],
    );
  }

  /// `Accept`
  String get label_button_agreement {
    return Intl.message(
      'Accept',
      name: 'label_button_agreement',
      desc: '',
      args: [],
    );
  }

  /// `关闭`
  String get label_button_clse {
    return Intl.message(
      '关闭',
      name: 'label_button_clse',
      desc: '',
      args: [],
    );
  }

  /// `Non-Consent`
  String get label_button_disagreement {
    return Intl.message(
      'Non-Consent',
      name: 'label_button_disagreement',
      desc: '',
      args: [],
    );
  }

  /// `Charging`
  String get label_button_recharge {
    return Intl.message(
      'Charging',
      name: 'label_button_recharge',
      desc: '',
      args: [],
    );
  }

  /// `Save your ballot`
  String get label_button_save_vote_paper {
    return Intl.message(
      'Save your ballot',
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

  /// `Vote`
  String get label_button_vote {
    return Intl.message(
      'Vote',
      name: 'label_button_vote',
      desc: '',
      args: [],
    );
  }

  /// `Viewing and charging for ads`
  String get label_button_watch_and_charge {
    return Intl.message(
      'Viewing and charging for ads',
      name: 'label_button_watch_and_charge',
      desc: '',
      args: [],
    );
  }

  /// `The Artist Asks You!`
  String get label_celeb_ask_to_you {
    return Intl.message(
      'The Artist Asks You!',
      name: 'label_celeb_ask_to_you',
      desc: '',
      args: [],
    );
  }

  /// `Artist Gallery`
  String get label_celeb_gallery {
    return Intl.message(
      'Artist Gallery',
      name: 'label_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Artist recommendations`
  String get label_celeb_recommend {
    return Intl.message(
      'Artist recommendations',
      name: 'label_celeb_recommend',
      desc: '',
      args: [],
    );
  }

  /// `Full Use`
  String get label_checkbox_entire_use {
    return Intl.message(
      'Full Use',
      name: 'label_checkbox_entire_use',
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

  /// `Chance to win a random image`
  String get label_draw_image {
    return Intl.message(
      'Chance to win a random image',
      name: 'label_draw_image',
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

  /// `Newest`
  String get label_dropdown_recent {
    return Intl.message(
      'Newest',
      name: 'label_dropdown_recent',
      desc: '',
      args: [],
    );
  }

  /// `Find more artists`
  String get label_find_celeb {
    return Intl.message(
      'Find more artists',
      name: 'label_find_celeb',
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

  /// `Leave a comment.`
  String get label_hint_comment {
    return Intl.message(
      'Leave a comment.',
      name: 'label_hint_comment',
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

  /// `Save the library`
  String get label_library_save {
    return Intl.message(
      'Save the library',
      name: 'label_library_save',
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

  /// `Libraries`
  String get label_library_tab_library {
    return Intl.message(
      'Libraries',
      name: 'label_library_tab_library',
      desc: '',
      args: [],
    );
  }

  /// `PIC`
  String get label_library_tab_pic {
    return Intl.message(
      'PIC',
      name: 'label_library_tab_pic',
      desc: '',
      args: [],
    );
  }

  /// `Go to the Artist Gallery`
  String get label_moveto_celeb_gallery {
    return Intl.message(
      'Go to the Artist Gallery',
      name: 'label_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Charges`
  String get label_mypage_charge_history {
    return Intl.message(
      'Charges',
      name: 'label_mypage_charge_history',
      desc: '',
      args: [],
    );
  }

  /// `Help Center`
  String get label_mypage_customer_center {
    return Intl.message(
      'Help Center',
      name: 'label_mypage_customer_center',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get label_mypage_logout {
    return Intl.message(
      'Log out',
      name: 'label_mypage_logout',
      desc: '',
      args: [],
    );
  }

  /// `Membership history`
  String get label_mypage_membership_history {
    return Intl.message(
      'Membership history',
      name: 'label_mypage_membership_history',
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

  /// `Announcements`
  String get label_mypage_notice {
    return Intl.message(
      'Announcements',
      name: 'label_mypage_notice',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get label_mypage_privacy_policy {
    return Intl.message(
      'Privacy Policy',
      name: 'label_mypage_privacy_policy',
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

  /// `Terms of Use`
  String get label_mypage_terms_of_use {
    return Intl.message(
      'Terms of Use',
      name: 'label_mypage_terms_of_use',
      desc: '',
      args: [],
    );
  }

  /// `Voting history`
  String get label_mypage_vote_history {
    return Intl.message(
      'Voting history',
      name: 'label_mypage_vote_history',
      desc: '',
      args: [],
    );
  }

  /// `Withdrawal`
  String get label_mypage_withdrawal {
    return Intl.message(
      'Withdrawal',
      name: 'label_mypage_withdrawal',
      desc: '',
      args: [],
    );
  }

  /// `No ads`
  String get label_no_ads {
    return Intl.message(
      'No ads',
      name: 'label_no_ads',
      desc: '',
      args: [],
    );
  }

  /// `You don't have any artists bookmarked yet!`
  String get label_no_celeb {
    return Intl.message(
      'You don\'t have any artists bookmarked yet!',
      name: 'label_no_celeb',
      desc: '',
      args: [],
    );
  }

  /// `Crop an image`
  String get label_pic_image_cropping {
    return Intl.message(
      'Crop an image',
      name: 'label_pic_image_cropping',
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

  /// `Save to Gallery`
  String get label_pic_pic_save_gallery {
    return Intl.message(
      'Save to Gallery',
      name: 'label_pic_pic_save_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Compositing an image...`
  String get label_pic_pic_synthesizing_image {
    return Intl.message(
      'Compositing an image...',
      name: 'label_pic_pic_synthesizing_image',
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

  /// `Reply`
  String get label_reply {
    return Intl.message(
      'Reply',
      name: 'label_reply',
      desc: '',
      args: [],
    );
  }

  /// `Retrying`
  String get label_retry {
    return Intl.message(
      'Retrying',
      name: 'label_retry',
      desc: '',
      args: [],
    );
  }

  /// `Accept the terms`
  String get label_screen_title_agreement {
    return Intl.message(
      'Accept the terms',
      name: 'label_screen_title_agreement',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get label_setting_alarm {
    return Intl.message(
      'Notifications',
      name: 'label_setting_alarm',
      desc: '',
      args: [],
    );
  }

  /// `App info`
  String get label_setting_appinfo {
    return Intl.message(
      'App info',
      name: 'label_setting_appinfo',
      desc: '',
      args: [],
    );
  }

  /// `Current version`
  String get label_setting_current_version {
    return Intl.message(
      'Current version',
      name: 'label_setting_current_version',
      desc: '',
      args: [],
    );
  }

  /// `Event notifications`
  String get label_setting_event_alarm {
    return Intl.message(
      'Event notifications',
      name: 'label_setting_event_alarm',
      desc: '',
      args: [],
    );
  }

  /// `Events and happenings.`
  String get label_setting_event_alarm_desc {
    return Intl.message(
      'Events and happenings.',
      name: 'label_setting_event_alarm_desc',
      desc: '',
      args: [],
    );
  }

  /// `Language settings`
  String get label_setting_language {
    return Intl.message(
      'Language settings',
      name: 'label_setting_language',
      desc: '',
      args: [],
    );
  }

  /// `Push notifications`
  String get label_setting_push_alarm {
    return Intl.message(
      'Push notifications',
      name: 'label_setting_push_alarm',
      desc: '',
      args: [],
    );
  }

  /// `Latest version`
  String get label_setting_recent_version {
    return Intl.message(
      'Latest version',
      name: 'label_setting_recent_version',
      desc: '',
      args: [],
    );
  }

  /// `Delete Cache`
  String get label_setting_remove_cache {
    return Intl.message(
      'Delete Cache',
      name: 'label_setting_remove_cache',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get label_setting_remove_cache_complete {
    return Intl.message(
      'Done',
      name: 'label_setting_remove_cache_complete',
      desc: '',
      args: [],
    );
  }

  /// `Manage storage`
  String get label_setting_storage {
    return Intl.message(
      'Manage storage',
      name: 'label_setting_storage',
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

  /// `Star Candy Pouch`
  String get label_star_candy_pouch {
    return Intl.message(
      'Star Candy Pouch',
      name: 'label_star_candy_pouch',
      desc: '',
      args: [],
    );
  }

  /// `Buy star candy`
  String get label_tab_buy_star_candy {
    return Intl.message(
      'Buy star candy',
      name: 'label_tab_buy_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `Free charging stations`
  String get label_tab_free_charge_station {
    return Intl.message(
      'Free charging stations',
      name: 'label_tab_free_charge_station',
      desc: '',
      args: [],
    );
  }

  /// `Daily charts`
  String get label_tabbar_picchart_daily {
    return Intl.message(
      'Daily charts',
      name: 'label_tabbar_picchart_daily',
      desc: '',
      args: [],
    );
  }

  /// `Monthly Charts`
  String get label_tabbar_picchart_monthly {
    return Intl.message(
      'Monthly Charts',
      name: 'label_tabbar_picchart_monthly',
      desc: '',
      args: [],
    );
  }

  /// `Weekly charts`
  String get label_tabbar_picchart_weekly {
    return Intl.message(
      'Weekly charts',
      name: 'label_tabbar_picchart_weekly',
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

  /// `Exit`
  String get label_tabbar_vote_end {
    return Intl.message(
      'Exit',
      name: 'label_tabbar_vote_end',
      desc: '',
      args: [],
    );
  }

  /// `{day}일 전`
  String label_time_ago_day(Object day) {
    return Intl.message(
      '$day일 전',
      name: 'label_time_ago_day',
      desc: '',
      args: [day],
    );
  }

  /// `{hour}시간 전`
  String label_time_ago_hour(Object hour) {
    return Intl.message(
      '$hour시간 전',
      name: 'label_time_ago_hour',
      desc: '',
      args: [hour],
    );
  }

  /// `{minute}분 전`
  String label_time_ago_minute(Object minute) {
    return Intl.message(
      '$minute분 전',
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

  /// `Comments`
  String get label_title_comment {
    return Intl.message(
      'Comments',
      name: 'label_title_comment',
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

  /// `Rewards list`
  String get label_vote_reward_list {
    return Intl.message(
      'Rewards list',
      name: 'label_vote_reward_list',
      desc: '',
      args: [],
    );
  }

  /// `Voting`
  String get label_vote_screen_title {
    return Intl.message(
      'Voting',
      name: 'label_vote_screen_title',
      desc: '',
      args: [],
    );
  }

  /// `Birthday polls`
  String get label_vote_tab_birthday {
    return Intl.message(
      'Birthday polls',
      name: 'label_vote_tab_birthday',
      desc: '',
      args: [],
    );
  }

  /// `PIC voting`
  String get label_vote_tab_pic {
    return Intl.message(
      'PIC voting',
      name: 'label_vote_tab_pic',
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

  /// `View ads`
  String get label_watch_ads {
    return Intl.message(
      'View ads',
      name: 'label_watch_ads',
      desc: '',
      args: [],
    );
  }

  /// `My Artists`
  String get lable_my_celeb {
    return Intl.message(
      'My Artists',
      name: 'lable_my_celeb',
      desc: '',
      args: [],
    );
  }

  /// `Acceptance of the terms is complete.`
  String get message_agreement_success {
    return Intl.message(
      'Acceptance of the terms is complete.',
      name: 'message_agreement_success',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred.`
  String get message_error_occurred {
    return Intl.message(
      'An error occurred.',
      name: 'message_error_occurred',
      desc: '',
      args: [],
    );
  }

  /// `Saving the image failed.`
  String get message_pic_pic_save_fail {
    return Intl.message(
      'Saving the image failed.',
      name: 'message_pic_pic_save_fail',
      desc: '',
      args: [],
    );
  }

  /// `The image has been saved.`
  String get message_pic_pic_save_success {
    return Intl.message(
      'The image has been saved.',
      name: 'message_pic_pic_save_success',
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

  /// `Manage comments`
  String get mypage_comment {
    return Intl.message(
      'Manage comments',
      name: 'mypage_comment',
      desc: '',
      args: [],
    );
  }

  /// `Language settings`
  String get mypage_language {
    return Intl.message(
      'Language settings',
      name: 'mypage_language',
      desc: '',
      args: [],
    );
  }

  /// `My purchases`
  String get mypage_purchases {
    return Intl.message(
      'My purchases',
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

  /// `Subscription information`
  String get mypage_subscription {
    return Intl.message(
      'Subscription information',
      name: 'mypage_subscription',
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

  /// `Gallery`
  String get nav_gallery {
    return Intl.message(
      'Gallery',
      name: 'nav_gallery',
      desc: '',
      args: [],
    );
  }

  /// `홈`
  String get nav_home {
    return Intl.message(
      '홈',
      name: 'nav_home',
      desc: '',
      args: [],
    );
  }

  /// `Libraries`
  String get nav_library {
    return Intl.message(
      'Libraries',
      name: 'nav_library',
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

  /// `PIC Charts`
  String get nav_picchart {
    return Intl.message(
      'PIC Charts',
      name: 'nav_picchart',
      desc: '',
      args: [],
    );
  }

  /// `Purchase`
  String get nav_purchases {
    return Intl.message(
      'Purchase',
      name: 'nav_purchases',
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

  /// `Shop`
  String get nav_store {
    return Intl.message(
      'Shop',
      name: 'nav_store',
      desc: '',
      args: [],
    );
  }

  /// `Subscriptions`
  String get nav_subscription {
    return Intl.message(
      'Subscriptions',
      name: 'nav_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Voting`
  String get nav_vote {
    return Intl.message(
      'Voting',
      name: 'nav_vote',
      desc: '',
      args: [],
    );
  }

  /// `20 characters or less, excluding special characters.`
  String get nickname_validation_error {
    return Intl.message(
      '20 characters or less, excluding special characters.',
      name: 'nickname_validation_error',
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

  /// `My profile`
  String get page_title_myprofile {
    return Intl.message(
      'My profile',
      name: 'page_title_myprofile',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get page_title_privacy {
    return Intl.message(
      'Privacy Policy',
      name: 'page_title_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Preferences`
  String get page_title_setting {
    return Intl.message(
      'Preferences',
      name: 'page_title_setting',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Use`
  String get page_title_terms_of_use {
    return Intl.message(
      'Terms of Use',
      name: 'page_title_terms_of_use',
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

  /// `Collecting votes`
  String get page_title_vote_gather {
    return Intl.message(
      'Collecting votes',
      name: 'page_title_vote_gather',
      desc: '',
      args: [],
    );
  }

  /// `Image sharing failed`
  String get share_image_fail {
    return Intl.message(
      'Image sharing failed',
      name: 'share_image_fail',
      desc: '',
      args: [],
    );
  }

  /// `Shared image successfully`
  String get share_image_success {
    return Intl.message(
      'Shared image successfully',
      name: 'share_image_success',
      desc: '',
      args: [],
    );
  }

  /// `I don't have the Twitter app`
  String get share_no_twitter {
    return Intl.message(
      'I don\'t have the Twitter app',
      name: 'share_no_twitter',
      desc: '',
      args: [],
    );
  }

  /// `Share on Twitter`
  String get share_twitter {
    return Intl.message(
      'Share on Twitter',
      name: 'share_twitter',
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

  /// `Bonuses`
  String get text_bonus {
    return Intl.message(
      'Bonuses',
      name: 'text_bonus',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Pic Chart!\nSee you in August 2024!`
  String get text_comming_soon_pic_chart1 {
    return Intl.message(
      'Welcome to Pic Chart!\nSee you in August 2024!',
      name: 'text_comming_soon_pic_chart1',
      desc: '',
      args: [],
    );
  }

  /// `Pic Chart is Picnic's new chart that\nreflects daily, weekly, and monthly scores.`
  String get text_comming_soon_pic_chart2 {
    return Intl.message(
      'Pic Chart is Picnic\'s new chart that\nreflects daily, weekly, and monthly scores.',
      name: 'text_comming_soon_pic_chart2',
      desc: '',
      args: [],
    );
  }

  /// `Check out the real-time\nbrand reputation of artists!`
  String get text_comming_soon_pic_chart3 {
    return Intl.message(
      'Check out the real-time\nbrand reputation of artists!',
      name: 'text_comming_soon_pic_chart3',
      desc: '',
      args: [],
    );
  }

  /// `Pic Chart?`
  String get text_comming_soon_pic_chart_title {
    return Intl.message(
      'Pic Chart?',
      name: 'text_comming_soon_pic_chart_title',
      desc: '',
      args: [],
    );
  }

  /// `The address has been copied.`
  String get text_copied_address {
    return Intl.message(
      'The address has been copied.',
      name: 'text_copied_address',
      desc: '',
      args: [],
    );
  }

  /// `Star candy has been awarded.`
  String get text_dialog_star_candy_received {
    return Intl.message(
      'Star candy has been awarded.',
      name: 'text_dialog_star_candy_received',
      desc: '',
      args: [],
    );
  }

  /// `The number of votes cannot be zero.`
  String get text_dialog_vote_amount_should_not_zero {
    return Intl.message(
      'The number of votes cannot be zero.',
      name: 'text_dialog_vote_amount_should_not_zero',
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

  /// `Search for an artist.`
  String get text_hint_search {
    return Intl.message(
      'Search for an artist.',
      name: 'text_hint_search',
      desc: '',
      args: [],
    );
  }

  /// `Navigate to the selected artist's home.`
  String get text_moveto_celeb_gallery {
    return Intl.message(
      'Navigate to the selected artist\'s home.',
      name: 'text_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Requires charging.`
  String get text_need_recharge {
    return Intl.message(
      'Requires charging.',
      name: 'text_need_recharge',
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

  /// `*Price includes VAT.`
  String get text_purchase_vat_included {
    return Intl.message(
      '*Price includes VAT.',
      name: 'text_purchase_vat_included',
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

  /// `{num1}개 +{num1}개 보너스`
  String text_star_candy_with_bonus(Object num1) {
    return Intl.message(
      '$num1개 +$num1개 보너스',
      name: 'text_star_candy_with_bonus',
      desc: '',
      args: [num1],
    );
  }

  /// `This Vote`
  String get text_this_time_vote {
    return Intl.message(
      'This Vote',
      name: 'text_this_time_vote',
      desc: '',
      args: [],
    );
  }

  /// `Voting complete`
  String get text_vote_complete {
    return Intl.message(
      'Voting complete',
      name: 'text_vote_complete',
      desc: '',
      args: [],
    );
  }

  /// `{rank}위`
  String text_vote_rank(Object rank) {
    return Intl.message(
      '$rank위',
      name: 'text_vote_rank',
      desc: '',
      args: [rank],
    );
  }

  /// `Rank in Rewards`
  String get text_vote_rank_in_reward {
    return Intl.message(
      'Rank in Rewards',
      name: 'text_vote_rank_in_reward',
      desc: '',
      args: [],
    );
  }

  /// `Where's My Favorite?`
  String get text_vote_where_is_my_bias {
    return Intl.message(
      'Where\'s My Favorite?',
      name: 'text_vote_where_is_my_bias',
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

  /// `成功`
  String get title_dialog_success {
    return Intl.message(
      '成功',
      name: 'title_dialog_success',
      desc: '',
      args: [],
    );
  }

  /// `Select a language`
  String get title_select_language {
    return Intl.message(
      'Select a language',
      name: 'title_select_language',
      desc: '',
      args: [],
    );
  }

  /// `You can add up to five of your own artists.`
  String get toast_max_five_celeb {
    return Intl.message(
      'You can add up to five of your own artists.',
      name: 'toast_max_five_celeb',
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
