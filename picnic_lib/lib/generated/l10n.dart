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

  /// `Achievement`
  String get achieve {
    return Intl.message(
      'Achievement',
      name: 'achieve',
      desc: '',
      args: [],
    );
  }

  /// `Ad availability`
  String get ads_available_time {
    return Intl.message(
      'Ad availability',
      name: 'ads_available_time',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous`
  String get anonymous {
    return Intl.message(
      'Anonymous',
      name: 'anonymous',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous Mode`
  String get anonymous_mode {
    return Intl.message(
      'Anonymous Mode',
      name: 'anonymous_mode',
      desc: '',
      args: [],
    );
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

  /// `Blocking users`
  String get block_user_label {
    return Intl.message(
      'Blocking users',
      name: 'block_user_label',
      desc: '',
      args: [],
    );
  }

  /// `Star candy has been awarded.`
  String get bonus_candy_awarded {
    return Intl.message(
      'Star candy has been awarded.',
      name: 'bonus_candy_awarded',
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

  /// `소멸 예정 보너스 별사탕 😢`
  String get candy_disappear_next_month {
    return Intl.message(
      '소멸 예정 보너스 별사탕 😢',
      name: 'candy_disappear_next_month',
      desc: '',
      args: [],
    );
  }

  /// `Bonus Star Candy earned in the current month will expire on the 15th of the following month.`
  String get candy_usage_policy_contents {
    return Intl.message(
      'Bonus Star Candy earned in the current month will expire on the 15th of the following month.',
      name: 'candy_usage_policy_contents',
      desc: '',
      args: [],
    );
  }

  /// `When using Star Candy, Star Candy that is about to expire is prioritized.`
  String get candy_usage_policy_contents2 {
    return Intl.message(
      'When using Star Candy, Star Candy that is about to expire is prioritized.',
      name: 'candy_usage_policy_contents2',
      desc: '',
      args: [],
    );
  }

  /// `*Bonuses will disappear the month after they are earned!`
  String get candy_usage_policy_guide {
    return Intl.message(
      '*Bonuses will disappear the month after they are earned!',
      name: 'candy_usage_policy_guide',
      desc: '',
      args: [],
    );
  }

  /// `Learn more`
  String get candy_usage_policy_guide_button {
    return Intl.message(
      'Learn more',
      name: 'candy_usage_policy_guide_button',
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

  /// `Comments`
  String get comments {
    return Intl.message(
      'Comments',
      name: 'comments',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get common_all {
    return Intl.message(
      'All',
      name: 'common_all',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get common_fail {
    return Intl.message(
      'Failed',
      name: 'common_fail',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get common_retry_label {
    return Intl.message(
      'Try again',
      name: 'common_retry_label',
      desc: '',
      args: [],
    );
  }

  /// `성공`
  String get common_success {
    return Intl.message(
      '성공',
      name: 'common_success',
      desc: '',
      args: [],
    );
  }

  /// `No data is available.`
  String get common_text_no_data {
    return Intl.message(
      'No data is available.',
      name: 'common_text_no_data',
      desc: '',
      args: [],
    );
  }

  /// `No search results found.`
  String get common_text_no_search_result {
    return Intl.message(
      'No search results found.',
      name: 'common_text_no_search_result',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred during the search.`
  String get common_text_search_error {
    return Intl.message(
      'An error occurred during the search.',
      name: 'common_text_search_error',
      desc: '',
      args: [],
    );
  }

  /// `Recent searches`
  String get common_text_search_recent_label {
    return Intl.message(
      'Recent searches',
      name: 'common_text_search_recent_label',
      desc: '',
      args: [],
    );
  }

  /// `Search results`
  String get common_text_search_result_label {
    return Intl.message(
      'Search results',
      name: 'common_text_search_result_label',
      desc: '',
      args: [],
    );
  }

  /// `Suggested activities`
  String get compatibility_activities_title {
    return Intl.message(
      'Suggested activities',
      name: 'compatibility_activities_title',
      desc: '',
      args: [],
    );
  }

  /// `I agree to store my gender and birthday information in my profile.`
  String get compatibility_agree_checkbox {
    return Intl.message(
      'I agree to store my gender and birthday information in my profile.',
      name: 'compatibility_agree_checkbox',
      desc: '',
      args: [],
    );
  }

  /// `Start compatibility analysis`
  String get compatibility_analyze_start {
    return Intl.message(
      'Start compatibility analysis',
      name: 'compatibility_analyze_start',
      desc: '',
      args: [],
    );
  }

  /// `Analyzing compatibility.`
  String get compatibility_analyzing {
    return Intl.message(
      'Analyzing compatibility.',
      name: 'compatibility_analyzing',
      desc: '',
      args: [],
    );
  }

  /// `Date of birth`
  String get compatibility_birthday {
    return Intl.message(
      'Date of birth',
      name: 'compatibility_birthday',
      desc: '',
      args: [],
    );
  }

  /// `Birth time`
  String get compatibility_birthtime {
    return Intl.message(
      'Birth time',
      name: 'compatibility_birthtime',
      desc: '',
      args: [],
    );
  }

  /// `Couple styles`
  String get compatibility_couple_style {
    return Intl.message(
      'Couple styles',
      name: 'compatibility_couple_style',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility data with the same conditions already exists.`
  String get compatibility_duplicate_data_message {
    return Intl.message(
      'Compatibility data with the same conditions already exists.',
      name: 'compatibility_duplicate_data_message',
      desc: '',
      args: [],
    );
  }

  /// `Please note that the compatibility data for this condition has already earned rewards, so we are unable to award additional rewards.`
  String get compatibility_perfect_score_exists {
    return Intl.message(
      'Please note that the compatibility data for this condition has already earned rewards, so we are unable to award additional rewards.',
      name: 'compatibility_perfect_score_exists',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility data that already exists`
  String get compatibility_duplicate_data_title {
    return Intl.message(
      'Compatibility data that already exists',
      name: 'compatibility_duplicate_data_title',
      desc: '',
      args: [],
    );
  }

  /// `Already Winning Matches Data`
  String get compatibility_perfect_score_exists_title {
    return Intl.message(
      'Already Winning Matches Data',
      name: 'compatibility_perfect_score_exists_title',
      desc: '',
      args: [],
    );
  }

  /// `Gender`
  String get compatibility_gender {
    return Intl.message(
      'Gender',
      name: 'compatibility_gender',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get compatibility_gender_female {
    return Intl.message(
      'Female',
      name: 'compatibility_gender_female',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get compatibility_gender_male {
    return Intl.message(
      'Male',
      name: 'compatibility_gender_male',
      desc: '',
      args: [],
    );
  }

  /// `Idol Styles`
  String get compatibility_idol_style {
    return Intl.message(
      'Idol Styles',
      name: 'compatibility_idol_style',
      desc: '',
      args: [],
    );
  }

  /// `Calculate New Goong-Hap`
  String get compatibility_new_compatibility {
    return Intl.message(
      'Calculate New Goong-Hap',
      name: 'compatibility_new_compatibility',
      desc: '',
      args: [],
    );
  }

  /// `Want to see a new pairing?`
  String get compatibility_new_compatibility_ask {
    return Intl.message(
      'Want to see a new pairing?',
      name: 'compatibility_new_compatibility_ask',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility`
  String get compatibility_page_title {
    return Intl.message(
      'Compatibility',
      name: 'compatibility_page_title',
      desc: '',
      args: [],
    );
  }

  /// `궁합이 없어요 😔`
  String get compatibility_result_not_found {
    return Intl.message(
      '궁합이 없어요 😔',
      name: 'compatibility_result_not_found',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred.`
  String get compatibility_snackbar_error {
    return Intl.message(
      'An error occurred.',
      name: 'compatibility_snackbar_error',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your date of birth.`
  String get compatibility_snackbar_need_birthday {
    return Intl.message(
      'Please enter your date of birth.',
      name: 'compatibility_snackbar_need_birthday',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your birth time.`
  String get compatibility_snackbar_need_birthtime {
    return Intl.message(
      'Please enter your birth time.',
      name: 'compatibility_snackbar_need_birthtime',
      desc: '',
      args: [],
    );
  }

  /// `Please select a gender.`
  String get compatibility_snackbar_need_gender {
    return Intl.message(
      'Please select a gender.',
      name: 'compatibility_snackbar_need_gender',
      desc: '',
      args: [],
    );
  }

  /// `Give your consent to save your profile.`
  String get compatibility_snackbar_need_profile_save_agree {
    return Intl.message(
      'Give your consent to save your profile.',
      name: 'compatibility_snackbar_need_profile_save_agree',
      desc: '',
      args: [],
    );
  }

  /// `Start analyzing compatibility.`
  String get compatibility_snackbar_start {
    return Intl.message(
      'Start analyzing compatibility.',
      name: 'compatibility_snackbar_start',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get compatibility_status_completed {
    return Intl.message(
      'Done',
      name: 'compatibility_status_completed',
      desc: '',
      args: [],
    );
  }

  /// `오류`
  String get compatibility_status_error {
    return Intl.message(
      '오류',
      name: 'compatibility_status_error',
      desc: '',
      args: [],
    );
  }

  /// `Typing`
  String get compatibility_status_input {
    return Intl.message(
      'Typing',
      name: 'compatibility_status_input',
      desc: '',
      args: [],
    );
  }

  /// `Analyzing`
  String get compatibility_status_pending {
    return Intl.message(
      'Analyzing',
      name: 'compatibility_status_pending',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility styles`
  String get compatibility_style_title {
    return Intl.message(
      'Compatibility styles',
      name: 'compatibility_style_title',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility summary`
  String get compatibility_summary_title {
    return Intl.message(
      'Compatibility summary',
      name: 'compatibility_summary_title',
      desc: '',
      args: [],
    );
  }

  /// `Don't know`
  String get compatibility_time_slot_unknown {
    return Intl.message(
      'Don\'t know',
      name: 'compatibility_time_slot_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility tips`
  String get compatibility_tips_title {
    return Intl.message(
      'Compatibility tips',
      name: 'compatibility_tips_title',
      desc: '',
      args: [],
    );
  }

  /// `User Styles`
  String get compatibility_user_style {
    return Intl.message(
      'User Styles',
      name: 'compatibility_user_style',
      desc: '',
      args: [],
    );
  }

  /// `Please wait a moment.`
  String get compatibility_waiting_message {
    return Intl.message(
      'Please wait a moment.',
      name: 'compatibility_waiting_message',
      desc: '',
      args: [],
    );
  }

  /// `If you leave the screen, you'll need to do the analysis again.`
  String get compatibility_warning_exit {
    return Intl.message(
      'If you leave the screen, you\'ll need to do the analysis again.',
      name: 'compatibility_warning_exit',
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

  /// `🚫 경고 🚫`
  String get dialog_caution {
    return Intl.message(
      '🚫 경고 🚫',
      name: 'dialog_caution',
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

  /// `When you can rejoin if you cancel your membership now`
  String get dialog_message_can_resignup {
    return Intl.message(
      'When you can rejoin if you cancel your membership now',
      name: 'dialog_message_can_resignup',
      desc: '',
      args: [],
    );
  }

  /// `Your purchase has been canceled.`
  String get dialog_message_purchase_canceled {
    return Intl.message(
      'Your purchase has been canceled.',
      name: 'dialog_message_purchase_canceled',
      desc: '',
      args: [],
    );
  }

  /// `There was an error with your purchase, please try again later.`
  String get dialog_message_purchase_failed {
    return Intl.message(
      'There was an error with your purchase, please try again later.',
      name: 'dialog_message_purchase_failed',
      desc: '',
      args: [],
    );
  }

  /// `Your purchase has been successfully completed.`
  String get dialog_message_purchase_success {
    return Intl.message(
      'Your purchase has been successfully completed.',
      name: 'dialog_message_purchase_success',
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

  /// `Starscapes to be deleted`
  String get dialog_will_delete_star_candy {
    return Intl.message(
      'Starscapes to be deleted',
      name: 'dialog_will_delete_star_candy',
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

  /// `If you cancel your membership, your star candy and account information on Picnic will be deleted immediately, and your existing information and data will not be restored when you rejoin.`
  String get dialog_withdraw_message {
    return Intl.message(
      'If you cancel your membership, your star candy and account information on Picnic will be deleted immediately, and your existing information and data will not be restored when you rejoin.',
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

  /// `An error occurred while performing the operation.`
  String get error_action_failed {
    return Intl.message(
      'An error occurred while performing the operation.',
      name: 'error_action_failed',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while parsing the content.`
  String get error_content_parse {
    return Intl.message(
      'An error occurred while parsing the content.',
      name: 'error_content_parse',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while deleting the post.`
  String get error_delete_post {
    return Intl.message(
      'An error occurred while deleting the post.',
      name: 'error_delete_post',
      desc: '',
      args: [],
    );
  }

  /// `Invalid data.`
  String get error_invalid_data {
    return Intl.message(
      'Invalid data.',
      name: 'error_invalid_data',
      desc: '',
      args: [],
    );
  }

  /// `There was an error loading the comment.`
  String get error_loading_more_comments {
    return Intl.message(
      'There was an error loading the comment.',
      name: 'error_loading_more_comments',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while loading the page.`
  String get error_loading_page {
    return Intl.message(
      'An error occurred while loading the page.',
      name: 'error_loading_page',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred during login.`
  String get error_message_login_failed {
    return Intl.message(
      'An error occurred during login.',
      name: 'error_message_login_failed',
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

  /// `Check your network connection.`
  String get error_network_connection {
    return Intl.message(
      'Check your network connection.',
      name: 'error_network_connection',
      desc: '',
      args: [],
    );
  }

  /// `The request timed out.`
  String get error_request_timeout {
    return Intl.message(
      'The request timed out.',
      name: 'error_request_timeout',
      desc: '',
      args: [],
    );
  }

  /// `Errors`
  String get error_title {
    return Intl.message(
      'Errors',
      name: 'error_title',
      desc: '',
      args: [],
    );
  }

  /// `An unknown error occurred.`
  String get error_unknown {
    return Intl.message(
      'An unknown error occurred.',
      name: 'error_unknown',
      desc: '',
      args: [],
    );
  }

  /// `We received an invalid response from the Apple server.\nPlease try again.`
  String get exception_auth_message_apple_invalid_response {
    return Intl.message(
      'We received an invalid response from the Apple server.\nPlease try again.',
      name: 'exception_auth_message_apple_invalid_response',
      desc: '',
      args: [],
    );
  }

  /// `Apple sign-in failed.\nPlease try again.`
  String get exception_auth_message_apple_sign_in_failed {
    return Intl.message(
      'Apple sign-in failed.\nPlease try again.',
      name: 'exception_auth_message_apple_sign_in_failed',
      desc: '',
      args: [],
    );
  }

  /// `Your login has been canceled.`
  String get exception_auth_message_common_cancel {
    return Intl.message(
      'Your login has been canceled.',
      name: 'exception_auth_message_common_cancel',
      desc: '',
      args: [],
    );
  }

  /// `The authentication token is invalid.\nPlease try again.`
  String get exception_auth_message_common_invalid_token {
    return Intl.message(
      'The authentication token is invalid.\nPlease try again.',
      name: 'exception_auth_message_common_invalid_token',
      desc: '',
      args: [],
    );
  }

  /// `Check your network connection.`
  String get exception_auth_message_common_network {
    return Intl.message(
      'Check your network connection.',
      name: 'exception_auth_message_common_network',
      desc: '',
      args: [],
    );
  }

  /// `An unknown error occurred during login.\nPlease try again in a moment.`
  String get exception_auth_message_common_unknown {
    return Intl.message(
      'An unknown error occurred during login.\nPlease try again in a moment.',
      name: 'exception_auth_message_common_unknown',
      desc: '',
      args: [],
    );
  }

  /// `This login method is not supported`
  String get exception_auth_message_common_unsupported_provider {
    return Intl.message(
      'This login method is not supported',
      name: 'exception_auth_message_common_unsupported_provider',
      desc: '',
      args: [],
    );
  }

  /// `A Google Play Services error has occurred.\nPlease update Google Play Services or restart your device.`
  String get exception_auth_message_google_google_play_service {
    return Intl.message(
      'A Google Play Services error has occurred.\nPlease update Google Play Services or restart your device.',
      name: 'exception_auth_message_google_google_play_service',
      desc: '',
      args: [],
    );
  }

  /// `I can't sign in with the KakaoTalk app.\nTry signing in with your Kakao account.`
  String get exception_auth_message_kakao_not_supported {
    return Intl.message(
      'I can\'t sign in with the KakaoTalk app.\nTry signing in with your Kakao account.',
      name: 'exception_auth_message_kakao_not_supported',
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

  /// `You have exhausted the ads available per ID.`
  String get label_ads_exceeded {
    return Intl.message(
      'You have exhausted the ads available per ID.',
      name: 'label_ads_exceeded',
      desc: '',
      args: [],
    );
  }

  /// `When the next ad will be available.`
  String get label_ads_next_available_time {
    return Intl.message(
      'When the next ad will be available.',
      name: 'label_ads_next_available_time',
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

  /// `닫기`
  String get label_button_close {
    return Intl.message(
      '닫기',
      name: 'label_button_close',
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

  /// `Mission and charge`
  String get label_button_mission_and_charge {
    return Intl.message(
      'Mission and charge',
      name: 'label_button_mission_and_charge',
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

  /// `Recent`
  String get label_last_provider {
    return Intl.message(
      'Recent',
      name: 'label_last_provider',
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

  /// `Loading ad`
  String get label_loading_ads {
    return Intl.message(
      'Loading ad',
      name: 'label_loading_ads',
      desc: '',
      args: [],
    );
  }

  /// `Ads fail to load`
  String get label_loading_ads_fail {
    return Intl.message(
      'Ads fail to load',
      name: 'label_loading_ads_fail',
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

  /// `My Artists`
  String get label_mypage_my_artist {
    return Intl.message(
      'My Artists',
      name: 'label_mypage_my_artist',
      desc: '',
      args: [],
    );
  }

  /// `Sign up for MyArtist.`
  String get label_mypage_no_artist {
    return Intl.message(
      'Sign up for MyArtist.',
      name: 'label_mypage_no_artist',
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

  /// `Id.`
  String get label_mypage_picnic_id {
    return Intl.message(
      'Id.',
      name: 'label_mypage_picnic_id',
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

  /// `Please sign in`
  String get label_mypage_should_login {
    return Intl.message(
      'Please sign in',
      name: 'label_mypage_should_login',
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

  /// `Star Candy Voting History`
  String get label_mypage_vote_history {
    return Intl.message(
      'Star Candy Voting History',
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

  /// `Replying to a reply`
  String get label_reply {
    return Intl.message(
      'Replying to a reply',
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

  /// `Latest version`
  String get label_setting_recent_version_up_to_date {
    return Intl.message(
      'Latest version',
      name: 'label_setting_recent_version_up_to_date',
      desc: '',
      args: [],
    );
  }

  /// `Delete cache memory`
  String get label_setting_remove_cache {
    return Intl.message(
      'Delete cache memory',
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

  /// `MyArtist`
  String get label_tab_my_artist {
    return Intl.message(
      'MyArtist',
      name: 'label_tab_my_artist',
      desc: '',
      args: [],
    );
  }

  /// `Find MyArtist`
  String get label_tab_search_my_artist {
    return Intl.message(
      'Find MyArtist',
      name: 'label_tab_search_my_artist',
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

  /// `Upcoming`
  String get label_tabbar_vote_upcoming {
    return Intl.message(
      'Upcoming',
      name: 'label_tabbar_vote_upcoming',
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

  /// `Close the poll`
  String get label_vote_end {
    return Intl.message(
      'Close the poll',
      name: 'label_vote_end',
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

  /// `Until voting begins`
  String get label_vote_upcoming {
    return Intl.message(
      'Until voting begins',
      name: 'label_vote_upcoming',
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

  /// `Mission`
  String get label_mission {
    return Intl.message(
      'Mission',
      name: 'label_mission',
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

  /// `There are currently no active polls.`
  String get message_noitem_vote_active {
    return Intl.message(
      'There are currently no active polls.',
      name: 'message_noitem_vote_active',
      desc: '',
      args: [],
    );
  }

  /// `There are currently no closed polls.`
  String get message_noitem_vote_end {
    return Intl.message(
      'There are currently no closed polls.',
      name: 'message_noitem_vote_end',
      desc: '',
      args: [],
    );
  }

  /// `There are currently no upcoming polls.`
  String get message_noitem_vote_upcoming {
    return Intl.message(
      'There are currently no upcoming polls.',
      name: 'message_noitem_vote_upcoming',
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

  /// `Cache memory deletion is complete`
  String get message_setting_remove_cache {
    return Intl.message(
      'Cache memory deletion is complete',
      name: 'message_setting_remove_cache',
      desc: '',
      args: [],
    );
  }

  /// `Nickname change failed.\nPlease select a different nickname.`
  String get message_update_nickname_fail {
    return Intl.message(
      'Nickname change failed.\nPlease select a different nickname.',
      name: 'message_update_nickname_fail',
      desc: '',
      args: [],
    );
  }

  /// `Your nickname has been successfully changed.`
  String get message_update_nickname_success {
    return Intl.message(
      'Your nickname has been successfully changed.',
      name: 'message_update_nickname_success',
      desc: '',
      args: [],
    );
  }

  /// `Poll closed`
  String get message_vote_is_ended {
    return Intl.message(
      'Poll closed',
      name: 'message_vote_is_ended',
      desc: '',
      args: [],
    );
  }

  /// `This is an upcoming vote`
  String get message_vote_is_upcoming {
    return Intl.message(
      'This is an upcoming vote',
      name: 'message_vote_is_upcoming',
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

  /// `Boards`
  String get nav_board {
    return Intl.message(
      'Boards',
      name: 'nav_board',
      desc: '',
      args: [],
    );
  }

  /// `My Artist’s Fortune teller`
  String get fortune_button_title {
    return Intl.message(
      'My Artist’s Fortune teller',
      name: 'fortune_button_title',
      desc: '',
      args: [],
    );
  }

  /// `Fortune of {year}`
  String fortune_title(Object year) {
    return Intl.message(
      'Fortune of $year',
      name: 'fortune_title',
      desc: '',
      args: [year],
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

  /// `Home`
  String get nav_home {
    return Intl.message(
      'Home',
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

  /// `My Information`
  String get my_info {
    return Intl.message(
      'My Information',
      name: 'my_info',
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

  /// `My`
  String get nav_my {
    return Intl.message(
      'My',
      name: 'nav_my',
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

  /// `Optional`
  String get optional {
    return Intl.message(
      'Optional',
      name: 'optional',
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

  /// `Create a post`
  String get page_title_post_write {
    return Intl.message(
      'Create a post',
      name: 'page_title_post_write',
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

  /// `Delete`
  String get popup_label_delete {
    return Intl.message(
      'Delete',
      name: 'popup_label_delete',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous posting`
  String get post_anonymous {
    return Intl.message(
      'Anonymous posting',
      name: 'post_anonymous',
      desc: '',
      args: [],
    );
  }

  /// `Want to go to the Drafts list?`
  String get post_ask_go_to_temporary_save_list {
    return Intl.message(
      'Want to go to the Drafts list?',
      name: 'post_ask_go_to_temporary_save_list',
      desc: '',
      args: [],
    );
  }

  /// `A board that already exists.`
  String get post_board_already_exist {
    return Intl.message(
      'A board that already exists.',
      name: 'post_board_already_exist',
      desc: '',
      args: [],
    );
  }

  /// `Your request to open a board is complete.`
  String get post_board_create_request_complete {
    return Intl.message(
      'Your request to open a board is complete.',
      name: 'post_board_create_request_complete',
      desc: '',
      args: [],
    );
  }

  /// `*Only one minor board can be applied per ID.`
  String get post_board_create_request_condition {
    return Intl.message(
      '*Only one minor board can be applied per ID.',
      name: 'post_board_create_request_condition',
      desc: '',
      args: [],
    );
  }

  /// `Request to open a board`
  String get post_board_create_request_label {
    return Intl.message(
      'Request to open a board',
      name: 'post_board_create_request_label',
      desc: '',
      args: [],
    );
  }

  /// `Reviewing a request to open a board`
  String get post_board_create_request_reviewing {
    return Intl.message(
      'Reviewing a request to open a board',
      name: 'post_board_create_request_reviewing',
      desc: '',
      args: [],
    );
  }

  /// `Open requests`
  String get post_board_request_label {
    return Intl.message(
      'Open requests',
      name: 'post_board_request_label',
      desc: '',
      args: [],
    );
  }

  /// `I can't open Youtube.`
  String get post_cannot_open_youtube {
    return Intl.message(
      'I can\'t open Youtube.',
      name: 'post_cannot_open_youtube',
      desc: '',
      args: [],
    );
  }

  /// `View full text`
  String get post_comment_action_show_original {
    return Intl.message(
      'View full text',
      name: 'post_comment_action_show_original',
      desc: '',
      args: [],
    );
  }

  /// `View translations`
  String get post_comment_action_show_translation {
    return Intl.message(
      'View translations',
      name: 'post_comment_action_show_translation',
      desc: '',
      args: [],
    );
  }

  /// `Translation`
  String get post_comment_action_translate {
    return Intl.message(
      'Translation',
      name: 'post_comment_action_translate',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get post_comment_content_more {
    return Intl.message(
      'More',
      name: 'post_comment_content_more',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete the comment?`
  String get post_comment_delete_confirm {
    return Intl.message(
      'Are you sure you want to delete the comment?',
      name: 'post_comment_delete_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Comment deletion failed.`
  String get post_comment_delete_fail {
    return Intl.message(
      'Comment deletion failed.',
      name: 'post_comment_delete_fail',
      desc: '',
      args: [],
    );
  }

  /// `This is a deleted comment.`
  String get post_comment_deleted_comment {
    return Intl.message(
      'This is a deleted comment.',
      name: 'post_comment_deleted_comment',
      desc: '',
      args: [],
    );
  }

  /// `Failed to process like.`
  String get post_comment_like_processing_fail {
    return Intl.message(
      'Failed to process like.',
      name: 'post_comment_like_processing_fail',
      desc: '',
      args: [],
    );
  }

  /// `Comment failed to load.`
  String get post_comment_loading_fail {
    return Intl.message(
      'Comment failed to load.',
      name: 'post_comment_loading_fail',
      desc: '',
      args: [],
    );
  }

  /// `Comment registration failed.`
  String get post_comment_register_fail {
    return Intl.message(
      'Comment registration failed.',
      name: 'post_comment_register_fail',
      desc: '',
      args: [],
    );
  }

  /// `Your comment has been registered.`
  String get post_comment_registered_comment {
    return Intl.message(
      'Your comment has been registered.',
      name: 'post_comment_registered_comment',
      desc: '',
      args: [],
    );
  }

  /// `This is a reported comment.`
  String get post_comment_reported_comment {
    return Intl.message(
      'This is a reported comment.',
      name: 'post_comment_reported_comment',
      desc: '',
      args: [],
    );
  }

  /// `The translation is complete.`
  String get post_comment_translate_complete {
    return Intl.message(
      'The translation is complete.',
      name: 'post_comment_translate_complete',
      desc: '',
      args: [],
    );
  }

  /// `The translation failed.`
  String get post_comment_translate_fail {
    return Intl.message(
      'The translation failed.',
      name: 'post_comment_translate_fail',
      desc: '',
      args: [],
    );
  }

  /// `Translated`
  String get post_comment_translated {
    return Intl.message(
      'Translated',
      name: 'post_comment_translated',
      desc: '',
      args: [],
    );
  }

  /// `Write a comment`
  String get post_comment_write_label {
    return Intl.message(
      'Write a comment',
      name: 'post_comment_write_label',
      desc: '',
      args: [],
    );
  }

  /// `Please enter something.`
  String get post_content_placeholder {
    return Intl.message(
      'Please enter something.',
      name: 'post_content_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete the scrap?`
  String get post_delete_scrap_confirm {
    return Intl.message(
      'Do you want to delete the scrap?',
      name: 'post_delete_scrap_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Delete a scrap`
  String get post_delete_scrap_title {
    return Intl.message(
      'Delete a scrap',
      name: 'post_delete_scrap_title',
      desc: '',
      args: [],
    );
  }

  /// `Contains inappropriate content`
  String get post_flagged {
    return Intl.message(
      'Contains inappropriate content',
      name: 'post_flagged',
      desc: '',
      args: [],
    );
  }

  /// `Go to the board`
  String get post_go_to_boards {
    return Intl.message(
      'Go to the board',
      name: 'post_go_to_boards',
      desc: '',
      args: [],
    );
  }

  /// `Publishing`
  String get post_header_publish {
    return Intl.message(
      'Publishing',
      name: 'post_header_publish',
      desc: '',
      args: [],
    );
  }

  /// `Drafts`
  String get post_header_temporary_save {
    return Intl.message(
      'Drafts',
      name: 'post_header_temporary_save',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a title.`
  String get post_hint_title {
    return Intl.message(
      'Please enter a title.',
      name: 'post_hint_title',
      desc: '',
      args: [],
    );
  }

  /// `Hyperlinks`
  String get post_hyperlink {
    return Intl.message(
      'Hyperlinks',
      name: 'post_hyperlink',
      desc: '',
      args: [],
    );
  }

  /// `Inserting links`
  String get post_insert_link {
    return Intl.message(
      'Inserting links',
      name: 'post_insert_link',
      desc: '',
      args: [],
    );
  }

  /// `The post failed to load.`
  String get post_loading_post_fail {
    return Intl.message(
      'The post failed to load.',
      name: 'post_loading_post_fail',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a description of at least 5 characters and no more than 20 characters.`
  String get post_minor_board_condition {
    return Intl.message(
      'Please enter a description of at least 5 characters and no more than 20 characters.',
      name: 'post_minor_board_condition',
      desc: '',
      args: [],
    );
  }

  /// `* Message requesting to open a board.`
  String get post_minor_board_create_request_message {
    return Intl.message(
      '* Message requesting to open a board.',
      name: 'post_minor_board_create_request_message',
      desc: '',
      args: [],
    );
  }

  /// `Please include at least 10 characters in your message requesting to open a board.`
  String get post_minor_board_create_request_message_condition {
    return Intl.message(
      'Please include at least 10 characters in your message requesting to open a board.',
      name: 'post_minor_board_create_request_message_condition',
      desc: '',
      args: [],
    );
  }

  /// `Enter a message requesting to open a board.`
  String get post_minor_board_create_request_message_input {
    return Intl.message(
      'Enter a message requesting to open a board.',
      name: 'post_minor_board_create_request_message_input',
      desc: '',
      args: [],
    );
  }

  /// `Minor bulletin board descriptions`
  String get post_minor_board_description {
    return Intl.message(
      'Minor bulletin board descriptions',
      name: 'post_minor_board_description',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a description for your minor board.`
  String get post_minor_board_description_input {
    return Intl.message(
      'Please enter a description for your minor board.',
      name: 'post_minor_board_description_input',
      desc: '',
      args: [],
    );
  }

  /// `Minor board name`
  String get post_minor_board_name {
    return Intl.message(
      'Minor board name',
      name: 'post_minor_board_name',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a name for your minor board.`
  String get post_minor_board_name_input {
    return Intl.message(
      'Please enter a name for your minor board.',
      name: 'post_minor_board_name_input',
      desc: '',
      args: [],
    );
  }

  /// `My compatibility`
  String get post_my_compatibilities {
    return Intl.message(
      'My compatibility',
      name: 'post_my_compatibilities',
      desc: '',
      args: [],
    );
  }

  /// `Posts I've written`
  String get post_my_written_post {
    return Intl.message(
      'Posts I\'ve written',
      name: 'post_my_written_post',
      desc: '',
      args: [],
    );
  }

  /// `Comments I wrote`
  String get post_my_written_reply {
    return Intl.message(
      'Comments I wrote',
      name: 'post_my_written_reply',
      desc: '',
      args: [],
    );
  }

  /// `My Scraps`
  String get post_my_written_scrap {
    return Intl.message(
      'My Scraps',
      name: 'post_my_written_scrap',
      desc: '',
      args: [],
    );
  }

  /// `No comments.`
  String get post_no_comment {
    return Intl.message(
      'No comments.',
      name: 'post_no_comment',
      desc: '',
      args: [],
    );
  }

  /// `No posts were found.`
  String get post_not_found {
    return Intl.message(
      'No posts were found.',
      name: 'post_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Replying to {nickname}...`
  String post_replying_comment(Object nickname) {
    return Intl.message(
      'Replying to $nickname...',
      name: 'post_replying_comment',
      desc: '',
      args: [nickname],
    );
  }

  /// `The report failed.`
  String get post_report_fail {
    return Intl.message(
      'The report failed.',
      name: 'post_report_fail',
      desc: '',
      args: [],
    );
  }

  /// `Make a report`
  String get post_report_label {
    return Intl.message(
      'Make a report',
      name: 'post_report_label',
      desc: '',
      args: [],
    );
  }

  /// `Please enter any other reason.`
  String get post_report_other_input {
    return Intl.message(
      'Please enter any other reason.',
      name: 'post_report_other_input',
      desc: '',
      args: [],
    );
  }

  /// `Unsavory posts`
  String get post_report_reason_1 {
    return Intl.message(
      'Unsavory posts',
      name: 'post_report_reason_1',
      desc: '',
      args: [],
    );
  }

  /// `Sexist, racist posts`
  String get post_report_reason_2 {
    return Intl.message(
      'Sexist, racist posts',
      name: 'post_report_reason_2',
      desc: '',
      args: [],
    );
  }

  /// `Posts containing offensive profanity`
  String get post_report_reason_3 {
    return Intl.message(
      'Posts containing offensive profanity',
      name: 'post_report_reason_3',
      desc: '',
      args: [],
    );
  }

  /// `Advertising/Promotional Posts`
  String get post_report_reason_4 {
    return Intl.message(
      'Advertising/Promotional Posts',
      name: 'post_report_reason_4',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get post_report_reason_5 {
    return Intl.message(
      'Other',
      name: 'post_report_reason_5',
      desc: '',
      args: [],
    );
  }

  /// `Please select a reason for your report.`
  String get post_report_reason_input {
    return Intl.message(
      'Please select a reason for your report.',
      name: 'post_report_reason_input',
      desc: '',
      args: [],
    );
  }

  /// `Reasons for reporting`
  String get post_report_reason_label {
    return Intl.message(
      'Reasons for reporting',
      name: 'post_report_reason_label',
      desc: '',
      args: [],
    );
  }

  /// `The report is complete.`
  String get post_report_success {
    return Intl.message(
      'The report is complete.',
      name: 'post_report_success',
      desc: '',
      args: [],
    );
  }

  /// `Draft complete.`
  String get post_temporary_save_complete {
    return Intl.message(
      'Draft complete.',
      name: 'post_temporary_save_complete',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a title.`
  String get post_title_placeholder {
    return Intl.message(
      'Please enter a title.',
      name: 'post_title_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Create a post`
  String get post_write_board_post {
    return Intl.message(
      'Create a post',
      name: 'post_write_board_post',
      desc: '',
      args: [],
    );
  }

  /// `Please create a post.`
  String get post_write_post_recommend_write {
    return Intl.message(
      'Please create a post.',
      name: 'post_write_post_recommend_write',
      desc: '',
      args: [],
    );
  }

  /// `YouTube link`
  String get post_youtube_link {
    return Intl.message(
      'YouTube link',
      name: 'post_youtube_link',
      desc: '',
      args: [],
    );
  }

  /// `This is the payment window for those who can't pay with the app.\n Please copy the random ID in advance.\n After copying it, click the button below to proceed with the payment.`
  String get purchase_web_message {
    return Intl.message(
      'This is the payment window for those who can\'t pay with the app.\n Please copy the random ID in advance.\n After copying it, click the button below to proceed with the payment.',
      name: 'purchase_web_message',
      desc: '',
      args: [],
    );
  }

  /// `Comments`
  String get replies {
    return Intl.message(
      'Comments',
      name: 'replies',
      desc: '',
      args: [],
    );
  }

  /// `Rewards`
  String get reward {
    return Intl.message(
      'Rewards',
      name: 'reward',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `seconds`
  String get seconds {
    return Intl.message(
      'seconds',
      name: 'seconds',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
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

  /// `X app is missing.`
  String get share_no_twitter {
    return Intl.message(
      'X app is missing.',
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

  /// `🎉 You've reached ${count} goals so far! 🎉`
  String text_achievement(Object count) {
    return Intl.message(
      '🎉 You\'ve reached \$$count goals so far! 🎉',
      name: 'text_achievement',
      desc: '',
      args: [count],
    );
  }

  /// `If I want to know the Goong-hap score between me and the {artist_name}?`
  String compatibility_purchase_message(Object artist_name) {
    return Intl.message(
      'If I want to know the Goong-hap score between me and the $artist_name?',
      name: 'compatibility_purchase_message',
      desc: '',
      args: [artist_name],
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

  /// `Failed to unbookmark`
  String get text_bookmark_failed {
    return Intl.message(
      'Failed to unbookmark',
      name: 'text_bookmark_failed',
      desc: '',
      args: [],
    );
  }

  /// `You can have up to five bookmarks`
  String get text_bookmark_over_5 {
    return Intl.message(
      'You can have up to five bookmarks',
      name: 'text_bookmark_over_5',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Peek Charts!\nSee you in November 2024!`
  String get text_comming_soon_pic_chart1 {
    return Intl.message(
      'Welcome to Peek Charts!\nSee you in November 2024!',
      name: 'text_comming_soon_pic_chart1',
      desc: '',
      args: [],
    );
  }

  /// `Pie charts are a new chart unique to Peeknick that reflects daily, weekly, and monthly scores.\nPeeknick's new chart that reflects daily, weekly, and monthly scores.`
  String get text_comming_soon_pic_chart2 {
    return Intl.message(
      'Pie charts are a new chart unique to Peeknick that reflects daily, weekly, and monthly scores.\nPeeknick\'s new chart that reflects daily, weekly, and monthly scores.',
      name: 'text_comming_soon_pic_chart2',
      desc: '',
      args: [],
    );
  }

  /// `Get a real-time reflection\nartist's brand reputation in real-time!`
  String get text_comming_soon_pic_chart3 {
    return Intl.message(
      'Get a real-time reflection\nartist\'s brand reputation in real-time!',
      name: 'text_comming_soon_pic_chart3',
      desc: '',
      args: [],
    );
  }

  /// `What is a Pie Chart?`
  String get text_comming_soon_pic_chart_title {
    return Intl.message(
      'What is a Pie Chart?',
      name: 'text_comming_soon_pic_chart_title',
      desc: '',
      args: [],
    );
  }

  /// `Searching the Artist Board`
  String get text_community_board_search {
    return Intl.message(
      'Searching the Artist Board',
      name: 'text_community_board_search',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get text_community_post_search {
    return Intl.message(
      'Search',
      name: 'text_community_post_search',
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

  /// `The ad stopped midway through.`
  String get text_dialog_ad_dismissed {
    return Intl.message(
      'The ad stopped midway through.',
      name: 'text_dialog_ad_dismissed',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load ads`
  String get text_dialog_ad_failed_to_show {
    return Intl.message(
      'Failed to load ads',
      name: 'text_dialog_ad_failed_to_show',
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

  /// `Search for artists`
  String get text_hint_search {
    return Intl.message(
      'Search for artists',
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

  /// `No artist`
  String get text_no_artist {
    return Intl.message(
      'No artist',
      name: 'text_no_artist',
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

  /// `{num1} + {num1} Bonuses`
  String text_star_candy_with_bonus(Object num1) {
    return Intl.message(
      '$num1 + $num1 Bonuses',
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

  /// `Rank {rank}`
  String text_vote_rank(Object rank) {
    return Intl.message(
      'Rank $rank',
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

  /// `성공`
  String get title_dialog_success {
    return Intl.message(
      '성공',
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

  /// `Update`
  String get update_button {
    return Intl.message(
      'Update',
      name: 'update_button',
      desc: '',
      args: [],
    );
  }

  /// `I can't open the app store.`
  String get update_cannot_open_appstore {
    return Intl.message(
      'I can\'t open the app store.',
      name: 'update_cannot_open_appstore',
      desc: '',
      args: [],
    );
  }

  /// `A new version ({version}) is available.`
  String update_recommend_text(Object version) {
    return Intl.message(
      'A new version ($version) is available.',
      name: 'update_recommend_text',
      desc: '',
      args: [version],
    );
  }

  /// `You need to update to a new version ({version}).`
  String update_required_text(Object version) {
    return Intl.message(
      'You need to update to a new version ($version).',
      name: 'update_required_text',
      desc: '',
      args: [version],
    );
  }

  /// `An update is required.`
  String get update_required_title {
    return Intl.message(
      'An update is required.',
      name: 'update_required_title',
      desc: '',
      args: [],
    );
  }

  /// `Views`
  String get views {
    return Intl.message(
      'Views',
      name: 'views',
      desc: '',
      args: [],
    );
  }

  /// `Save the results`
  String get vote_result_save_button {
    return Intl.message(
      'Save the results',
      name: 'vote_result_save_button',
      desc: '',
      args: [],
    );
  }

  /// `Share your results`
  String get vote_result_share_button {
    return Intl.message(
      'Share your results',
      name: 'vote_result_share_button',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Rat|(23:30-01:29)|🐀`
  String get compatibility_time_slot1 {
    return Intl.message(
      'Hour of the Rat|(23:30-01:29)|🐀',
      name: 'compatibility_time_slot1',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Ox|(01:30-03:29)|🐂`
  String get compatibility_time_slot2 {
    return Intl.message(
      'Hour of the Ox|(01:30-03:29)|🐂',
      name: 'compatibility_time_slot2',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Tiger|(03:30-05:29)|🐅`
  String get compatibility_time_slot3 {
    return Intl.message(
      'Hour of the Tiger|(03:30-05:29)|🐅',
      name: 'compatibility_time_slot3',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Rabbit|(05:30-07:29)|🐇`
  String get compatibility_time_slot4 {
    return Intl.message(
      'Hour of the Rabbit|(05:30-07:29)|🐇',
      name: 'compatibility_time_slot4',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Dragon|(07:30-09:29)|🐉`
  String get compatibility_time_slot5 {
    return Intl.message(
      'Hour of the Dragon|(07:30-09:29)|🐉',
      name: 'compatibility_time_slot5',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Snake|(09:30-11:29)|🐍`
  String get compatibility_time_slot6 {
    return Intl.message(
      'Hour of the Snake|(09:30-11:29)|🐍',
      name: 'compatibility_time_slot6',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Horse|(11:30-13:29)|🐎`
  String get compatibility_time_slot7 {
    return Intl.message(
      'Hour of the Horse|(11:30-13:29)|🐎',
      name: 'compatibility_time_slot7',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Sheep|(13:30-15:29)|🐑`
  String get compatibility_time_slot8 {
    return Intl.message(
      'Hour of the Sheep|(13:30-15:29)|🐑',
      name: 'compatibility_time_slot8',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Monkey|(15:30-17:29)|🐒`
  String get compatibility_time_slot9 {
    return Intl.message(
      'Hour of the Monkey|(15:30-17:29)|🐒',
      name: 'compatibility_time_slot9',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Rooster|(17:30-19:29)|🐔`
  String get compatibility_time_slot10 {
    return Intl.message(
      'Hour of the Rooster|(17:30-19:29)|🐔',
      name: 'compatibility_time_slot10',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Dog|(19:30-21:29)|🐕`
  String get compatibility_time_slot11 {
    return Intl.message(
      'Hour of the Dog|(19:30-21:29)|🐕',
      name: 'compatibility_time_slot11',
      desc: '',
      args: [],
    );
  }

  /// `Hour of the Boar|(21:30-23:29)|🐖`
  String get compatibility_time_slot12 {
    return Intl.message(
      'Hour of the Boar|(21:30-23:29)|🐖',
      name: 'compatibility_time_slot12',
      desc: '',
      args: [],
    );
  }

  /// `Get 1 bonus star candy for every 100 votes and share!`
  String get voting_share_benefit_text {
    return Intl.message(
      'Get 1 bonus star candy for every 100 votes and share!',
      name: 'voting_share_benefit_text',
      desc: '',
      args: [],
    );
  }

  /// `Comprehensive Fortune`
  String get fortune_total_title {
    return Intl.message(
      'Comprehensive Fortune',
      name: 'fortune_total_title',
      desc: '',
      args: [],
    );
  }

  /// `Monthly Fortune`
  String get fortune_monthly {
    return Intl.message(
      'Monthly Fortune',
      name: 'fortune_monthly',
      desc: '',
      args: [],
    );
  }

  /// `Business fortunes`
  String get fortune_career {
    return Intl.message(
      'Business fortunes',
      name: 'fortune_career',
      desc: '',
      args: [],
    );
  }

  /// `Health clouds`
  String get fortune_health {
    return Intl.message(
      'Health clouds',
      name: 'fortune_health',
      desc: '',
      args: [],
    );
  }

  /// `Fortune Telling`
  String get fortune_money {
    return Intl.message(
      'Fortune Telling',
      name: 'fortune_money',
      desc: '',
      args: [],
    );
  }

  /// `Interpersonal`
  String get fortune_relationship {
    return Intl.message(
      'Interpersonal',
      name: 'fortune_relationship',
      desc: '',
      args: [],
    );
  }

  /// `Lucky keywords`
  String get fortune_lucky_keyword {
    return Intl.message(
      'Lucky keywords',
      name: 'fortune_lucky_keyword',
      desc: '',
      args: [],
    );
  }

  /// `Lucky days of the week`
  String get fortune_lucky_days {
    return Intl.message(
      'Lucky days of the week',
      name: 'fortune_lucky_days',
      desc: '',
      args: [],
    );
  }

  /// `Lucky colors`
  String get fortune_lucky_color {
    return Intl.message(
      'Lucky colors',
      name: 'fortune_lucky_color',
      desc: '',
      args: [],
    );
  }

  /// `Lucky numbers`
  String get fortune_lucky_number {
    return Intl.message(
      'Lucky numbers',
      name: 'fortune_lucky_number',
      desc: '',
      args: [],
    );
  }

  /// `Direction of Fortune`
  String get fortune_lucky_direction {
    return Intl.message(
      'Direction of Fortune',
      name: 'fortune_lucky_direction',
      desc: '',
      args: [],
    );
  }

  /// `Advice`
  String get fortune_advice {
    return Intl.message(
      'Advice',
      name: 'fortune_advice',
      desc: '',
      args: [],
    );
  }

  /// `Voted!`
  String get vote_share_message {
    return Intl.message(
      'Voted!',
      name: 'vote_share_message',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for January`
  String get fortune_month1 {
    return Intl.message(
      'Fortune for January',
      name: 'fortune_month1',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for February`
  String get fortune_month2 {
    return Intl.message(
      'Fortune for February',
      name: 'fortune_month2',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for March`
  String get fortune_month3 {
    return Intl.message(
      'Fortune for March',
      name: 'fortune_month3',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for April`
  String get fortune_month4 {
    return Intl.message(
      'Fortune for April',
      name: 'fortune_month4',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for August`
  String get fortune_month8 {
    return Intl.message(
      'Fortune for August',
      name: 'fortune_month8',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for July`
  String get fortune_month7 {
    return Intl.message(
      'Fortune for July',
      name: 'fortune_month7',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for June`
  String get fortune_month6 {
    return Intl.message(
      'Fortune for June',
      name: 'fortune_month6',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for May`
  String get fortune_month5 {
    return Intl.message(
      'Fortune for May',
      name: 'fortune_month5',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for September`
  String get fortune_month9 {
    return Intl.message(
      'Fortune for September',
      name: 'fortune_month9',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for October`
  String get fortune_month10 {
    return Intl.message(
      'Fortune for October',
      name: 'fortune_month10',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for November`
  String get fortune_month11 {
    return Intl.message(
      'Fortune for November',
      name: 'fortune_month11',
      desc: '',
      args: [],
    );
  }

  /// `Fortune for December`
  String get fortune_month12 {
    return Intl.message(
      'Fortune for December',
      name: 'fortune_month12',
      desc: '',
      args: [],
    );
  }

  /// `Honor`
  String get fortune_honor {
    return Intl.message(
      'Honor',
      name: 'fortune_honor',
      desc: '',
      args: [],
    );
  }

  /// `Increase accuracy!`
  String get compatibility_birthtime_subtitle {
    return Intl.message(
      'Increase accuracy!',
      name: 'compatibility_birthtime_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Check with Star Candy`
  String get fortune_purchase_by_star_candy {
    return Intl.message(
      'Check with Star Candy',
      name: 'fortune_purchase_by_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `Pay Now`
  String get fortune_purchase_by_one_click {
    return Intl.message(
      'Pay Now',
      name: 'fortune_purchase_by_one_click',
      desc: '',
      args: [],
    );
  }

  /// `You don't have enough Star Candy. Moving to the shop screen.`
  String get fortune_lack_of_star_candy_title {
    return Intl.message(
      'You don\'t have enough Star Candy. Moving to the shop screen.',
      name: 'fortune_lack_of_star_candy_title',
      desc: '',
      args: [],
    );
  }

  /// `Reward Star Candies cannot be used here. 😥`
  String get fortune_lack_of_star_candy_message {
    return Intl.message(
      'Reward Star Candies cannot be used here. 😥',
      name: 'fortune_lack_of_star_candy_message',
      desc: '',
      args: [],
    );
  }

  /// `Goong-Hap with me`
  String get fortune_with_me {
    return Intl.message(
      'Goong-Hap with me',
      name: 'fortune_with_me',
      desc: '',
      args: [],
    );
  }

  /// `Preparing`
  String get compatibility_analyzing_prepare {
    return Intl.message(
      'Preparing',
      name: 'compatibility_analyzing_prepare',
      desc: '',
      args: [],
    );
  }

  /// `Remaining Star Candy`
  String get compatibility_remain_star_candy {
    return Intl.message(
      'Remaining Star Candy',
      name: 'compatibility_remain_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `Curious about #{artist_name}’s 2025 fortune? Come to #피크닠 now! Let’s discover that shining destiny together!`
  String fortune_share_message(Object artist_name) {
    return Intl.message(
      'Curious about #$artist_name’s 2025 fortune? Come to #피크닠 now! Let’s discover that shining destiny together!',
      name: 'fortune_share_message',
      desc: '',
      args: [artist_name],
    );
  }

  /// `#picnic #신년운세 #Fourtuneteller`
  String get fortune_share_hashtag {
    return Intl.message(
      '#picnic #신년운세 #Fourtuneteller',
      name: 'fortune_share_hashtag',
      desc: '',
      args: [],
    );
  }

  /// `What percentage is my shining chemistry compatibility with #{artist_name}} ? My heart is racing!`
  String compatibility_share_message(Object artist_name) {
    return Intl.message(
      'What percentage is my shining chemistry compatibility with #$artist_name} ? My heart is racing!',
      name: 'compatibility_share_message',
      desc: '',
      args: [artist_name],
    );
  }

  /// `#Picnic #피크닠 #아이돌궁합 #Goonghap #피크닠궁합`
  String get compatibility_share_hashtag {
    return Intl.message(
      '#Picnic #피크닠 #아이돌궁합 #Goonghap #피크닠궁합',
      name: 'compatibility_share_hashtag',
      desc: '',
      args: [],
    );
  }

  /// `The unsubscribe was processed successfully.`
  String get withdrawal_success {
    return Intl.message(
      'The unsubscribe was processed successfully.',
      name: 'withdrawal_success',
      desc: '',
      args: [],
    );
  }

  /// `To prevent traffic surges, total usage is limited to 10,000 at a time.`
  String get voting_limit_text {
    return Intl.message(
      'To prevent traffic surges, total usage is limited to 10,000 at a time.',
      name: 'voting_limit_text',
      desc: '',
      args: [],
    );
  }

  /// `Only up to 10,000 is allowed.`
  String get voting_limit_warning {
    return Intl.message(
      'Only up to 10,000 is allowed.',
      name: 'voting_limit_warning',
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
