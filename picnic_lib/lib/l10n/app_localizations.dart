import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @achieve.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achieve;

  /// No description provided for @ads_available_time.
  ///
  /// In en, this message translates to:
  /// **'Next available time to watch ads'**
  String get ads_available_time;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @anonymous_mode.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Mode'**
  String get anonymous_mode;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Picnic'**
  String get appTitle;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Picnic'**
  String get app_name;

  /// No description provided for @application_reason_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter application reason (optional)'**
  String get application_reason_hint;

  /// No description provided for @application_reason_label.
  ///
  /// In en, this message translates to:
  /// **'Application Reason'**
  String get application_reason_label;

  /// No description provided for @application_success.
  ///
  /// In en, this message translates to:
  /// **'Vote candidate application has been completed.'**
  String get application_success;

  /// No description provided for @artist_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter artist name'**
  String get artist_name_hint;

  /// No description provided for @artist_name_label.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artist_name_label;

  /// No description provided for @block_user_label.
  ///
  /// In en, this message translates to:
  /// **'Blocking users'**
  String get block_user_label;

  /// No description provided for @bonus_candy_awarded.
  ///
  /// In en, this message translates to:
  /// **'Star candy has been awarded.'**
  String get bonus_candy_awarded;

  /// No description provided for @button_apply_as_candidate.
  ///
  /// In en, this message translates to:
  /// **'Candidate Application'**
  String get button_apply_as_candidate;

  /// No description provided for @button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get button_cancel;

  /// No description provided for @button_complete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get button_complete;

  /// No description provided for @button_login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get button_login;

  /// No description provided for @button_ok.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get button_ok;

  /// No description provided for @button_pic_pic_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get button_pic_pic_save;

  /// No description provided for @candy_disappear_next_month.
  ///
  /// In en, this message translates to:
  /// **'Expiring Bonus Starchies 😢'**
  String get candy_disappear_next_month;

  /// No description provided for @candy_usage_policy_contents.
  ///
  /// In en, this message translates to:
  /// **'Bonus Star Candy earned in the current month will expire on the 15th of the following month.'**
  String get candy_usage_policy_contents;

  /// No description provided for @candy_usage_policy_contents2.
  ///
  /// In en, this message translates to:
  /// **'When using Star Candy, Star Candy that is about to expire is prioritized.'**
  String get candy_usage_policy_contents2;

  /// No description provided for @candy_usage_policy_guide.
  ///
  /// In en, this message translates to:
  /// **'*Bonuses will disappear the month after they are earned!'**
  String get candy_usage_policy_guide;

  /// No description provided for @candy_usage_policy_guide_button.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get candy_usage_policy_guide_button;

  /// No description provided for @candy_usage_policy_title.
  ///
  /// In en, this message translates to:
  /// **'Starchies Usage Policy'**
  String get candy_usage_policy_title;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get common_fail;

  /// No description provided for @common_retry_label.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_retry_label;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_text_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data is available.'**
  String get common_text_no_data;

  /// No description provided for @common_text_no_search_result.
  ///
  /// In en, this message translates to:
  /// **'No search results found.'**
  String get common_text_no_search_result;

  /// No description provided for @common_text_search_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during the search.'**
  String get common_text_search_error;

  /// No description provided for @common_text_search_recent_label.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get common_text_search_recent_label;

  /// No description provided for @common_text_search_result_label.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get common_text_search_result_label;

  /// No description provided for @compatibility_activities_title.
  ///
  /// In en, this message translates to:
  /// **'Suggested activities'**
  String get compatibility_activities_title;

  /// No description provided for @compatibility_agree_checkbox.
  ///
  /// In en, this message translates to:
  /// **'I agree to store my gender and birthday information in my profile.'**
  String get compatibility_agree_checkbox;

  /// No description provided for @compatibility_analyze_start.
  ///
  /// In en, this message translates to:
  /// **'Start compatibility analysis'**
  String get compatibility_analyze_start;

  /// No description provided for @compatibility_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing compatibility.'**
  String get compatibility_analyzing;

  /// No description provided for @compatibility_analyzing_prepare.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get compatibility_analyzing_prepare;

  /// No description provided for @compatibility_birthday.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get compatibility_birthday;

  /// No description provided for @compatibility_birthtime.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get compatibility_birthtime;

  /// No description provided for @compatibility_birthtime_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Increase accuracy!'**
  String get compatibility_birthtime_subtitle;

  /// No description provided for @compatibility_couple_style.
  ///
  /// In en, this message translates to:
  /// **'Couple styles'**
  String get compatibility_couple_style;

  /// No description provided for @compatibility_duplicate_data_message.
  ///
  /// In en, this message translates to:
  /// **'Compatibility data with the same conditions already exists.'**
  String get compatibility_duplicate_data_message;

  /// No description provided for @compatibility_duplicate_data_title.
  ///
  /// In en, this message translates to:
  /// **'Compatibility data that already exists'**
  String get compatibility_duplicate_data_title;

  /// No description provided for @compatibility_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get compatibility_gender;

  /// No description provided for @compatibility_gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get compatibility_gender_female;

  /// No description provided for @compatibility_gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get compatibility_gender_male;

  /// No description provided for @compatibility_idol_style.
  ///
  /// In en, this message translates to:
  /// **'Idol Styles'**
  String get compatibility_idol_style;

  /// No description provided for @compatibility_new_compatibility.
  ///
  /// In en, this message translates to:
  /// **'Calculate New Goong-Hap'**
  String get compatibility_new_compatibility;

  /// No description provided for @compatibility_new_compatibility_ask.
  ///
  /// In en, this message translates to:
  /// **'Want to see a new Goong-Hap?'**
  String get compatibility_new_compatibility_ask;

  /// No description provided for @compatibility_page_title.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibility_page_title;

  /// No description provided for @compatibility_perfect_score_exists.
  ///
  /// In en, this message translates to:
  /// **'Please note that the compatibility data for this condition has already earned rewards, so we are unable to award additional rewards.'**
  String get compatibility_perfect_score_exists;

  /// No description provided for @compatibility_perfect_score_exists_title.
  ///
  /// In en, this message translates to:
  /// **'Already Winning Matches Data'**
  String get compatibility_perfect_score_exists_title;

  /// No description provided for @compatibility_purchase_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Use 100 Star Candy to check Goong-Hap results.'**
  String get compatibility_purchase_confirm_message;

  /// No description provided for @compatibility_purchase_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Purchase with Star Candy'**
  String get compatibility_purchase_confirm_title;

  /// No description provided for @compatibility_purchase_message.
  ///
  /// In en, this message translates to:
  /// **'If I want to know the Goong-hap score between me and the {artistName}?'**
  String compatibility_purchase_message(Object artistName);

  /// No description provided for @compatibility_remain_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Remaining Star Candy'**
  String get compatibility_remain_star_candy;

  /// No description provided for @compatibility_result_not_found.
  ///
  /// In en, this message translates to:
  /// **'It\'s not Goong-Hap 😔.'**
  String get compatibility_result_not_found;

  /// No description provided for @compatibility_share_hashtag.
  ///
  /// In en, this message translates to:
  /// **'#Picnic #피크닠 #아이돌궁합 #Goonghap #피크닠궁합'**
  String get compatibility_share_hashtag;

  /// No description provided for @compatibility_share_message.
  ///
  /// In en, this message translates to:
  /// **'What percentage is my shining chemistry compatibility with {artistName} ? My heart is racing!'**
  String compatibility_share_message(Object artistName);

  /// No description provided for @compatibility_snackbar_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get compatibility_snackbar_error;

  /// No description provided for @compatibility_snackbar_need_birthday.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth.'**
  String get compatibility_snackbar_need_birthday;

  /// No description provided for @compatibility_snackbar_need_birthtime.
  ///
  /// In en, this message translates to:
  /// **'Please enter your birth time.'**
  String get compatibility_snackbar_need_birthtime;

  /// No description provided for @compatibility_snackbar_need_gender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender.'**
  String get compatibility_snackbar_need_gender;

  /// No description provided for @compatibility_snackbar_need_profile_save_agree.
  ///
  /// In en, this message translates to:
  /// **'Give your consent to save your profile.'**
  String get compatibility_snackbar_need_profile_save_agree;

  /// No description provided for @compatibility_snackbar_start.
  ///
  /// In en, this message translates to:
  /// **'Start analyzing compatibility.'**
  String get compatibility_snackbar_start;

  /// No description provided for @compatibility_status_completed.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get compatibility_status_completed;

  /// No description provided for @compatibility_status_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get compatibility_status_error;

  /// No description provided for @compatibility_status_input.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get compatibility_status_input;

  /// No description provided for @compatibility_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get compatibility_status_pending;

  /// No description provided for @compatibility_style_title.
  ///
  /// In en, this message translates to:
  /// **'Compatibility styles'**
  String get compatibility_style_title;

  /// No description provided for @compatibility_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Compatibility summary'**
  String get compatibility_summary_title;

  /// No description provided for @compatibility_time_slot1.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rat|(23:30-01:29)|🐀'**
  String get compatibility_time_slot1;

  /// No description provided for @compatibility_time_slot10.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rooster|(17:30-19:29)|🐔'**
  String get compatibility_time_slot10;

  /// No description provided for @compatibility_time_slot11.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Dog|(19:30-21:29)|🐕'**
  String get compatibility_time_slot11;

  /// No description provided for @compatibility_time_slot12.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Boar|(21:30-23:29)|🐖'**
  String get compatibility_time_slot12;

  /// No description provided for @compatibility_time_slot2.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Ox|(01:30-03:29)|🐂'**
  String get compatibility_time_slot2;

  /// No description provided for @compatibility_time_slot3.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Tiger|(03:30-05:29)|🐅'**
  String get compatibility_time_slot3;

  /// No description provided for @compatibility_time_slot4.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rabbit|(05:30-07:29)|🐇'**
  String get compatibility_time_slot4;

  /// No description provided for @compatibility_time_slot5.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Dragon|(07:30-09:29)|🐉'**
  String get compatibility_time_slot5;

  /// No description provided for @compatibility_time_slot6.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Snake|(09:30-11:29)|🐍'**
  String get compatibility_time_slot6;

  /// No description provided for @compatibility_time_slot7.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Horse|(11:30-13:29)|🐎'**
  String get compatibility_time_slot7;

  /// No description provided for @compatibility_time_slot8.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Sheep|(13:30-15:29)|🐑'**
  String get compatibility_time_slot8;

  /// No description provided for @compatibility_time_slot9.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Monkey|(15:30-17:29)|🐒'**
  String get compatibility_time_slot9;

  /// No description provided for @compatibility_time_slot_unknown.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get compatibility_time_slot_unknown;

  /// No description provided for @compatibility_tips_title.
  ///
  /// In en, this message translates to:
  /// **'Compatibility tips'**
  String get compatibility_tips_title;

  /// No description provided for @compatibility_user_style.
  ///
  /// In en, this message translates to:
  /// **'User Styles'**
  String get compatibility_user_style;

  /// No description provided for @compatibility_waiting_message.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get compatibility_waiting_message;

  /// No description provided for @compatibility_warning_exit.
  ///
  /// In en, this message translates to:
  /// **'If you leave the screen, you\'ll need to do the analysis again.'**
  String get compatibility_warning_exit;

  /// No description provided for @dialog_button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_button_cancel;

  /// No description provided for @dialog_button_ok.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialog_button_ok;

  /// No description provided for @dialog_caution.
  ///
  /// In en, this message translates to:
  /// **'🚫 Caution 🚫'**
  String get dialog_caution;

  /// No description provided for @dialog_content_ads_exhausted.
  ///
  /// In en, this message translates to:
  /// **'All ads have been exhausted. Please try again next time.'**
  String get dialog_content_ads_exhausted;

  /// No description provided for @dialog_content_ads_loading.
  ///
  /// In en, this message translates to:
  /// **'Ads are loading.'**
  String get dialog_content_ads_loading;

  /// No description provided for @dialog_content_ads_retrying.
  ///
  /// In en, this message translates to:
  /// **'The ad is reloading. Please try again in a moment.'**
  String get dialog_content_ads_retrying;

  /// No description provided for @dialog_content_login_required.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get dialog_content_login_required;

  /// No description provided for @dialog_login_required_description.
  ///
  /// In en, this message translates to:
  /// **'You need to login to use this feature. Would you like to login?'**
  String get dialog_login_required_description;

  /// No description provided for @dialog_message_can_resignup.
  ///
  /// In en, this message translates to:
  /// **'When you can rejoin if you cancel your membership now?'**
  String get dialog_message_can_resignup;

  /// No description provided for @dialog_message_purchase_canceled.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been canceled.'**
  String get dialog_message_purchase_canceled;

  /// No description provided for @dialog_message_purchase_failed.
  ///
  /// In en, this message translates to:
  /// **'There was an error with your purchase, please try again later.'**
  String get dialog_message_purchase_failed;

  /// No description provided for @dialog_message_purchase_success.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been successfully completed.'**
  String get dialog_message_purchase_success;

  /// No description provided for @dialog_purchases_fail.
  ///
  /// In en, this message translates to:
  /// **'The purchase failed.'**
  String get dialog_purchases_fail;

  /// No description provided for @dialog_purchases_success.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is complete.'**
  String get dialog_purchases_success;

  /// No description provided for @dialog_title_ads_exhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted all ads'**
  String get dialog_title_ads_exhausted;

  /// No description provided for @dialog_title_vote_fail.
  ///
  /// In en, this message translates to:
  /// **'Voting Failed'**
  String get dialog_title_vote_fail;

  /// No description provided for @dialog_will_delete_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Star Candies to be deleted'**
  String get dialog_will_delete_star_candy;

  /// No description provided for @dialog_withdraw_button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Let me think about this one more time.'**
  String get dialog_withdraw_button_cancel;

  /// No description provided for @dialog_withdraw_button_ok.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribing'**
  String get dialog_withdraw_button_ok;

  /// No description provided for @dialog_withdraw_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during unsubscribe.'**
  String get dialog_withdraw_error;

  /// No description provided for @dialog_withdraw_message.
  ///
  /// In en, this message translates to:
  /// **'If you cancel your membership, your star candy and account information on Picnic will be deleted immediately, and your existing information and data will not be restored when you rejoin.'**
  String get dialog_withdraw_message;

  /// No description provided for @dialog_withdraw_success.
  ///
  /// In en, this message translates to:
  /// **'The unsubscribe was processed successfully.'**
  String get dialog_withdraw_success;

  /// No description provided for @dialog_withdraw_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get dialog_withdraw_title;

  /// No description provided for @download_android_button.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get download_android_button;

  /// No description provided for @download_apk_button.
  ///
  /// In en, this message translates to:
  /// **'Direct APK Download'**
  String get download_apk_button;

  /// No description provided for @download_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get download_coming_soon;

  /// No description provided for @download_description.
  ///
  /// In en, this message translates to:
  /// **'Voting and media platform for K-Pop artists'**
  String get download_description;

  /// No description provided for @download_feature_media.
  ///
  /// In en, this message translates to:
  /// **'Media Gallery'**
  String get download_feature_media;

  /// No description provided for @download_feature_rewards.
  ///
  /// In en, this message translates to:
  /// **'Reward System'**
  String get download_feature_rewards;

  /// No description provided for @download_feature_voting.
  ///
  /// In en, this message translates to:
  /// **'Artist Voting'**
  String get download_feature_voting;

  /// No description provided for @download_features_title.
  ///
  /// In en, this message translates to:
  /// **'Picnic Key Features'**
  String get download_features_title;

  /// No description provided for @download_ios_button.
  ///
  /// In en, this message translates to:
  /// **'Download on App Store'**
  String get download_ios_button;

  /// No description provided for @download_link_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get download_link_copied;

  /// No description provided for @download_link_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get download_link_copy;

  /// No description provided for @download_page_title.
  ///
  /// In en, this message translates to:
  /// **'Download Picnic App'**
  String get download_page_title;

  /// No description provided for @download_qr_description.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code with your smartphone'**
  String get download_qr_description;

  /// No description provided for @download_qr_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Download with QR Code'**
  String get download_qr_title;

  /// No description provided for @download_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Download the Picnic app now and support your favorite K-Pop artists!'**
  String get download_subtitle;

  /// No description provided for @error_action_failed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while performing the operation.'**
  String get error_action_failed;

  /// No description provided for @error_application_reason_required.
  ///
  /// In en, this message translates to:
  /// **'Application reason is required'**
  String get error_application_reason_required;

  /// No description provided for @error_artist_not_selected.
  ///
  /// In en, this message translates to:
  /// **'Please select an artist'**
  String get error_artist_not_selected;

  /// No description provided for @error_content_parse.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while parsing the content.'**
  String get error_content_parse;

  /// No description provided for @error_delete_post.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting the post.'**
  String get error_delete_post;

  /// No description provided for @error_invalid_data.
  ///
  /// In en, this message translates to:
  /// **'Invalid data.'**
  String get error_invalid_data;

  /// No description provided for @error_loading_more_comments.
  ///
  /// In en, this message translates to:
  /// **'There was an error loading the comment.'**
  String get error_loading_more_comments;

  /// No description provided for @error_loading_page.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the page.'**
  String get error_loading_page;

  /// No description provided for @error_message_login_failed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login.'**
  String get error_message_login_failed;

  /// No description provided for @error_message_no_user.
  ///
  /// In en, this message translates to:
  /// **'The membership information doesn\'t exist.'**
  String get error_message_no_user;

  /// No description provided for @error_message_withdrawal.
  ///
  /// In en, this message translates to:
  /// **'A member who has unsubscribed.'**
  String get error_message_withdrawal;

  /// No description provided for @error_network_connection.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection.'**
  String get error_network_connection;

  /// No description provided for @error_request_timeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get error_request_timeout;

  /// No description provided for @error_title.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get error_title;

  /// No description provided for @error_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get error_unknown;

  /// No description provided for @exception_auth_message_apple_invalid_response.
  ///
  /// In en, this message translates to:
  /// **'We received an invalid response from the Apple server.\nPlease try again.'**
  String get exception_auth_message_apple_invalid_response;

  /// No description provided for @exception_auth_message_apple_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.\nPlease try again.'**
  String get exception_auth_message_apple_sign_in_failed;

  /// No description provided for @exception_auth_message_common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Your login has been canceled.'**
  String get exception_auth_message_common_cancel;

  /// No description provided for @exception_auth_message_common_invalid_token.
  ///
  /// In en, this message translates to:
  /// **'The authentication token is invalid.\nPlease try again.'**
  String get exception_auth_message_common_invalid_token;

  /// No description provided for @exception_auth_message_common_network.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection.'**
  String get exception_auth_message_common_network;

  /// No description provided for @exception_auth_message_common_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred during login.\nPlease try again in a moment.'**
  String get exception_auth_message_common_unknown;

  /// No description provided for @exception_auth_message_common_unsupported_provider.
  ///
  /// In en, this message translates to:
  /// **'This login method is not supported.'**
  String get exception_auth_message_common_unsupported_provider;

  /// No description provided for @exception_auth_message_google_google_play_service.
  ///
  /// In en, this message translates to:
  /// **'A Google Play Services error has occurred.\nPlease update Google Play Services or restart your device.'**
  String get exception_auth_message_google_google_play_service;

  /// No description provided for @exception_auth_message_kakao_not_supported.
  ///
  /// In en, this message translates to:
  /// **'I can\'t sign in with the KakaoTalk app.\nTry signing in with your Kakao account.'**
  String get exception_auth_message_kakao_not_supported;

  /// No description provided for @faq_category_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get faq_category_account;

  /// No description provided for @faq_category_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get faq_category_all;

  /// No description provided for @faq_category_etc.
  ///
  /// In en, this message translates to:
  /// **'Etc'**
  String get faq_category_etc;

  /// No description provided for @faq_category_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get faq_category_general;

  /// No description provided for @faq_category_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get faq_category_payment;

  /// No description provided for @faq_category_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get faq_category_service;

  /// No description provided for @fortune_advice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get fortune_advice;

  /// No description provided for @fortune_button_title.
  ///
  /// In en, this message translates to:
  /// **'My Artist\'s Fortune teller'**
  String get fortune_button_title;

  /// No description provided for @fortune_career.
  ///
  /// In en, this message translates to:
  /// **'Business fortunes'**
  String get fortune_career;

  /// No description provided for @fortune_health.
  ///
  /// In en, this message translates to:
  /// **'Health fortunes'**
  String get fortune_health;

  /// No description provided for @fortune_honor.
  ///
  /// In en, this message translates to:
  /// **'Honor'**
  String get fortune_honor;

  /// No description provided for @fortune_lack_of_star_candy_message.
  ///
  /// In en, this message translates to:
  /// **'Reward Star Candies cannot be used here. 😥'**
  String get fortune_lack_of_star_candy_message;

  /// No description provided for @fortune_lack_of_star_candy_title.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough Star Candy. Moving to the shop screen.'**
  String get fortune_lack_of_star_candy_title;

  /// No description provided for @fortune_lucky_color.
  ///
  /// In en, this message translates to:
  /// **'Lucky colors'**
  String get fortune_lucky_color;

  /// No description provided for @fortune_lucky_days.
  ///
  /// In en, this message translates to:
  /// **'Lucky days of the week'**
  String get fortune_lucky_days;

  /// No description provided for @fortune_lucky_direction.
  ///
  /// In en, this message translates to:
  /// **'Direction of Fortune'**
  String get fortune_lucky_direction;

  /// No description provided for @fortune_lucky_keyword.
  ///
  /// In en, this message translates to:
  /// **'Lucky keywords'**
  String get fortune_lucky_keyword;

  /// No description provided for @fortune_lucky_number.
  ///
  /// In en, this message translates to:
  /// **'Lucky numbers'**
  String get fortune_lucky_number;

  /// No description provided for @fortune_money.
  ///
  /// In en, this message translates to:
  /// **'Fortune Telling'**
  String get fortune_money;

  /// No description provided for @fortune_month1.
  ///
  /// In en, this message translates to:
  /// **'Fortune for January'**
  String get fortune_month1;

  /// No description provided for @fortune_month10.
  ///
  /// In en, this message translates to:
  /// **'Fortune for October'**
  String get fortune_month10;

  /// No description provided for @fortune_month11.
  ///
  /// In en, this message translates to:
  /// **'Fortune for November'**
  String get fortune_month11;

  /// No description provided for @fortune_month12.
  ///
  /// In en, this message translates to:
  /// **'Fortune for December'**
  String get fortune_month12;

  /// No description provided for @fortune_month2.
  ///
  /// In en, this message translates to:
  /// **'Fortune for February'**
  String get fortune_month2;

  /// No description provided for @fortune_month3.
  ///
  /// In en, this message translates to:
  /// **'Fortune for March'**
  String get fortune_month3;

  /// No description provided for @fortune_month4.
  ///
  /// In en, this message translates to:
  /// **'Fortune for April'**
  String get fortune_month4;

  /// No description provided for @fortune_month5.
  ///
  /// In en, this message translates to:
  /// **'Fortune for May'**
  String get fortune_month5;

  /// No description provided for @fortune_month6.
  ///
  /// In en, this message translates to:
  /// **'Fortune for June'**
  String get fortune_month6;

  /// No description provided for @fortune_month7.
  ///
  /// In en, this message translates to:
  /// **'Fortune for July'**
  String get fortune_month7;

  /// No description provided for @fortune_month8.
  ///
  /// In en, this message translates to:
  /// **'Fortune for August'**
  String get fortune_month8;

  /// No description provided for @fortune_month9.
  ///
  /// In en, this message translates to:
  /// **'Fortune for September'**
  String get fortune_month9;

  /// No description provided for @fortune_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Fortune'**
  String get fortune_monthly;

  /// No description provided for @fortune_purchase_by_one_click.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get fortune_purchase_by_one_click;

  /// No description provided for @fortune_purchase_by_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Check with StarCandy'**
  String get fortune_purchase_by_star_candy;

  /// No description provided for @fortune_relationship.
  ///
  /// In en, this message translates to:
  /// **'Interpersonal'**
  String get fortune_relationship;

  /// No description provided for @fortune_share_hashtag.
  ///
  /// In en, this message translates to:
  /// **'#picnic #신년운세 #Fourtuneteller'**
  String get fortune_share_hashtag;

  /// No description provided for @fortune_share_message.
  ///
  /// In en, this message translates to:
  /// **'Curious about {artistName}\'s 2025 fortune? Come to #피크닠 now! Let\'s discover that shining destiny together!'**
  String fortune_share_message(Object artistName);

  /// No description provided for @fortune_title.
  ///
  /// In en, this message translates to:
  /// **'Fortune of {year}'**
  String fortune_title(Object year);

  /// No description provided for @fortune_total_title.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Fortune'**
  String get fortune_total_title;

  /// No description provided for @fortune_with_me.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap with me'**
  String get fortune_with_me;

  /// No description provided for @group_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name (optional)'**
  String get group_name_hint;

  /// No description provided for @group_name_label.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get group_name_label;

  /// No description provided for @hint_library_add.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get hint_library_add;

  /// No description provided for @hint_nickname_input.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname.'**
  String get hint_nickname_input;

  /// No description provided for @image_save_success.
  ///
  /// In en, this message translates to:
  /// **'The image has been saved.'**
  String get image_save_success;

  /// No description provided for @label_ads_exceeded.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the number of times you can watch ads for this button.'**
  String get label_ads_exceeded;

  /// No description provided for @label_ads_get_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Get Star Candy from Ads'**
  String get label_ads_get_star_candy;

  /// No description provided for @label_ads_limits.
  ///
  /// In en, this message translates to:
  /// **'{hourly} per hour, {daily} per day'**
  String label_ads_limits(Object daily, Object hourly);

  /// No description provided for @label_ads_load_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ad. Please try again.'**
  String get label_ads_load_fail;

  /// No description provided for @label_ads_load_timeout.
  ///
  /// In en, this message translates to:
  /// **'Ad loading timed out. Please try again.'**
  String get label_ads_load_timeout;

  /// No description provided for @label_ads_next_available_time.
  ///
  /// In en, this message translates to:
  /// **'When the next ad will be available.'**
  String get label_ads_next_available_time;

  /// No description provided for @label_ads_reward_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to get reward. Please try again.'**
  String get label_ads_reward_fail;

  /// No description provided for @label_ads_sdk_init_fail.
  ///
  /// In en, this message translates to:
  /// **'SDK initialization failed. Please try again.'**
  String get label_ads_sdk_init_fail;

  /// No description provided for @label_ads_show_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to show ad. Please try again.'**
  String get label_ads_show_fail;

  /// No description provided for @label_agreement_privacy.
  ///
  /// In en, this message translates to:
  /// **'Consent to the collection and use of personal information'**
  String get label_agreement_privacy;

  /// No description provided for @label_agreement_terms.
  ///
  /// In en, this message translates to:
  /// **'Accept the Terms of Use'**
  String get label_agreement_terms;

  /// No description provided for @label_album_add.
  ///
  /// In en, this message translates to:
  /// **'Add a new album'**
  String get label_album_add;

  /// No description provided for @label_area_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get label_area_filter_all;

  /// No description provided for @label_area_filter_kpop.
  ///
  /// In en, this message translates to:
  /// **'K-POP'**
  String get label_area_filter_kpop;

  /// No description provided for @label_area_filter_musical.
  ///
  /// In en, this message translates to:
  /// **'K-MUSICAL'**
  String get label_area_filter_musical;

  /// No description provided for @label_article_comment_empty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get label_article_comment_empty;

  /// No description provided for @label_asia_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Asia Pick'**
  String get label_asia_recommendation;

  /// No description provided for @label_bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get label_bonus;

  /// No description provided for @label_button_agreement.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get label_button_agreement;

  /// No description provided for @label_button_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get label_button_close;

  /// No description provided for @label_button_disagreement.
  ///
  /// In en, this message translates to:
  /// **'Non-Consent'**
  String get label_button_disagreement;

  /// No description provided for @label_button_mission_and_charge.
  ///
  /// In en, this message translates to:
  /// **'Mission and charge'**
  String get label_button_mission_and_charge;

  /// No description provided for @label_button_recharge.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get label_button_recharge;

  /// No description provided for @label_button_save_vote_paper.
  ///
  /// In en, this message translates to:
  /// **'Save your ballot'**
  String get label_button_save_vote_paper;

  /// No description provided for @label_button_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get label_button_share;

  /// No description provided for @label_button_vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get label_button_vote;

  /// No description provided for @label_button_vote_ended.
  ///
  /// In en, this message translates to:
  /// **'Vote Ended'**
  String get label_button_vote_ended;

  /// No description provided for @label_button_vote_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Vote Upcoming'**
  String get label_button_vote_upcoming;

  /// No description provided for @label_button_watch_and_charge.
  ///
  /// In en, this message translates to:
  /// **'Viewing and charging for ads'**
  String get label_button_watch_and_charge;

  /// No description provided for @label_celeb_ask_to_you.
  ///
  /// In en, this message translates to:
  /// **'The Artist Asks You!'**
  String get label_celeb_ask_to_you;

  /// No description provided for @label_celeb_gallery.
  ///
  /// In en, this message translates to:
  /// **'Artist Gallery'**
  String get label_celeb_gallery;

  /// No description provided for @label_celeb_recommend.
  ///
  /// In en, this message translates to:
  /// **'Artist recommendations'**
  String get label_celeb_recommend;

  /// No description provided for @label_checkbox_entire_use.
  ///
  /// In en, this message translates to:
  /// **'Full Use'**
  String get label_checkbox_entire_use;

  /// No description provided for @label_current_language.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get label_current_language;

  /// No description provided for @label_draw_image.
  ///
  /// In en, this message translates to:
  /// **'Chance to win a random image'**
  String get label_draw_image;

  /// No description provided for @label_dropdown_oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get label_dropdown_oldest;

  /// No description provided for @label_dropdown_recent.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get label_dropdown_recent;

  /// No description provided for @label_find_celeb.
  ///
  /// In en, this message translates to:
  /// **'Find more artists'**
  String get label_find_celeb;

  /// No description provided for @label_gallery_tab_article.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get label_gallery_tab_article;

  /// No description provided for @label_gallery_tab_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get label_gallery_tab_chat;

  /// No description provided for @label_global_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Global Pick'**
  String get label_global_recommendation;

  /// No description provided for @label_hint_comment.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment.'**
  String get label_hint_comment;

  /// No description provided for @label_input_input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get label_input_input;

  /// No description provided for @label_korean_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Korean Pick'**
  String get label_korean_recommendation;

  /// No description provided for @label_last_provider.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get label_last_provider;

  /// No description provided for @label_library_save.
  ///
  /// In en, this message translates to:
  /// **'Save the library'**
  String get label_library_save;

  /// No description provided for @label_library_tab_ai_photo.
  ///
  /// In en, this message translates to:
  /// **'AI Photos'**
  String get label_library_tab_ai_photo;

  /// No description provided for @label_library_tab_library.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get label_library_tab_library;

  /// No description provided for @label_library_tab_pic.
  ///
  /// In en, this message translates to:
  /// **'PIC'**
  String get label_library_tab_pic;

  /// No description provided for @label_list_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get label_list_more;

  /// No description provided for @label_loading_ads.
  ///
  /// In en, this message translates to:
  /// **'Loading ad'**
  String get label_loading_ads;

  /// No description provided for @label_loading_ads_fail.
  ///
  /// In en, this message translates to:
  /// **'Ads fail to load'**
  String get label_loading_ads_fail;

  /// No description provided for @label_login_with_apple.
  ///
  /// In en, this message translates to:
  /// **'Login with Apple'**
  String get label_login_with_apple;

  /// No description provided for @label_login_with_google.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get label_login_with_google;

  /// No description provided for @label_login_with_kakao.
  ///
  /// In en, this message translates to:
  /// **'Login with Kakao'**
  String get label_login_with_kakao;

  /// No description provided for @label_login_with_wechat.
  ///
  /// In en, this message translates to:
  /// **'Login with WeChat'**
  String get label_login_with_wechat;

  /// No description provided for @label_mission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get label_mission;

  /// No description provided for @label_mission_get_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Get Star Candy from Missions'**
  String get label_mission_get_star_candy;

  /// No description provided for @label_mission_short.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get label_mission_short;

  /// No description provided for @label_moveto_celeb_gallery.
  ///
  /// In en, this message translates to:
  /// **'Go to the Artist Gallery'**
  String get label_moveto_celeb_gallery;

  /// Charge history menu for admin users
  ///
  /// In en, this message translates to:
  /// **'Charges (Admin)'**
  String get label_mypage_charge_history;

  /// No description provided for @label_mypage_customer_center.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get label_mypage_customer_center;

  /// No description provided for @label_mypage_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get label_mypage_faq;

  /// No description provided for @label_mypage_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get label_mypage_logout;

  /// No description provided for @label_mypage_membership_history.
  ///
  /// In en, this message translates to:
  /// **'Membership history'**
  String get label_mypage_membership_history;

  /// No description provided for @label_mypage_my_artist.
  ///
  /// In en, this message translates to:
  /// **'My Artists'**
  String get label_mypage_my_artist;

  /// No description provided for @label_mypage_no_artist.
  ///
  /// In en, this message translates to:
  /// **'No Artist'**
  String get label_mypage_no_artist;

  /// No description provided for @label_mypage_notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get label_mypage_notice;

  /// No description provided for @label_mypage_picnic_id.
  ///
  /// In en, this message translates to:
  /// **'だろう。'**
  String get label_mypage_picnic_id;

  /// No description provided for @label_mypage_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get label_mypage_privacy_policy;

  /// No description provided for @label_mypage_setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get label_mypage_setting;

  /// No description provided for @label_mypage_should_login.
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get label_mypage_should_login;

  /// No description provided for @label_mypage_terms_of_use.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get label_mypage_terms_of_use;

  /// No description provided for @label_mypage_vote_history.
  ///
  /// In en, this message translates to:
  /// **'StarCandy Voting History'**
  String get label_mypage_vote_history;

  /// No description provided for @label_mypage_withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get label_mypage_withdrawal;

  /// No description provided for @label_no_ads.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get label_no_ads;

  /// No description provided for @label_no_celeb.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any artists bookmarked yet!'**
  String get label_no_celeb;

  /// No description provided for @label_pic_chart.
  ///
  /// In en, this message translates to:
  /// **'Pic Chart'**
  String get label_pic_chart;

  /// No description provided for @label_pic_image_cropping.
  ///
  /// In en, this message translates to:
  /// **'Crop an image'**
  String get label_pic_image_cropping;

  /// No description provided for @label_pic_pic_initializing_camera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get label_pic_pic_initializing_camera;

  /// No description provided for @label_pic_pic_save_gallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get label_pic_pic_save_gallery;

  /// No description provided for @label_pic_pic_synthesizing_image.
  ///
  /// In en, this message translates to:
  /// **'Compositing an image...'**
  String get label_pic_pic_synthesizing_image;

  /// No description provided for @label_popup_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get label_popup_close;

  /// No description provided for @label_popup_hide_7days.
  ///
  /// In en, this message translates to:
  /// **'Don\'t view for 7 days'**
  String get label_popup_hide_7days;

  /// No description provided for @label_read_more_comment.
  ///
  /// In en, this message translates to:
  /// **'More comments'**
  String get label_read_more_comment;

  /// No description provided for @label_reply.
  ///
  /// In en, this message translates to:
  /// **'Replying to a reply'**
  String get label_reply;

  /// No description provided for @label_retry.
  ///
  /// In en, this message translates to:
  /// **'Retrying'**
  String get label_retry;

  /// No description provided for @label_reward_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get label_reward_location;

  /// No description provided for @label_reward_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get label_reward_overview;

  /// No description provided for @label_reward_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get label_reward_size;

  /// No description provided for @label_screen_title_agreement.
  ///
  /// In en, this message translates to:
  /// **'Accept the terms'**
  String get label_screen_title_agreement;

  /// No description provided for @label_setting_alarm.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get label_setting_alarm;

  /// No description provided for @label_setting_appinfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get label_setting_appinfo;

  /// No description provided for @label_setting_current_version.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get label_setting_current_version;

  /// No description provided for @label_setting_event_alarm.
  ///
  /// In en, this message translates to:
  /// **'Event notifications'**
  String get label_setting_event_alarm;

  /// No description provided for @label_setting_event_alarm_desc.
  ///
  /// In en, this message translates to:
  /// **'Events and happenings.'**
  String get label_setting_event_alarm_desc;

  /// No description provided for @label_setting_language.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get label_setting_language;

  /// No description provided for @label_setting_push_alarm.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get label_setting_push_alarm;

  /// No description provided for @label_setting_recent_version.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get label_setting_recent_version;

  /// No description provided for @label_setting_recent_version_up_to_date.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get label_setting_recent_version_up_to_date;

  /// No description provided for @label_setting_remove_cache.
  ///
  /// In en, this message translates to:
  /// **'Delete cache memory'**
  String get label_setting_remove_cache;

  /// No description provided for @label_setting_remove_cache_complete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get label_setting_remove_cache_complete;

  /// No description provided for @label_setting_storage.
  ///
  /// In en, this message translates to:
  /// **'Manage storage'**
  String get label_setting_storage;

  /// No description provided for @label_setting_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get label_setting_update;

  /// No description provided for @label_star_candy_pouch.
  ///
  /// In en, this message translates to:
  /// **'Star Candy Pouch'**
  String get label_star_candy_pouch;

  /// No description provided for @label_tab_buy_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Buy star candy'**
  String get label_tab_buy_star_candy;

  /// No description provided for @label_tab_free_charge_station.
  ///
  /// In en, this message translates to:
  /// **'Free charging stations'**
  String get label_tab_free_charge_station;

  /// No description provided for @label_tab_my_artist.
  ///
  /// In en, this message translates to:
  /// **'MyArtist'**
  String get label_tab_my_artist;

  /// No description provided for @label_tab_search_my_artist.
  ///
  /// In en, this message translates to:
  /// **'Find MyArtist'**
  String get label_tab_search_my_artist;

  /// No description provided for @label_tabbar_picchart_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily charts'**
  String get label_tabbar_picchart_daily;

  /// No description provided for @label_tabbar_picchart_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Charts'**
  String get label_tabbar_picchart_monthly;

  /// No description provided for @label_tabbar_picchart_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly charts'**
  String get label_tabbar_picchart_weekly;

  /// No description provided for @label_tabbar_vote_active.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get label_tabbar_vote_active;

  /// No description provided for @label_tabbar_vote_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get label_tabbar_vote_all;

  /// No description provided for @label_tabbar_vote_end.
  ///
  /// In en, this message translates to:
  /// **'\nClosed'**
  String get label_tabbar_vote_end;

  /// No description provided for @label_tabbar_vote_image.
  ///
  /// In en, this message translates to:
  /// **'Image Vote'**
  String get label_tabbar_vote_image;

  /// No description provided for @label_tabbar_vote_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get label_tabbar_vote_upcoming;

  /// No description provided for @label_time_ago_day.
  ///
  /// In en, this message translates to:
  /// **'{day} days ago'**
  String label_time_ago_day(Object day);

  /// No description provided for @label_time_ago_hour.
  ///
  /// In en, this message translates to:
  /// **'{hour} hours ago'**
  String label_time_ago_hour(Object hour);

  /// No description provided for @label_time_ago_minute.
  ///
  /// In en, this message translates to:
  /// **'{minute} minutes ago'**
  String label_time_ago_minute(Object minute);

  /// No description provided for @label_time_ago_right_now.
  ///
  /// In en, this message translates to:
  /// **'Just a moment ago'**
  String get label_time_ago_right_now;

  /// No description provided for @label_title_comment.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get label_title_comment;

  /// No description provided for @label_title_report.
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get label_title_report;

  /// No description provided for @label_unlimited_rewards.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rewards'**
  String get label_unlimited_rewards;

  /// No description provided for @label_various_rewards.
  ///
  /// In en, this message translates to:
  /// **'Various rewards'**
  String get label_various_rewards;

  /// No description provided for @label_vote_achieve.
  ///
  /// In en, this message translates to:
  /// **'Achievement Vote'**
  String get label_vote_achieve;

  /// No description provided for @label_vote_birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get label_vote_birthday;

  /// No description provided for @label_vote_comback.
  ///
  /// In en, this message translates to:
  /// **'Comeback Vote'**
  String get label_vote_comback;

  /// No description provided for @label_vote_debut.
  ///
  /// In en, this message translates to:
  /// **'Debut'**
  String get label_vote_debut;

  /// No description provided for @label_vote_end.
  ///
  /// In en, this message translates to:
  /// **'Close the poll'**
  String get label_vote_end;

  /// No description provided for @label_vote_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get label_vote_image;

  /// No description provided for @label_vote_reward_list.
  ///
  /// In en, this message translates to:
  /// **'Rewards list'**
  String get label_vote_reward_list;

  /// No description provided for @label_vote_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get label_vote_screen_title;

  /// No description provided for @label_vote_shining.
  ///
  /// In en, this message translates to:
  /// **'Shining Vote'**
  String get label_vote_shining;

  /// No description provided for @label_vote_tab_birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday polls'**
  String get label_vote_tab_birthday;

  /// No description provided for @label_vote_tab_pic.
  ///
  /// In en, this message translates to:
  /// **'PIC voting'**
  String get label_vote_tab_pic;

  /// No description provided for @label_vote_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Until voting begins'**
  String get label_vote_upcoming;

  /// No description provided for @label_vote_vote_gather.
  ///
  /// In en, this message translates to:
  /// **'Collecting votes'**
  String get label_vote_vote_gather;

  /// No description provided for @label_watch_ads.
  ///
  /// In en, this message translates to:
  /// **'View ads'**
  String get label_watch_ads;

  /// No description provided for @label_watch_ads_short.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get label_watch_ads_short;

  /// No description provided for @lable_my_celeb.
  ///
  /// In en, this message translates to:
  /// **'My Artists'**
  String get lable_my_celeb;

  /// No description provided for @login_simple_login.
  ///
  /// In en, this message translates to:
  /// **'Simple Login'**
  String get login_simple_login;

  /// No description provided for @login_simple_login_guide.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? You\'ll be automatically signed up with your social login above'**
  String get login_simple_login_guide;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Find special moments at a picnic'**
  String get login_title;

  /// No description provided for @message_agreement_success.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of the terms is complete.'**
  String get message_agreement_success;

  /// No description provided for @message_error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get message_error_occurred;

  /// No description provided for @message_noitem_vote_active.
  ///
  /// In en, this message translates to:
  /// **'There are currently no active polls.'**
  String get message_noitem_vote_active;

  /// No description provided for @message_noitem_vote_end.
  ///
  /// In en, this message translates to:
  /// **'There are currently no closed polls.'**
  String get message_noitem_vote_end;

  /// No description provided for @message_noitem_vote_upcoming.
  ///
  /// In en, this message translates to:
  /// **'There are currently no upcoming polls.'**
  String get message_noitem_vote_upcoming;

  /// No description provided for @message_pic_pic_save_fail.
  ///
  /// In en, this message translates to:
  /// **'Saving the image failed.'**
  String get message_pic_pic_save_fail;

  /// No description provided for @message_pic_pic_save_success.
  ///
  /// In en, this message translates to:
  /// **'The image has been saved.'**
  String get message_pic_pic_save_success;

  /// No description provided for @message_report_confirm.
  ///
  /// In en, this message translates to:
  /// **'Want to report?'**
  String get message_report_confirm;

  /// No description provided for @message_report_ok.
  ///
  /// In en, this message translates to:
  /// **'The report is complete.'**
  String get message_report_ok;

  /// No description provided for @message_setting_remove_cache.
  ///
  /// In en, this message translates to:
  /// **'Cache memory deletion is complete.'**
  String get message_setting_remove_cache;

  /// No description provided for @message_update_nickname_fail.
  ///
  /// In en, this message translates to:
  /// **'Nickname change failed.\nPlease select a different nickname.'**
  String get message_update_nickname_fail;

  /// No description provided for @message_update_nickname_success.
  ///
  /// In en, this message translates to:
  /// **'Your nickname has been successfully changed.'**
  String get message_update_nickname_success;

  /// No description provided for @message_vote_is_ended.
  ///
  /// In en, this message translates to:
  /// **'Poll closed'**
  String get message_vote_is_ended;

  /// No description provided for @message_vote_is_upcoming.
  ///
  /// In en, this message translates to:
  /// **'This is an upcoming vote.'**
  String get message_vote_is_upcoming;

  /// No description provided for @my_info.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get my_info;

  /// No description provided for @mypage_comment.
  ///
  /// In en, this message translates to:
  /// **'Manage comments'**
  String get mypage_comment;

  /// No description provided for @mypage_language.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get mypage_language;

  /// No description provided for @mypage_purchases.
  ///
  /// In en, this message translates to:
  /// **'My purchases'**
  String get mypage_purchases;

  /// No description provided for @mypage_setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mypage_setting;

  /// No description provided for @mypage_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription information'**
  String get mypage_subscription;

  /// No description provided for @nav_ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get nav_ads;

  /// No description provided for @nav_board.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get nav_board;

  /// No description provided for @nav_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get nav_gallery;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_library.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get nav_library;

  /// No description provided for @nav_media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get nav_media;

  /// No description provided for @nav_my.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get nav_my;

  /// No description provided for @nav_picchart.
  ///
  /// In en, this message translates to:
  /// **'PIC Charts'**
  String get nav_picchart;

  /// No description provided for @nav_purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get nav_purchases;

  /// No description provided for @nav_rewards.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get nav_rewards;

  /// No description provided for @nav_setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_setting;

  /// No description provided for @nav_store.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get nav_store;

  /// No description provided for @nav_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get nav_subscription;

  /// No description provided for @nav_vote.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get nav_vote;

  /// No description provided for @nickname_validation_error.
  ///
  /// In en, this message translates to:
  /// **'20 characters or less, excluding special characters.'**
  String get nickname_validation_error;

  /// No description provided for @no_search_results.
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get no_search_results;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @page_title_mypage.
  ///
  /// In en, this message translates to:
  /// **'My Page'**
  String get page_title_mypage;

  /// No description provided for @page_title_myprofile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get page_title_myprofile;

  /// No description provided for @page_title_post_write.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get page_title_post_write;

  /// No description provided for @page_title_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get page_title_privacy;

  /// No description provided for @page_title_setting.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get page_title_setting;

  /// No description provided for @page_title_terms_of_use.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get page_title_terms_of_use;

  /// No description provided for @page_title_vote_detail.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get page_title_vote_detail;

  /// No description provided for @page_title_vote_gather.
  ///
  /// In en, this message translates to:
  /// **'Collecting votes'**
  String get page_title_vote_gather;

  /// No description provided for @patch_check.
  ///
  /// In en, this message translates to:
  /// **'Checking for patches'**
  String get patch_check;

  /// No description provided for @patch_error.
  ///
  /// In en, this message translates to:
  /// **'Patch failed'**
  String get patch_error;

  /// No description provided for @patch_install.
  ///
  /// In en, this message translates to:
  /// **'Installing patch'**
  String get patch_install;

  /// No description provided for @patch_restart_app.
  ///
  /// In en, this message translates to:
  /// **'Restarting app'**
  String get patch_restart_app;

  /// No description provided for @popup_label_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get popup_label_delete;

  /// No description provided for @post_anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous posting'**
  String get post_anonymous;

  /// No description provided for @post_ask_go_to_temporary_save_list.
  ///
  /// In en, this message translates to:
  /// **'Want to go to the Drafts list?'**
  String get post_ask_go_to_temporary_save_list;

  /// No description provided for @post_board_already_exist.
  ///
  /// In en, this message translates to:
  /// **'A board that already exists.'**
  String get post_board_already_exist;

  /// No description provided for @post_board_create_request_complete.
  ///
  /// In en, this message translates to:
  /// **'Your request to open a board is complete.'**
  String get post_board_create_request_complete;

  /// No description provided for @post_board_create_request_condition.
  ///
  /// In en, this message translates to:
  /// **'*Only one minor board can be applied per ID.'**
  String get post_board_create_request_condition;

  /// No description provided for @post_board_create_request_label.
  ///
  /// In en, this message translates to:
  /// **'Request to open a board'**
  String get post_board_create_request_label;

  /// No description provided for @post_board_create_request_reviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing a request to open a board'**
  String get post_board_create_request_reviewing;

  /// No description provided for @post_board_request_label.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get post_board_request_label;

  /// No description provided for @post_cannot_open_youtube.
  ///
  /// In en, this message translates to:
  /// **'I can\'t open Youtube.'**
  String get post_cannot_open_youtube;

  /// No description provided for @post_comment_action_show_original.
  ///
  /// In en, this message translates to:
  /// **'View full text'**
  String get post_comment_action_show_original;

  /// No description provided for @post_comment_action_show_translation.
  ///
  /// In en, this message translates to:
  /// **'View translations'**
  String get post_comment_action_show_translation;

  /// No description provided for @post_comment_action_translate.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get post_comment_action_translate;

  /// No description provided for @post_comment_content_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get post_comment_content_more;

  /// No description provided for @post_comment_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the comment?'**
  String get post_comment_delete_confirm;

  /// No description provided for @post_comment_delete_fail.
  ///
  /// In en, this message translates to:
  /// **'Comment deletion failed.'**
  String get post_comment_delete_fail;

  /// No description provided for @post_comment_deleted_comment.
  ///
  /// In en, this message translates to:
  /// **'This is a deleted comment.'**
  String get post_comment_deleted_comment;

  /// No description provided for @post_comment_like_processing_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to process like.'**
  String get post_comment_like_processing_fail;

  /// No description provided for @post_comment_loading_fail.
  ///
  /// In en, this message translates to:
  /// **'Comment failed to load.'**
  String get post_comment_loading_fail;

  /// No description provided for @post_comment_register_fail.
  ///
  /// In en, this message translates to:
  /// **'Comment registration failed.'**
  String get post_comment_register_fail;

  /// No description provided for @post_comment_registered_comment.
  ///
  /// In en, this message translates to:
  /// **'Your comment has been registered.'**
  String get post_comment_registered_comment;

  /// No description provided for @post_comment_reported_comment.
  ///
  /// In en, this message translates to:
  /// **'This is a reported comment.'**
  String get post_comment_reported_comment;

  /// No description provided for @post_comment_translate_complete.
  ///
  /// In en, this message translates to:
  /// **'The translation is complete.'**
  String get post_comment_translate_complete;

  /// No description provided for @post_comment_translate_fail.
  ///
  /// In en, this message translates to:
  /// **'The translation failed.'**
  String get post_comment_translate_fail;

  /// No description provided for @post_comment_translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get post_comment_translated;

  /// No description provided for @post_comment_write_label.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get post_comment_write_label;

  /// No description provided for @post_content_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter something.'**
  String get post_content_placeholder;

  /// No description provided for @post_delete_scrap_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the scrap?'**
  String get post_delete_scrap_confirm;

  /// No description provided for @post_delete_scrap_title.
  ///
  /// In en, this message translates to:
  /// **'Delete a scrap'**
  String get post_delete_scrap_title;

  /// No description provided for @post_flagged.
  ///
  /// In en, this message translates to:
  /// **'Contains inappropriate content'**
  String get post_flagged;

  /// No description provided for @post_go_to_boards.
  ///
  /// In en, this message translates to:
  /// **'Go to the board'**
  String get post_go_to_boards;

  /// No description provided for @post_header_publish.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get post_header_publish;

  /// No description provided for @post_header_temporary_save.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get post_header_temporary_save;

  /// No description provided for @post_hint_title.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get post_hint_title;

  /// No description provided for @post_hyperlink.
  ///
  /// In en, this message translates to:
  /// **'Hyperlinks'**
  String get post_hyperlink;

  /// No description provided for @post_insert_link.
  ///
  /// In en, this message translates to:
  /// **'Inserting links'**
  String get post_insert_link;

  /// No description provided for @post_loading_post_fail.
  ///
  /// In en, this message translates to:
  /// **'The post failed to load.'**
  String get post_loading_post_fail;

  /// No description provided for @post_minor_board_condition.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description of at least 5 characters and no more than 20 characters.'**
  String get post_minor_board_condition;

  /// No description provided for @post_minor_board_create_request_message.
  ///
  /// In en, this message translates to:
  /// **'* Message requesting to open a board.'**
  String get post_minor_board_create_request_message;

  /// No description provided for @post_minor_board_create_request_message_condition.
  ///
  /// In en, this message translates to:
  /// **'Please include at least 10 characters in your message requesting to open a board.'**
  String get post_minor_board_create_request_message_condition;

  /// No description provided for @post_minor_board_create_request_message_input.
  ///
  /// In en, this message translates to:
  /// **'Enter a message requesting to open a board.'**
  String get post_minor_board_create_request_message_input;

  /// No description provided for @post_minor_board_description.
  ///
  /// In en, this message translates to:
  /// **'Minor bulletin board descriptions'**
  String get post_minor_board_description;

  /// No description provided for @post_minor_board_description_input.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description for your minor board.'**
  String get post_minor_board_description_input;

  /// No description provided for @post_minor_board_name.
  ///
  /// In en, this message translates to:
  /// **'Minor board name'**
  String get post_minor_board_name;

  /// No description provided for @post_minor_board_name_input.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your minor board.'**
  String get post_minor_board_name_input;

  /// No description provided for @post_my_compatibilities.
  ///
  /// In en, this message translates to:
  /// **'My compatibility'**
  String get post_my_compatibilities;

  /// No description provided for @post_my_written_post.
  ///
  /// In en, this message translates to:
  /// **'Posts I\'ve written'**
  String get post_my_written_post;

  /// No description provided for @post_my_written_reply.
  ///
  /// In en, this message translates to:
  /// **'Comments I wrote'**
  String get post_my_written_reply;

  /// No description provided for @post_my_written_scrap.
  ///
  /// In en, this message translates to:
  /// **'My Scraps'**
  String get post_my_written_scrap;

  /// No description provided for @post_no_comment.
  ///
  /// In en, this message translates to:
  /// **'No comments.'**
  String get post_no_comment;

  /// No description provided for @post_not_found.
  ///
  /// In en, this message translates to:
  /// **'No posts were found.'**
  String get post_not_found;

  /// No description provided for @post_replying_comment.
  ///
  /// In en, this message translates to:
  /// **'Replying to {nickname}...'**
  String post_replying_comment(Object nickname);

  /// No description provided for @post_report_fail.
  ///
  /// In en, this message translates to:
  /// **'The report failed.'**
  String get post_report_fail;

  /// No description provided for @post_report_label.
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get post_report_label;

  /// No description provided for @post_report_other_input.
  ///
  /// In en, this message translates to:
  /// **'Please enter any other reason.'**
  String get post_report_other_input;

  /// No description provided for @post_report_reason_1.
  ///
  /// In en, this message translates to:
  /// **'Unsavory posts'**
  String get post_report_reason_1;

  /// No description provided for @post_report_reason_2.
  ///
  /// In en, this message translates to:
  /// **'Sexist, racist posts'**
  String get post_report_reason_2;

  /// No description provided for @post_report_reason_3.
  ///
  /// In en, this message translates to:
  /// **'Posts containing offensive profanity'**
  String get post_report_reason_3;

  /// No description provided for @post_report_reason_4.
  ///
  /// In en, this message translates to:
  /// **'Advertising/Promotional Posts'**
  String get post_report_reason_4;

  /// No description provided for @post_report_reason_5.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get post_report_reason_5;

  /// No description provided for @post_report_reason_input.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for your report.'**
  String get post_report_reason_input;

  /// No description provided for @post_report_reason_label.
  ///
  /// In en, this message translates to:
  /// **'Reasons for reporting'**
  String get post_report_reason_label;

  /// No description provided for @post_report_success.
  ///
  /// In en, this message translates to:
  /// **'The report is complete.'**
  String get post_report_success;

  /// No description provided for @post_temporary_save_complete.
  ///
  /// In en, this message translates to:
  /// **'Draft complete.'**
  String get post_temporary_save_complete;

  /// No description provided for @post_title_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get post_title_placeholder;

  /// No description provided for @post_write_board_post.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get post_write_board_post;

  /// No description provided for @post_write_post_recommend_write.
  ///
  /// In en, this message translates to:
  /// **'Please create a post.'**
  String get post_write_post_recommend_write;

  /// No description provided for @post_youtube_link.
  ///
  /// In en, this message translates to:
  /// **'YouTube link'**
  String get post_youtube_link;

  /// No description provided for @purchase_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase_confirm_button;

  /// No description provided for @purchase_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Would you like to purchase the following item?'**
  String get purchase_confirm_message;

  /// No description provided for @purchase_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Purchase Confirmation'**
  String get purchase_confirm_title;

  /// No description provided for @purchase_cooldown_message.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get purchase_cooldown_message;

  /// No description provided for @purchase_in_progress_message.
  ///
  /// In en, this message translates to:
  /// **'Purchase is in progress. Please wait a moment.'**
  String get purchase_in_progress_message;

  /// No description provided for @purchase_initializing_message.
  ///
  /// In en, this message translates to:
  /// **'Initializing. Please try again in a moment.'**
  String get purchase_initializing_message;

  /// No description provided for @purchase_payment_amount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get purchase_payment_amount;

  /// No description provided for @purchase_restore_success_message.
  ///
  /// In en, this message translates to:
  /// **'Purchase restoration completed.\\nPlease check your star candy balance.'**
  String get purchase_restore_success_message;

  /// No description provided for @purchase_restore_wait_message.
  ///
  /// In en, this message translates to:
  /// **'Purchase is in progress. Please try again after completion.'**
  String get purchase_restore_wait_message;

  /// No description provided for @purchase_timeout_message.
  ///
  /// In en, this message translates to:
  /// **'Purchase processing is taking too long.\\nPlease try again later.'**
  String get purchase_timeout_message;

  /// No description provided for @purchase_web_message.
  ///
  /// In en, this message translates to:
  /// **'This is the payment window for those who can\'t pay with the app.\n Please copy the random ID in advance.\n After copying it, click the button below to proceed with the payment.'**
  String get purchase_web_message;

  /// No description provided for @qna_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get qna_actions;

  /// No description provided for @qna_answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get qna_answer;

  /// No description provided for @qna_answered_at.
  ///
  /// In en, this message translates to:
  /// **'Answered at'**
  String get qna_answered_at;

  /// No description provided for @qna_answered_by.
  ///
  /// In en, this message translates to:
  /// **'Answered by'**
  String get qna_answered_by;

  /// No description provided for @qna_attached_files.
  ///
  /// In en, this message translates to:
  /// **'Attached Files'**
  String get qna_attached_files;

  /// No description provided for @qna_attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get qna_attachments;

  /// No description provided for @qna_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get qna_cancel;

  /// No description provided for @qna_content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get qna_content;

  /// No description provided for @qna_content_hint.
  ///
  /// In en, this message translates to:
  /// **'Please enter your inquiry in detail'**
  String get qna_content_hint;

  /// No description provided for @qna_content_min_length.
  ///
  /// In en, this message translates to:
  /// **'Inquiry content must be at least 10 characters'**
  String get qna_content_min_length;

  /// No description provided for @qna_content_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter inquiry content'**
  String get qna_content_required;

  /// No description provided for @qna_create_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit inquiry:'**
  String get qna_create_failed;

  /// No description provided for @qna_create_page_title.
  ///
  /// In en, this message translates to:
  /// **'Create Inquiry'**
  String get qna_create_page_title;

  /// No description provided for @qna_create_success.
  ///
  /// In en, this message translates to:
  /// **'Inquiry has been successfully submitted'**
  String get qna_create_success;

  /// No description provided for @qna_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get qna_delete;

  /// No description provided for @qna_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get qna_delete_confirm;

  /// No description provided for @qna_delete_confirm_content.
  ///
  /// In en, this message translates to:
  /// **'Delete this inquiry?\nIt cannot be recovered after deletion.'**
  String get qna_delete_confirm_content;

  /// No description provided for @qna_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Inquiry'**
  String get qna_delete_confirm_title;

  /// No description provided for @qna_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get qna_delete_failed;

  /// No description provided for @qna_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Inquiry has been deleted'**
  String get qna_delete_success;

  /// No description provided for @qna_detail_page_title.
  ///
  /// In en, this message translates to:
  /// **'Inquiry Details'**
  String get qna_detail_page_title;

  /// No description provided for @qna_download_file.
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get qna_download_file;

  /// No description provided for @qna_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get qna_edit;

  /// No description provided for @qna_file_attach_label.
  ///
  /// In en, this message translates to:
  /// **'File Attachment'**
  String get qna_file_attach_label;

  /// No description provided for @qna_file_select.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get qna_file_select;

  /// No description provided for @qna_file_type_document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get qna_file_type_document;

  /// No description provided for @qna_file_type_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get qna_file_type_image;

  /// No description provided for @qna_file_type_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get qna_file_type_other;

  /// No description provided for @qna_file_upload_info.
  ///
  /// In en, this message translates to:
  /// **'• Maximum 10MB upload allowed\n• Supported formats: Images (jpg, png, gif), Documents (pdf, doc, txt)'**
  String get qna_file_upload_info;

  /// No description provided for @qna_file_uploading_button.
  ///
  /// In en, this message translates to:
  /// **'File Uploading...'**
  String get qna_file_uploading_button;

  /// No description provided for @qna_loading_error.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading'**
  String get qna_loading_error;

  /// No description provided for @qna_login_required.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get qna_login_required;

  /// No description provided for @qna_login_required_create.
  ///
  /// In en, this message translates to:
  /// **'To create QnA\nplease login first'**
  String get qna_login_required_create;

  /// No description provided for @qna_login_required_detail.
  ///
  /// In en, this message translates to:
  /// **'To view QnA details\nplease login first'**
  String get qna_login_required_detail;

  /// No description provided for @qna_login_required_service.
  ///
  /// In en, this message translates to:
  /// **'To use QnA service\nplease login first'**
  String get qna_login_required_service;

  /// No description provided for @qna_mark_resolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as Resolved'**
  String get qna_mark_resolved;

  /// No description provided for @qna_mark_resolved_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change status'**
  String get qna_mark_resolved_failed;

  /// No description provided for @qna_mark_resolved_success.
  ///
  /// In en, this message translates to:
  /// **'Changed to resolved'**
  String get qna_mark_resolved_success;

  /// No description provided for @qna_no_answer_yet.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get qna_no_answer_yet;

  /// No description provided for @qna_no_inquiries.
  ///
  /// In en, this message translates to:
  /// **'No inquiry history'**
  String get qna_no_inquiries;

  /// No description provided for @qna_no_inquiries_subtitle.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions\nfeel free to contact us anytime'**
  String get qna_no_inquiries_subtitle;

  /// No description provided for @qna_page_title.
  ///
  /// In en, this message translates to:
  /// **'QnA Inquiry (Admin)'**
  String get qna_page_title;

  /// No description provided for @qna_privacy_notice.
  ///
  /// In en, this message translates to:
  /// **'Information you enter will be collected and used for inquiry processing. Please check our privacy policy for details.'**
  String get qna_privacy_notice;

  /// No description provided for @qna_question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get qna_question;

  /// No description provided for @qna_refresh_pull.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get qna_refresh_pull;

  /// No description provided for @qna_statistics_answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get qna_statistics_answered;

  /// No description provided for @qna_statistics_pending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Response'**
  String get qna_statistics_pending;

  /// No description provided for @qna_statistics_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get qna_statistics_resolved;

  /// No description provided for @qna_statistics_title.
  ///
  /// In en, this message translates to:
  /// **'Inquiry Status'**
  String get qna_statistics_title;

  /// No description provided for @qna_status_answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get qna_status_answered;

  /// No description provided for @qna_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Response'**
  String get qna_status_pending;

  /// No description provided for @qna_status_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get qna_status_resolved;

  /// No description provided for @qna_status_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get qna_status_closed;

  /// No description provided for @qna_submit_button.
  ///
  /// In en, this message translates to:
  /// **'Submit Inquiry'**
  String get qna_submit_button;

  /// No description provided for @qna_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get qna_title;

  /// No description provided for @qna_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a brief summary of your inquiry'**
  String get qna_title_hint;

  /// No description provided for @qna_title_min_length.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters'**
  String get qna_title_min_length;

  /// No description provided for @qna_title_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get qna_title_required;

  /// No description provided for @qna_upload_complete.
  ///
  /// In en, this message translates to:
  /// **'Upload Complete'**
  String get qna_upload_complete;

  /// No description provided for @qna_upload_waiting.
  ///
  /// In en, this message translates to:
  /// **'Upload Waiting'**
  String get qna_upload_waiting;

  /// No description provided for @qna_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get qna_uploading;

  /// No description provided for @qna_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Please check your input.'**
  String get qna_validation_failed;

  /// No description provided for @qna_write_inquiry.
  ///
  /// In en, this message translates to:
  /// **'New Inquiry'**
  String get qna_write_inquiry;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get replies;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get reward;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @share_image_fail.
  ///
  /// In en, this message translates to:
  /// **'Image sharing failed'**
  String get share_image_fail;

  /// No description provided for @share_image_success.
  ///
  /// In en, this message translates to:
  /// **'Shared image successfully'**
  String get share_image_success;

  /// No description provided for @share_no_twitter.
  ///
  /// In en, this message translates to:
  /// **'X app is missing.'**
  String get share_no_twitter;

  /// No description provided for @share_twitter.
  ///
  /// In en, this message translates to:
  /// **'Share on Twitter'**
  String get share_twitter;

  /// No description provided for @submit_application.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submit_application;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @text_achievement.
  ///
  /// In en, this message translates to:
  /// **'🎉 You\'ve reached \${count} goals so far! 🎉'**
  String text_achievement(Object count);

  /// No description provided for @text_ads_random.
  ///
  /// In en, this message translates to:
  /// **'Viewing ads and collecting random images.'**
  String get text_ads_random;

  /// No description provided for @text_bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get text_bonus;

  /// No description provided for @text_bookmark_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unbookmark'**
  String get text_bookmark_failed;

  /// No description provided for @text_bookmark_over_5.
  ///
  /// In en, this message translates to:
  /// **'You can have up to five bookmarks'**
  String get text_bookmark_over_5;

  /// No description provided for @text_comming_soon_pic_chart1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Peek Charts!\nSee you in November 2024!'**
  String get text_comming_soon_pic_chart1;

  /// No description provided for @text_comming_soon_pic_chart2.
  ///
  /// In en, this message translates to:
  /// **'Pie charts are a new chart unique to Peeknick that reflects daily, weekly, and monthly scores.\nPeeknick\'s new chart that reflects daily, weekly, and monthly scores.'**
  String get text_comming_soon_pic_chart2;

  /// No description provided for @text_comming_soon_pic_chart3.
  ///
  /// In en, this message translates to:
  /// **'Get a real-time reflection\nartist\'s brand reputation in real-time!'**
  String get text_comming_soon_pic_chart3;

  /// No description provided for @text_comming_soon_pic_chart_title.
  ///
  /// In en, this message translates to:
  /// **'What is a PicChart?'**
  String get text_comming_soon_pic_chart_title;

  /// No description provided for @text_community_board_search.
  ///
  /// In en, this message translates to:
  /// **'Searching the Artist Board'**
  String get text_community_board_search;

  /// No description provided for @text_community_post_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get text_community_post_search;

  /// No description provided for @text_copied_address.
  ///
  /// In en, this message translates to:
  /// **'The address has been copied.'**
  String get text_copied_address;

  /// No description provided for @text_dialog_ad_dismissed.
  ///
  /// In en, this message translates to:
  /// **'The ad stopped midway through.'**
  String get text_dialog_ad_dismissed;

  /// No description provided for @text_dialog_ad_failed_to_show.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ads.'**
  String get text_dialog_ad_failed_to_show;

  /// No description provided for @text_dialog_star_candy_received.
  ///
  /// In en, this message translates to:
  /// **'Star candy has been awarded.'**
  String get text_dialog_star_candy_received;

  /// No description provided for @text_dialog_vote_amount_should_not_zero.
  ///
  /// In en, this message translates to:
  /// **'The number of votes cannot be zero.'**
  String get text_dialog_vote_amount_should_not_zero;

  /// No description provided for @text_draw_image.
  ///
  /// In en, this message translates to:
  /// **'Confirmed ownership of 1 image from the entire gallery.'**
  String get text_draw_image;

  /// No description provided for @text_hint_search.
  ///
  /// In en, this message translates to:
  /// **'Search for artists'**
  String get text_hint_search;

  /// No description provided for @text_moveto_celeb_gallery.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the selected artist\'s home.'**
  String get text_moveto_celeb_gallery;

  /// No description provided for @text_need_recharge.
  ///
  /// In en, this message translates to:
  /// **'Requires charging.'**
  String get text_need_recharge;

  /// No description provided for @text_no_artist.
  ///
  /// In en, this message translates to:
  /// **'No artist'**
  String get text_no_artist;

  /// No description provided for @text_no_search_result.
  ///
  /// In en, this message translates to:
  /// **'No search results.'**
  String get text_no_search_result;

  /// No description provided for @text_purchase_vat_included.
  ///
  /// In en, this message translates to:
  /// **'*Price includes VAT.'**
  String get text_purchase_vat_included;

  /// No description provided for @text_star_candy.
  ///
  /// In en, this message translates to:
  /// **'Star Candy'**
  String get text_star_candy;

  /// No description provided for @text_star_candy_with_bonus.
  ///
  /// In en, this message translates to:
  /// **'{num1} + {num1} Bonuses'**
  String text_star_candy_with_bonus(Object num1);

  /// No description provided for @text_this_time_vote.
  ///
  /// In en, this message translates to:
  /// **'This Vote'**
  String get text_this_time_vote;

  /// No description provided for @text_vote_complete.
  ///
  /// In en, this message translates to:
  /// **'Voting complete'**
  String get text_vote_complete;

  /// No description provided for @text_vote_countdown_end.
  ///
  /// In en, this message translates to:
  /// **'Until End'**
  String get text_vote_countdown_end;

  /// No description provided for @text_vote_countdown_start.
  ///
  /// In en, this message translates to:
  /// **'Until Start'**
  String get text_vote_countdown_start;

  /// No description provided for @text_vote_ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get text_vote_ended;

  /// No description provided for @text_vote_rank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String text_vote_rank(Object rank);

  /// No description provided for @text_vote_rank_in_reward.
  ///
  /// In en, this message translates to:
  /// **'Rank in Rewards'**
  String get text_vote_rank_in_reward;

  /// No description provided for @text_vote_reward.
  ///
  /// In en, this message translates to:
  /// **'{count} reward'**
  String text_vote_reward(Object count);

  /// No description provided for @text_vote_where_is_my_bias.
  ///
  /// In en, this message translates to:
  /// **'Where\'s My Favorite?'**
  String get text_vote_where_is_my_bias;

  /// No description provided for @time_days_ago.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get time_days_ago;

  /// No description provided for @time_hours_ago.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get time_hours_ago;

  /// No description provided for @time_just_now.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get time_just_now;

  /// No description provided for @time_minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get time_minutes_ago;

  /// No description provided for @time_unit_day.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get time_unit_day;

  /// No description provided for @time_unit_hour.
  ///
  /// In en, this message translates to:
  /// **'H'**
  String get time_unit_hour;

  /// No description provided for @time_unit_minute.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get time_unit_minute;

  /// No description provided for @time_unit_second.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get time_unit_second;

  /// No description provided for @title_dialog_library_add.
  ///
  /// In en, this message translates to:
  /// **'Add a new album'**
  String get title_dialog_library_add;

  /// No description provided for @title_dialog_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get title_dialog_success;

  /// No description provided for @title_select_language.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get title_select_language;

  /// No description provided for @toast_max_five_celeb.
  ///
  /// In en, this message translates to:
  /// **'You can add up to five of your own artists.'**
  String get toast_max_five_celeb;

  /// No description provided for @update_button.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update_button;

  /// No description provided for @update_cannot_open_appstore.
  ///
  /// In en, this message translates to:
  /// **'I can\'t open the app store.'**
  String get update_cannot_open_appstore;

  /// No description provided for @update_recommend_text.
  ///
  /// In en, this message translates to:
  /// **'A new version ({version}) is available.'**
  String update_recommend_text(Object version);

  /// No description provided for @update_required_text.
  ///
  /// In en, this message translates to:
  /// **'You need to update to a new version ({version}).'**
  String update_required_text(Object version);

  /// No description provided for @update_required_title.
  ///
  /// In en, this message translates to:
  /// **'An update is required.'**
  String get update_required_title;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @vote_item_request_addition_request.
  ///
  /// In en, this message translates to:
  /// **'Vote artists addition request'**
  String get vote_item_request_addition_request;

  /// No description provided for @vote_item_request_already_applied_artist.
  ///
  /// In en, this message translates to:
  /// **'You have already applied for this artist.'**
  String get vote_item_request_already_applied_artist;

  /// No description provided for @vote_item_request_already_registered.
  ///
  /// In en, this message translates to:
  /// **'Already registered'**
  String get vote_item_request_already_registered;

  /// No description provided for @vote_item_request_artist_name_missing.
  ///
  /// In en, this message translates to:
  /// **'Artist name missing'**
  String get vote_item_request_artist_name_missing;

  /// No description provided for @vote_item_request_button.
  ///
  /// In en, this message translates to:
  /// **'Apply for Vote Candidate'**
  String get vote_item_request_button;

  /// No description provided for @vote_item_request_can_apply.
  ///
  /// In en, this message translates to:
  /// **'Can apply'**
  String get vote_item_request_can_apply;

  /// No description provided for @vote_item_request_count.
  ///
  /// In en, this message translates to:
  /// **'count'**
  String get vote_item_request_count;

  /// No description provided for @vote_item_request_current_item_request.
  ///
  /// In en, this message translates to:
  /// **'Current Artist Request'**
  String get vote_item_request_current_item_request;

  /// No description provided for @vote_item_request_item_request_count.
  ///
  /// In en, this message translates to:
  /// **'{count} artists requests'**
  String vote_item_request_item_request_count(Object count);

  /// No description provided for @vote_item_request_no_item_request_yet.
  ///
  /// In en, this message translates to:
  /// **'No artist request yet'**
  String get vote_item_request_no_item_request_yet;

  /// No description provided for @vote_item_request_search_artist.
  ///
  /// In en, this message translates to:
  /// **'Search Artist'**
  String get vote_item_request_search_artist;

  /// No description provided for @vote_item_request_search_artist_hint.
  ///
  /// In en, this message translates to:
  /// **'Search for artist or group'**
  String get vote_item_request_search_artist_hint;

  /// No description provided for @vote_item_request_search_artist_prompt.
  ///
  /// In en, this message translates to:
  /// **'Search for an artist to apply'**
  String get vote_item_request_search_artist_prompt;

  /// No description provided for @vote_item_request_status.
  ///
  /// In en, this message translates to:
  /// **'Request status'**
  String get vote_item_request_status;

  /// No description provided for @vote_item_request_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get vote_item_request_status_approved;

  /// No description provided for @vote_item_request_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get vote_item_request_status_cancelled;

  /// No description provided for @vote_item_request_status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get vote_item_request_status_in_progress;

  /// No description provided for @vote_item_request_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get vote_item_request_status_pending;

  /// No description provided for @vote_item_request_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get vote_item_request_status_rejected;

  /// No description provided for @vote_item_request_status_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get vote_item_request_status_unknown;

  /// No description provided for @vote_item_request_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get vote_item_request_submit;

  /// No description provided for @vote_item_request_title.
  ///
  /// In en, this message translates to:
  /// **'Vote Artist Request'**
  String get vote_item_request_title;

  /// No description provided for @vote_item_request_total_item_requests.
  ///
  /// In en, this message translates to:
  /// **'Total {count} artists requests'**
  String vote_item_request_total_item_requests(Object count);

  /// No description provided for @vote_item_request_user_info_not_found.
  ///
  /// In en, this message translates to:
  /// **'User information not found.'**
  String get vote_item_request_user_info_not_found;

  /// No description provided for @vote_period.
  ///
  /// In en, this message translates to:
  /// **'Vote Period'**
  String get vote_period;

  /// No description provided for @vote_result_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save the results'**
  String get vote_result_save_button;

  /// No description provided for @vote_result_share_button.
  ///
  /// In en, this message translates to:
  /// **'Share your results'**
  String get vote_result_share_button;

  /// No description provided for @vote_share_message.
  ///
  /// In en, this message translates to:
  /// **'Voted!'**
  String get vote_share_message;

  /// No description provided for @voting_limit_text.
  ///
  /// In en, this message translates to:
  /// **'To prevent traffic surges, total usage is limited to 10,000 at a time.'**
  String get voting_limit_text;

  /// No description provided for @voting_limit_warning.
  ///
  /// In en, this message translates to:
  /// **'Only up to 10,000 is allowed.'**
  String get voting_limit_warning;

  /// No description provided for @voting_share_benefit_text.
  ///
  /// In en, this message translates to:
  /// **'Get 1 bonus star candy for every 100 votes and share!'**
  String get voting_share_benefit_text;

  /// No description provided for @withdrawal_success.
  ///
  /// In en, this message translates to:
  /// **'The unsubscribe was processed successfully.'**
  String get withdrawal_success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @just_now.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get just_now;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @ban_title.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get ban_title;

  /// No description provided for @ban_message.
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily suspended due to inappropriate activity.'**
  String get ban_message;

  /// No description provided for @ban_contact.
  ///
  /// In en, this message translates to:
  /// **'Please contact customer service if you have any questions.'**
  String get ban_contact;

  /// No description provided for @compatibility_empty_state_title.
  ///
  /// In en, this message translates to:
  /// **'No compatibility information'**
  String get compatibility_empty_state_title;

  /// No description provided for @compatibility_empty_state_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first compatibility!'**
  String get compatibility_empty_state_subtitle;

  /// No description provided for @network_error_title.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get network_error_title;

  /// No description provided for @network_error_message.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get network_error_message;

  /// No description provided for @notice_pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notice_pinned;

  /// No description provided for @message_agreement_fail.
  ///
  /// In en, this message translates to:
  /// **'Terms agreement required'**
  String get message_agreement_fail;

  /// No description provided for @title_dialog_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get title_dialog_error;

  /// No description provided for @vote_item_request_waiting.
  ///
  /// In en, this message translates to:
  /// **'대기중'**
  String get vote_item_request_waiting;

  /// No description provided for @capture_failed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed'**
  String get capture_failed;

  /// No description provided for @qna_submit_success.
  ///
  /// In en, this message translates to:
  /// **'Your inquiry has been successfully submitted'**
  String get qna_submit_success;

  /// No description provided for @qna_submit_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while submitting your inquiry'**
  String get qna_submit_error;

  /// No description provided for @qna_title_too_short.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 2 characters for the title'**
  String get qna_title_too_short;

  /// No description provided for @qna_content_too_short.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 10 characters for the content'**
  String get qna_content_too_short;

  /// No description provided for @qna_list_title.
  ///
  /// In en, this message translates to:
  /// **'QnA List'**
  String get qna_list_title;

  /// No description provided for @qna_error_message.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get qna_error_message;

  /// No description provided for @qna_empty_list.
  ///
  /// In en, this message translates to:
  /// **'No inquiry history'**
  String get qna_empty_list;

  /// No description provided for @qna_create_first.
  ///
  /// In en, this message translates to:
  /// **'Write your first question'**
  String get qna_create_first;

  /// No description provided for @days_ago.
  ///
  /// In en, this message translates to:
  /// **' days ago'**
  String get days_ago;

  /// No description provided for @hours_ago.
  ///
  /// In en, this message translates to:
  /// **' hours ago'**
  String get hours_ago;

  /// No description provided for @minutes_ago.
  ///
  /// In en, this message translates to:
  /// **' minutes ago'**
  String get minutes_ago;

  /// No description provided for @starCandy100.
  ///
  /// In en, this message translates to:
  /// **'100 Star Candy'**
  String get starCandy100;

  /// No description provided for @starCandy200.
  ///
  /// In en, this message translates to:
  /// **'200 Star Candy'**
  String get starCandy200;

  /// No description provided for @starCandy600.
  ///
  /// In en, this message translates to:
  /// **'600 Star Candy'**
  String get starCandy600;

  /// No description provided for @starCandy1000.
  ///
  /// In en, this message translates to:
  /// **'1,000 Star Candy'**
  String get starCandy1000;

  /// No description provided for @starCandy2000.
  ///
  /// In en, this message translates to:
  /// **'2,000 Star Candy'**
  String get starCandy2000;

  /// No description provided for @starCandy3000.
  ///
  /// In en, this message translates to:
  /// **'3,000 Star Candy'**
  String get starCandy3000;

  /// No description provided for @starCandy4000.
  ///
  /// In en, this message translates to:
  /// **'4,000 Star Candy'**
  String get starCandy4000;

  /// No description provided for @starCandy5000.
  ///
  /// In en, this message translates to:
  /// **'5,000 Star Candy'**
  String get starCandy5000;

  /// No description provided for @update_required_message.
  ///
  /// In en, this message translates to:
  /// **'App update required'**
  String get update_required_message;

  /// No description provided for @vote_item_request_no_search_results.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get vote_item_request_no_search_results;

  /// No description provided for @jma_voting_star_candy_shortage.
  ///
  /// In en, this message translates to:
  /// **'You need {shortage} more star candies.'**
  String jma_voting_star_candy_shortage(Object shortage);

  /// No description provided for @jma_voting_star_candy_multiple_of_three.
  ///
  /// In en, this message translates to:
  /// **'Star Candy can only be used in multiples of 3. Please add {needed} more or reduce by {excess}.'**
  String jma_voting_star_candy_multiple_of_three(Object excess, Object needed);

  /// No description provided for @jma_voting_daily_limit_remaining.
  ///
  /// In en, this message translates to:
  /// **'Today\'s remaining bonus votes: {remaining} times (max {max} times)'**
  String jma_voting_daily_limit_remaining(Object max, Object remaining);

  /// No description provided for @jma_voting_daily_limit_exhausted.
  ///
  /// In en, this message translates to:
  /// **'You have used all bonus votes for today.'**
  String get jma_voting_daily_limit_exhausted;

  /// No description provided for @jma_voting_my_star_candy.
  ///
  /// In en, this message translates to:
  /// **'My Star Candy'**
  String get jma_voting_my_star_candy;

  /// No description provided for @jma_voting_usable_jma_votes.
  ///
  /// In en, this message translates to:
  /// **'Available JMA Votes'**
  String get jma_voting_usable_jma_votes;

  /// No description provided for @jma_voting_use_all.
  ///
  /// In en, this message translates to:
  /// **'Use All'**
  String get jma_voting_use_all;

  /// No description provided for @jma_voting_max_usable.
  ///
  /// In en, this message translates to:
  /// **'Maximum {amount} available'**
  String jma_voting_max_usable(Object amount);

  /// No description provided for @jma_voting_bonus_only.
  ///
  /// In en, this message translates to:
  /// **'Use {amount} bonus Star Candy → {votes} votes'**
  String jma_voting_bonus_only(Object amount, Object votes);

  /// No description provided for @jma_voting_bonus_plus_regular.
  ///
  /// In en, this message translates to:
  /// **'Bonus {bonus} + Star Candy {regular} → {votes} votes'**
  String jma_voting_bonus_plus_regular(
      Object bonus, Object regular, Object votes);

  /// No description provided for @jma_voting_regular_only.
  ///
  /// In en, this message translates to:
  /// **'Star Candy {amount} → {votes} votes'**
  String jma_voting_regular_only(Object amount, Object votes);

  /// No description provided for @jma_voting_input_amount.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount of Star Candy.'**
  String get jma_voting_input_amount;

  /// No description provided for @jma_voting_info_text.
  ///
  /// In en, this message translates to:
  /// **'· 3 Star Candy will be automatically converted to 1 JMA vote\n· Bonus Star Candy can be used up to 5 times per day for JMA voting\n· By participating in voting, you will automatically participate in the JMA concert ticket event'**
  String get jma_voting_info_text;

  /// No description provided for @jma_voting_daily_limit_error.
  ///
  /// In en, this message translates to:
  /// **'You can vote up to 5 times per day.'**
  String get jma_voting_daily_limit_error;

  /// No description provided for @jma_voting_exchange_failed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while exchanging Star Candy. Please try again.'**
  String get jma_voting_exchange_failed;

  /// No description provided for @jma_voting_daily_limit_title.
  ///
  /// In en, this message translates to:
  /// **'Voting Limit'**
  String get jma_voting_daily_limit_title;

  /// No description provided for @jma_voting_exchange_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Exchange Failed'**
  String get jma_voting_exchange_failed_title;

  /// No description provided for @jma_voting_max_votes_exceeded.
  ///
  /// In en, this message translates to:
  /// **'The current maximum possible votes is {maxVotes}.'**
  String jma_voting_max_votes_exceeded(Object maxVotes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
