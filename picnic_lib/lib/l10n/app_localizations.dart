import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_my.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
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
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
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
    Locale('bn'),
    Locale('bn', 'BD'),
    Locale('en'),
    Locale('es'),
    Locale('fil'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('my'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// Auto-generated metadata for key 'achieve'.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achieve;

  /// Auto-generated metadata for key 'ads_available_time'.
  ///
  /// In en, this message translates to:
  /// **'Next available time to watch ads'**
  String get ads_available_time;

  /// Auto-generated metadata for key 'anonymous'.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// Auto-generated metadata for key 'anonymous_mode'.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Mode'**
  String get anonymous_mode;

  /// Auto-generated metadata for key 'block_user_label'.
  ///
  /// In en, this message translates to:
  /// **'Blocking users'**
  String get block_user_label;

  /// Auto-generated metadata for key 'button_cancel'.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get button_cancel;

  /// Auto-generated metadata for key 'button_complete'.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get button_complete;

  /// Auto-generated metadata for key 'button_login'.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get button_login;

  /// Auto-generated metadata for key 'button_ok'.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get button_ok;

  /// Auto-generated metadata for key 'comments'.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Auto-generated metadata for key 'common_all'.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// Auto-generated metadata for key 'common_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get common_fail;

  /// Auto-generated metadata for key 'common_retry_label'.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_retry_label;

  /// Auto-generated metadata for key 'common_success'.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// Auto-generated metadata for key 'common_text_no_data'.
  ///
  /// In en, this message translates to:
  /// **'No data is available.'**
  String get common_text_no_data;

  /// Auto-generated metadata for key 'common_text_no_search_result'.
  ///
  /// In en, this message translates to:
  /// **'No search results found.'**
  String get common_text_no_search_result;

  /// Auto-generated metadata for key 'common_text_search_error'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during the search.'**
  String get common_text_search_error;

  /// Auto-generated metadata for key 'common_text_search_recent_label'.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get common_text_search_recent_label;

  /// Auto-generated metadata for key 'common_text_search_result_label'.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get common_text_search_result_label;

  /// Auto-generated metadata for key 'goonghap_activities_title'.
  ///
  /// In en, this message translates to:
  /// **'Suggested activities'**
  String get goonghap_activities_title;

  /// Error message when artist has no birth date for goonghap
  ///
  /// In en, this message translates to:
  /// **'This artist\'s birth date is not available for goonghap.'**
  String get goonghap_artist_no_birthdate;

  /// Auto-generated metadata for key 'goonghap_agree_checkbox'.
  ///
  /// In en, this message translates to:
  /// **'I agree to store my gender and birthday information in my profile.'**
  String get goonghap_agree_checkbox;

  /// Auto-generated metadata for key 'goonghap_analyze_start'.
  ///
  /// In en, this message translates to:
  /// **'Start Goong-Hap analysis'**
  String get goonghap_analyze_start;

  /// Auto-generated metadata for key 'goonghap_analyzing'.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Goong-Hap.'**
  String get goonghap_analyzing;

  /// Auto-generated metadata for key 'goonghap_analyzing_prepare'.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get goonghap_analyzing_prepare;

  /// Auto-generated metadata for key 'goonghap_birthday'.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get goonghap_birthday;

  /// Auto-generated metadata for key 'goonghap_birthtime'.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get goonghap_birthtime;

  /// Auto-generated metadata for key 'goonghap_couple_style'.
  ///
  /// In en, this message translates to:
  /// **'Couple styles'**
  String get goonghap_couple_style;

  /// Auto-generated metadata for key 'goonghap_duplicate_data_title'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap data that already exists'**
  String get goonghap_duplicate_data_title;

  /// Auto-generated metadata for key 'goonghap_gender'.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get goonghap_gender;

  /// Auto-generated metadata for key 'goonghap_gender_female'.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get goonghap_gender_female;

  /// Auto-generated metadata for key 'goonghap_gender_male'.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get goonghap_gender_male;

  /// Auto-generated metadata for key 'goonghap_idol_style'.
  ///
  /// In en, this message translates to:
  /// **'Idol Styles'**
  String get goonghap_idol_style;

  /// Auto-generated metadata for key 'goonghap_new'.
  ///
  /// In en, this message translates to:
  /// **'View New Goong-Hap'**
  String get goonghap_new;

  /// Auto-generated metadata for key 'goonghap_page_title'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap'**
  String get goonghap_page_title;

  /// Auto-generated metadata for key 'goonghap_purchase_confirm_message'.
  ///
  /// In en, this message translates to:
  /// **'Use 100 Star Candy to check Goong-Hap results.'**
  String get goonghap_purchase_confirm_message;

  /// Auto-generated metadata for key 'goonghap_remain_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Remaining Star Candy'**
  String get goonghap_remain_star_candy;

  /// Auto-generated metadata for key 'goonghap_result_not_found'.
  ///
  /// In en, this message translates to:
  /// **'It\'s not Goong-Hap 😔.'**
  String get goonghap_result_not_found;

  /// Auto-generated metadata for key 'goonghap_share_hashtag'.
  ///
  /// In en, this message translates to:
  /// **'#Picnic #피크닠 #아이돌궁합 #Goonghap #피크닠궁합'**
  String get goonghap_share_hashtag;

  /// No description provided for @goonghap_share_message.
  ///
  /// In en, this message translates to:
  /// **'What percentage is my shining chemistry Goong-Hap with {artistName}? My heart is racing!'**
  String goonghap_share_message(String artistName);

  /// Auto-generated metadata for key 'goonghap_snackbar_error'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get goonghap_snackbar_error;

  /// Auto-generated metadata for key 'goonghap_snackbar_need_gender'.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender.'**
  String get goonghap_snackbar_need_gender;

  /// Auto-generated metadata for key 'goonghap_snackbar_start'.
  ///
  /// In en, this message translates to:
  /// **'Start analyzing Goong-Hap.'**
  String get goonghap_snackbar_start;

  /// Auto-generated metadata for key 'goonghap_style_title'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap styles'**
  String get goonghap_style_title;

  /// Auto-generated metadata for key 'goonghap_time_slot1'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rat|(23:00-01:00)|🐀'**
  String get goonghap_time_slot1;

  /// Auto-generated metadata for key 'goonghap_time_slot10'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rooster|(17:00-19:00)|🐔'**
  String get goonghap_time_slot10;

  /// Auto-generated metadata for key 'goonghap_time_slot11'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Dog|(19:00-21:00)|🐕'**
  String get goonghap_time_slot11;

  /// Auto-generated metadata for key 'goonghap_time_slot12'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Boar|(21:00-23:00)|🐖'**
  String get goonghap_time_slot12;

  /// Auto-generated metadata for key 'goonghap_time_slot2'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Ox|(01:00-03:00)|🐂'**
  String get goonghap_time_slot2;

  /// Auto-generated metadata for key 'goonghap_time_slot3'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Tiger|(03:00-05:00)|🐅'**
  String get goonghap_time_slot3;

  /// Auto-generated metadata for key 'goonghap_time_slot4'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Rabbit|(05:00-07:00)|🐇'**
  String get goonghap_time_slot4;

  /// Auto-generated metadata for key 'goonghap_time_slot5'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Dragon|(07:00-09:00)|🐉'**
  String get goonghap_time_slot5;

  /// Auto-generated metadata for key 'goonghap_time_slot6'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Snake|(09:00-11:00)|🐍'**
  String get goonghap_time_slot6;

  /// Auto-generated metadata for key 'goonghap_time_slot7'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Horse|(11:00-13:00)|🐎'**
  String get goonghap_time_slot7;

  /// Auto-generated metadata for key 'goonghap_time_slot8'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Sheep|(13:00-15:00)|🐑'**
  String get goonghap_time_slot8;

  /// Auto-generated metadata for key 'goonghap_time_slot9'.
  ///
  /// In en, this message translates to:
  /// **'Hour of the Monkey|(15:00-17:00)|🐒'**
  String get goonghap_time_slot9;

  /// Auto-generated metadata for key 'goonghap_tips_title'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap tips'**
  String get goonghap_tips_title;

  /// Auto-generated metadata for key 'goonghap_user_style'.
  ///
  /// In en, this message translates to:
  /// **'User Styles'**
  String get goonghap_user_style;

  /// Auto-generated metadata for key 'goonghap_waiting_message'.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get goonghap_waiting_message;

  /// Auto-generated metadata for key 'goonghap_warning_exit'.
  ///
  /// In en, this message translates to:
  /// **'If you leave the screen, you\'ll need to do the analysis again.'**
  String get goonghap_warning_exit;

  /// Auto-generated metadata for key 'dialog_button_cancel'.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_button_cancel;

  /// Auto-generated metadata for key 'dialog_button_ok'.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialog_button_ok;

  /// Auto-generated metadata for key 'dialog_caution'.
  ///
  /// In en, this message translates to:
  /// **'🚫 Caution 🚫'**
  String get dialog_caution;

  /// Auto-generated metadata for key 'dialog_content_ads_exhausted'.
  ///
  /// In en, this message translates to:
  /// **'All ads have been exhausted. Please try again next time.'**
  String get dialog_content_ads_exhausted;

  /// Auto-generated metadata for key 'dialog_content_login_required'.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get dialog_content_login_required;

  /// Auto-generated metadata for key 'dialog_message_can_resignup'.
  ///
  /// In en, this message translates to:
  /// **'When you can rejoin if you cancel your membership now?'**
  String get dialog_message_can_resignup;

  /// Auto-generated metadata for key 'dialog_message_purchase_failed'.
  ///
  /// In en, this message translates to:
  /// **'There was an error with your purchase, please try again later.'**
  String get dialog_message_purchase_failed;

  /// Auto-generated metadata for key 'dialog_message_purchase_success'.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been successfully completed.'**
  String get dialog_message_purchase_success;

  /// Auto-generated metadata for key 'dialog_title_ads_exhausted'.
  ///
  /// In en, this message translates to:
  /// **'Exhausted all ads'**
  String get dialog_title_ads_exhausted;

  /// Auto-generated metadata for key 'dialog_title_vote_fail'.
  ///
  /// In en, this message translates to:
  /// **'Voting Failed'**
  String get dialog_title_vote_fail;

  /// Auto-generated metadata for key 'dialog_will_delete_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Star Candies to be deleted'**
  String get dialog_will_delete_star_candy;

  /// Auto-generated metadata for key 'dialog_withdraw_message'.
  ///
  /// In en, this message translates to:
  /// **'If you cancel your membership, your star candy and account information on Picnic will be deleted immediately, and your existing information and data will not be restored when you rejoin.'**
  String get dialog_withdraw_message;

  /// Auto-generated metadata for key 'dialog_withdraw_title'.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get dialog_withdraw_title;

  /// Auto-generated metadata for key 'error_action_failed'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while performing the operation.'**
  String get error_action_failed;

  /// Auto-generated metadata for key 'error_content_parse'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while parsing the content.'**
  String get error_content_parse;

  /// Auto-generated metadata for key 'error_invalid_data'.
  ///
  /// In en, this message translates to:
  /// **'Invalid data.'**
  String get error_invalid_data;

  /// Auto-generated metadata for key 'error_network_connection'.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection.'**
  String get error_network_connection;

  /// Auto-generated metadata for key 'error_request_timeout'.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get error_request_timeout;

  /// Auto-generated metadata for key 'error_title'.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get error_title;

  /// Auto-generated metadata for key 'error_unknown'.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get error_unknown;

  /// Auto-generated metadata for key 'faq_category_all'.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get faq_category_all;

  /// Auto-generated metadata for key 'fortune_advice'.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get fortune_advice;

  /// Auto-generated metadata for key 'fortune_button_title'.
  ///
  /// In en, this message translates to:
  /// **'My Artist\'s Fortune teller'**
  String get fortune_button_title;

  /// Auto-generated metadata for key 'fortune_career'.
  ///
  /// In en, this message translates to:
  /// **'Business fortunes'**
  String get fortune_career;

  /// Auto-generated metadata for key 'fortune_health'.
  ///
  /// In en, this message translates to:
  /// **'Health fortunes'**
  String get fortune_health;

  /// Auto-generated metadata for key 'fortune_honor'.
  ///
  /// In en, this message translates to:
  /// **'Honor'**
  String get fortune_honor;

  /// Auto-generated metadata for key 'fortune_lack_of_star_candy_message'.
  ///
  /// In en, this message translates to:
  /// **'Reward Star Candies cannot be used here. 😥'**
  String get fortune_lack_of_star_candy_message;

  /// Auto-generated metadata for key 'fortune_lack_of_star_candy_title'.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough Star Candy. Moving to the shop screen.'**
  String get fortune_lack_of_star_candy_title;

  /// Auto-generated metadata for key 'fortune_lucky_color'.
  ///
  /// In en, this message translates to:
  /// **'Lucky colors'**
  String get fortune_lucky_color;

  /// Auto-generated metadata for key 'fortune_lucky_days'.
  ///
  /// In en, this message translates to:
  /// **'Lucky days of the week'**
  String get fortune_lucky_days;

  /// Auto-generated metadata for key 'fortune_lucky_keyword'.
  ///
  /// In en, this message translates to:
  /// **'Lucky keywords'**
  String get fortune_lucky_keyword;

  /// Auto-generated metadata for key 'fortune_lucky_number'.
  ///
  /// In en, this message translates to:
  /// **'Lucky numbers'**
  String get fortune_lucky_number;

  /// Auto-generated metadata for key 'fortune_money'.
  ///
  /// In en, this message translates to:
  /// **'Fortune Telling'**
  String get fortune_money;

  /// Auto-generated metadata for key 'fortune_month1'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for January'**
  String get fortune_month1;

  /// Auto-generated metadata for key 'fortune_month10'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for October'**
  String get fortune_month10;

  /// Auto-generated metadata for key 'fortune_month11'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for November'**
  String get fortune_month11;

  /// Auto-generated metadata for key 'fortune_month12'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for December'**
  String get fortune_month12;

  /// Auto-generated metadata for key 'fortune_month2'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for February'**
  String get fortune_month2;

  /// Auto-generated metadata for key 'fortune_month3'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for March'**
  String get fortune_month3;

  /// Auto-generated metadata for key 'fortune_month4'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for April'**
  String get fortune_month4;

  /// Auto-generated metadata for key 'fortune_month5'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for May'**
  String get fortune_month5;

  /// Auto-generated metadata for key 'fortune_month6'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for June'**
  String get fortune_month6;

  /// Auto-generated metadata for key 'fortune_month7'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for July'**
  String get fortune_month7;

  /// Auto-generated metadata for key 'fortune_month8'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for August'**
  String get fortune_month8;

  /// Auto-generated metadata for key 'fortune_month9'.
  ///
  /// In en, this message translates to:
  /// **'Fortune for September'**
  String get fortune_month9;

  /// Auto-generated metadata for key 'fortune_monthly'.
  ///
  /// In en, this message translates to:
  /// **'Monthly Fortune'**
  String get fortune_monthly;

  /// Auto-generated metadata for key 'fortune_relationship'.
  ///
  /// In en, this message translates to:
  /// **'Interpersonal'**
  String get fortune_relationship;

  /// Auto-generated metadata for key 'fortune_total_title'.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Fortune'**
  String get fortune_total_title;

  /// Auto-generated metadata for key 'fortune_with_me'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap with me'**
  String get fortune_with_me;

  /// Auto-generated metadata for key 'hint_library_add'.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get hint_library_add;

  /// Auto-generated metadata for key 'hint_nickname_input'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname.'**
  String get hint_nickname_input;

  /// Auto-generated metadata for key 'image_save_success'.
  ///
  /// In en, this message translates to:
  /// **'The image has been saved.'**
  String get image_save_success;

  /// Auto-generated metadata for key 'label_ads_exceeded'.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the number of times you can watch ads for this button.'**
  String get label_ads_exceeded;

  /// Auto-generated metadata for key 'label_ads_get_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Get Star Candy from Ads'**
  String get label_ads_get_star_candy;

  /// No description provided for @label_ads_limits.
  ///
  /// In en, this message translates to:
  /// **'{hourly} per hour, {daily} per day'**
  String label_ads_limits(int hourly, int daily);

  /// Auto-generated metadata for key 'label_ads_load_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ad. Please try again.'**
  String get label_ads_load_fail;

  /// Auto-generated metadata for key 'label_ads_sdk_init_fail'.
  ///
  /// In en, this message translates to:
  /// **'SDK initialization failed. Please try again.'**
  String get label_ads_sdk_init_fail;

  /// Auto-generated metadata for key 'label_ads_show_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to show ad. Please try again.'**
  String get label_ads_show_fail;

  /// Auto-generated metadata for key 'label_agreement_privacy'.
  ///
  /// In en, this message translates to:
  /// **'Consent to the collection and use of personal information'**
  String get label_agreement_privacy;

  /// Auto-generated metadata for key 'label_agreement_terms'.
  ///
  /// In en, this message translates to:
  /// **'Accept the Terms of Use'**
  String get label_agreement_terms;

  /// Auto-generated metadata for key 'label_album_add'.
  ///
  /// In en, this message translates to:
  /// **'Add a new album'**
  String get label_album_add;

  /// Auto-generated metadata for key 'label_article_comment_empty'.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get label_article_comment_empty;

  /// Auto-generated metadata for key 'label_asia_recommendation'.
  ///
  /// In en, this message translates to:
  /// **'Asia Pick'**
  String get label_asia_recommendation;

  /// Auto-generated metadata for key 'label_bonus'.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get label_bonus;

  /// Auto-generated metadata for key 'label_button_agreement'.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get label_button_agreement;

  /// Auto-generated metadata for key 'label_button_close'.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get label_button_close;

  /// Auto-generated metadata for key 'label_button_recharge'.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get label_button_recharge;

  /// Auto-generated metadata for key 'label_button_view_policy'.
  ///
  /// In en, this message translates to:
  /// **'View Policy'**
  String get label_button_view_policy;

  /// Auto-generated metadata for key 'label_button_vote'.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get label_button_vote;

  /// Auto-generated metadata for key 'label_celeb_gallery'.
  ///
  /// In en, this message translates to:
  /// **'Artist Gallery'**
  String get label_celeb_gallery;

  /// Auto-generated metadata for key 'label_celeb_recommend'.
  ///
  /// In en, this message translates to:
  /// **'Artist recommendations'**
  String get label_celeb_recommend;

  /// Auto-generated metadata for key 'label_checkbox_entire_use'.
  ///
  /// In en, this message translates to:
  /// **'Full Use'**
  String get label_checkbox_entire_use;

  /// Auto-generated metadata for key 'label_draw_image'.
  ///
  /// In en, this message translates to:
  /// **'Chance to win a random image'**
  String get label_draw_image;

  /// Auto-generated metadata for key 'label_dropdown_oldest'.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get label_dropdown_oldest;

  /// Auto-generated metadata for key 'label_dropdown_recent'.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get label_dropdown_recent;

  /// Auto-generated metadata for key 'label_global_recommendation'.
  ///
  /// In en, this message translates to:
  /// **'Global Pick'**
  String get label_global_recommendation;

  /// Auto-generated metadata for key 'label_hint_comment'.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment.'**
  String get label_hint_comment;

  /// Auto-generated metadata for key 'label_input_input'.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get label_input_input;

  /// Auto-generated metadata for key 'label_korean_recommendation'.
  ///
  /// In en, this message translates to:
  /// **'Korean Pick'**
  String get label_korean_recommendation;

  /// Auto-generated metadata for key 'label_last_provider'.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get label_last_provider;

  /// Auto-generated metadata for key 'label_library_save'.
  ///
  /// In en, this message translates to:
  /// **'Save the library'**
  String get label_library_save;

  /// Auto-generated metadata for key 'label_library_tab_ai_photo'.
  ///
  /// In en, this message translates to:
  /// **'AI Photos'**
  String get label_library_tab_ai_photo;

  /// Auto-generated metadata for key 'label_library_tab_library'.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get label_library_tab_library;

  /// Auto-generated metadata for key 'label_library_tab_pic'.
  ///
  /// In en, this message translates to:
  /// **'PIC'**
  String get label_library_tab_pic;

  /// Auto-generated metadata for key 'label_loading_ads'.
  ///
  /// In en, this message translates to:
  /// **'Loading ad'**
  String get label_loading_ads;

  /// Auto-generated metadata for key 'label_mission_get_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Get Star Candy from Missions'**
  String get label_mission_get_star_candy;

  /// Auto-generated metadata for key 'label_mission_short'.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get label_mission_short;

  /// Auto-generated metadata for key 'label_moveto_celeb_gallery'.
  ///
  /// In en, this message translates to:
  /// **'Go to the Artist Gallery'**
  String get label_moveto_celeb_gallery;

  /// Auto-generated metadata for key 'label_mypage_faq'.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get label_mypage_faq;

  /// Auto-generated metadata for key 'label_mypage_logout'.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get label_mypage_logout;

  /// Auto-generated metadata for key 'label_mypage_my_artist'.
  ///
  /// In en, this message translates to:
  /// **'My Artists'**
  String get label_mypage_my_artist;

  /// Auto-generated metadata for key 'label_mypage_no_artist'.
  ///
  /// In en, this message translates to:
  /// **'No Artist'**
  String get label_mypage_no_artist;

  /// Auto-generated metadata for key 'label_mypage_notice'.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get label_mypage_notice;

  /// Auto-generated metadata for key 'label_mypage_notifications'.
  ///
  /// In en, this message translates to:
  /// **'Notification Box'**
  String get label_mypage_notifications;

  /// Auto-generated metadata for key 'label_mypage_picnic_id'.
  ///
  /// In en, this message translates to:
  /// **'Picnic ID'**
  String get label_mypage_picnic_id;

  /// Auto-generated metadata for key 'label_mypage_privacy_policy'.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get label_mypage_privacy_policy;

  /// Auto-generated metadata for key 'label_mypage_setting'.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get label_mypage_setting;

  /// Auto-generated metadata for key 'label_mypage_should_login'.
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get label_mypage_should_login;

  /// Auto-generated metadata for key 'label_mypage_terms_of_use'.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get label_mypage_terms_of_use;

  /// Auto-generated metadata for key 'label_mypage_vote_history'.
  ///
  /// In en, this message translates to:
  /// **'StarCandy Voting History'**
  String get label_mypage_vote_history;

  /// Auto-generated metadata for key 'label_mypage_withdrawal'.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get label_mypage_withdrawal;

  /// Auto-generated metadata for key 'label_no_celeb'.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any artists bookmarked yet!'**
  String get label_no_celeb;

  /// Auto-generated metadata for key 'label_pic_chart'.
  ///
  /// In en, this message translates to:
  /// **'Pic Chart'**
  String get label_pic_chart;

  /// Auto-generated metadata for key 'label_pic_pic_save_gallery'.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get label_pic_pic_save_gallery;

  /// Auto-generated metadata for key 'label_read_more_comment'.
  ///
  /// In en, this message translates to:
  /// **'More comments'**
  String get label_read_more_comment;

  /// Auto-generated metadata for key 'label_reply'.
  ///
  /// In en, this message translates to:
  /// **'Replying to a reply'**
  String get label_reply;

  /// Auto-generated metadata for key 'label_retry'.
  ///
  /// In en, this message translates to:
  /// **'Retrying'**
  String get label_retry;

  /// Auto-generated metadata for key 'label_setting_alarm'.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get label_setting_alarm;

  /// Auto-generated metadata for key 'label_setting_appinfo'.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get label_setting_appinfo;

  /// Auto-generated metadata for key 'label_setting_current_version'.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get label_setting_current_version;

  /// Auto-generated metadata for key 'label_setting_event_alarm'.
  ///
  /// In en, this message translates to:
  /// **'Event notifications'**
  String get label_setting_event_alarm;

  /// Auto-generated metadata for key 'label_setting_event_alarm_desc'.
  ///
  /// In en, this message translates to:
  /// **'Events and happenings.'**
  String get label_setting_event_alarm_desc;

  /// Auto-generated metadata for key 'label_setting_language'.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get label_setting_language;

  /// Auto-generated metadata for key 'label_setting_push_alarm'.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get label_setting_push_alarm;

  /// Auto-generated metadata for key 'label_setting_recent_version'.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get label_setting_recent_version;

  /// Auto-generated metadata for key 'label_setting_recent_version_up_to_date'.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get label_setting_recent_version_up_to_date;

  /// Auto-generated metadata for key 'label_setting_remove_cache'.
  ///
  /// In en, this message translates to:
  /// **'Delete cache memory'**
  String get label_setting_remove_cache;

  /// Auto-generated metadata for key 'label_setting_storage'.
  ///
  /// In en, this message translates to:
  /// **'Manage storage'**
  String get label_setting_storage;

  /// Auto-generated metadata for key 'label_star_candy_pouch'.
  ///
  /// In en, this message translates to:
  /// **'Star Candy Pouch'**
  String get label_star_candy_pouch;

  /// Auto-generated metadata for key 'label_tabbar_vote_active'.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get label_tabbar_vote_active;

  /// Auto-generated metadata for key 'label_tabbar_vote_end'.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get label_tabbar_vote_end;

  /// No description provided for @label_time_ago_day.
  ///
  /// In en, this message translates to:
  /// **'{day} days ago'**
  String label_time_ago_day(int day);

  /// No description provided for @label_time_ago_hour.
  ///
  /// In en, this message translates to:
  /// **'{hour} hours ago'**
  String label_time_ago_hour(int hour);

  /// Auto-generated metadata for key 'label_time_ago_right_now'.
  ///
  /// In en, this message translates to:
  /// **'Just a moment ago'**
  String get label_time_ago_right_now;

  /// Auto-generated metadata for key 'label_title_report'.
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get label_title_report;

  /// Auto-generated metadata for key 'label_unlimited_rewards'.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rewards'**
  String get label_unlimited_rewards;

  /// Auto-generated metadata for key 'label_vote_end'.
  ///
  /// In en, this message translates to:
  /// **'Close the poll'**
  String get label_vote_end;

  /// Auto-generated metadata for key 'label_vote_reward_list'.
  ///
  /// In en, this message translates to:
  /// **'Rewards list'**
  String get label_vote_reward_list;

  /// Auto-generated metadata for key 'label_vote_screen_title'.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get label_vote_screen_title;

  /// Auto-generated metadata for key 'label_vote_upcoming'.
  ///
  /// In en, this message translates to:
  /// **'Until voting begins'**
  String get label_vote_upcoming;

  /// Auto-generated metadata for key 'label_watch_ads_short'.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get label_watch_ads_short;

  /// Auto-generated metadata for key 'lable_my_celeb'.
  ///
  /// In en, this message translates to:
  /// **'My Artists'**
  String get lable_my_celeb;

  /// Auto-generated metadata for key 'message_error_occurred'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get message_error_occurred;

  /// Auto-generated metadata for key 'message_noitem_vote_active'.
  ///
  /// In en, this message translates to:
  /// **'There are currently no active polls.'**
  String get message_noitem_vote_active;

  /// Auto-generated metadata for key 'message_noitem_vote_end'.
  ///
  /// In en, this message translates to:
  /// **'There are currently no closed polls.'**
  String get message_noitem_vote_end;

  /// Auto-generated metadata for key 'message_noitem_vote_upcoming'.
  ///
  /// In en, this message translates to:
  /// **'There are currently no upcoming polls.'**
  String get message_noitem_vote_upcoming;

  /// Auto-generated metadata for key 'message_pic_pic_save_fail'.
  ///
  /// In en, this message translates to:
  /// **'Saving the image failed.'**
  String get message_pic_pic_save_fail;

  /// Auto-generated metadata for key 'message_pic_pic_save_success'.
  ///
  /// In en, this message translates to:
  /// **'The image has been saved.'**
  String get message_pic_pic_save_success;

  /// Auto-generated metadata for key 'message_vote_is_ended'.
  ///
  /// In en, this message translates to:
  /// **'Poll closed'**
  String get message_vote_is_ended;

  /// Auto-generated metadata for key 'message_vote_is_upcoming'.
  ///
  /// In en, this message translates to:
  /// **'This is an upcoming vote.'**
  String get message_vote_is_upcoming;

  /// Auto-generated metadata for key 'my_info'.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get my_info;

  /// Auto-generated metadata for key 'mypage_setting'.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mypage_setting;

  /// Auto-generated metadata for key 'nav_media'.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get nav_media;

  /// Auto-generated metadata for key 'nickname_validation_error'.
  ///
  /// In en, this message translates to:
  /// **'20 characters or less, excluding special characters.'**
  String get nickname_validation_error;

  /// Auto-generated metadata for key 'page_title_mypage'.
  ///
  /// In en, this message translates to:
  /// **'My Page'**
  String get page_title_mypage;

  /// Auto-generated metadata for key 'page_title_post_write'.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get page_title_post_write;

  /// Auto-generated metadata for key 'page_title_vote_detail'.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get page_title_vote_detail;

  /// Auto-generated metadata for key 'popup_label_delete'.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get popup_label_delete;

  /// Auto-generated metadata for key 'post_anonymous'.
  ///
  /// In en, this message translates to:
  /// **'Anonymous posting'**
  String get post_anonymous;

  /// Auto-generated metadata for key 'post_board_already_exist'.
  ///
  /// In en, this message translates to:
  /// **'A board that already exists.'**
  String get post_board_already_exist;

  /// Auto-generated metadata for key 'post_board_create_request_complete'.
  ///
  /// In en, this message translates to:
  /// **'Your request to open a board is complete.'**
  String get post_board_create_request_complete;

  /// Auto-generated metadata for key 'post_board_create_request_condition'.
  ///
  /// In en, this message translates to:
  /// **'*Only one minor board can be applied per ID.'**
  String get post_board_create_request_condition;

  /// Auto-generated metadata for key 'post_board_request_label'.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get post_board_request_label;

  /// Auto-generated metadata for key 'post_comment_action_translate'.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get post_comment_action_translate;

  /// Auto-generated metadata for key 'post_comment_content_more'.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get post_comment_content_more;

  /// Auto-generated metadata for key 'post_comment_delete_confirm'.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the comment?'**
  String get post_comment_delete_confirm;

  /// Auto-generated metadata for key 'post_comment_delete_fail'.
  ///
  /// In en, this message translates to:
  /// **'Comment deletion failed.'**
  String get post_comment_delete_fail;

  /// Auto-generated metadata for key 'post_comment_deleted_comment'.
  ///
  /// In en, this message translates to:
  /// **'This is a deleted comment.'**
  String get post_comment_deleted_comment;

  /// Auto-generated metadata for key 'post_comment_like_processing_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to process like.'**
  String get post_comment_like_processing_fail;

  /// Auto-generated metadata for key 'post_comment_loading_fail'.
  ///
  /// In en, this message translates to:
  /// **'Comment failed to load.'**
  String get post_comment_loading_fail;

  /// Auto-generated metadata for key 'post_comment_register_fail'.
  ///
  /// In en, this message translates to:
  /// **'Comment registration failed.'**
  String get post_comment_register_fail;

  /// Auto-generated metadata for key 'post_comment_registered_comment'.
  ///
  /// In en, this message translates to:
  /// **'Your comment has been registered.'**
  String get post_comment_registered_comment;

  /// Auto-generated metadata for key 'post_comment_reported_comment'.
  ///
  /// In en, this message translates to:
  /// **'This is a reported comment.'**
  String get post_comment_reported_comment;

  /// Auto-generated metadata for key 'post_comment_translate_fail'.
  ///
  /// In en, this message translates to:
  /// **'The translation failed.'**
  String get post_comment_translate_fail;

  /// Auto-generated metadata for key 'post_comment_translated'.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get post_comment_translated;

  /// Auto-generated metadata for key 'post_comment_write_label'.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get post_comment_write_label;

  /// Auto-generated metadata for key 'post_content_placeholder'.
  ///
  /// In en, this message translates to:
  /// **'Please enter something.'**
  String get post_content_placeholder;

  /// Auto-generated metadata for key 'post_delete_scrap_confirm'.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the scrap?'**
  String get post_delete_scrap_confirm;

  /// Auto-generated metadata for key 'post_delete_scrap_title'.
  ///
  /// In en, this message translates to:
  /// **'Delete a scrap'**
  String get post_delete_scrap_title;

  /// Auto-generated metadata for key 'post_flagged'.
  ///
  /// In en, this message translates to:
  /// **'Contains inappropriate content'**
  String get post_flagged;

  /// Auto-generated metadata for key 'post_go_to_boards'.
  ///
  /// In en, this message translates to:
  /// **'Go to the board'**
  String get post_go_to_boards;

  /// Auto-generated metadata for key 'post_header_publish'.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get post_header_publish;

  /// Auto-generated metadata for key 'post_header_temporary_save'.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get post_header_temporary_save;

  /// Auto-generated metadata for key 'post_hint_title'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get post_hint_title;

  /// Auto-generated metadata for key 'post_hyperlink'.
  ///
  /// In en, this message translates to:
  /// **'Hyperlinks'**
  String get post_hyperlink;

  /// Auto-generated metadata for key 'post_insert_link'.
  ///
  /// In en, this message translates to:
  /// **'Inserting links'**
  String get post_insert_link;

  /// Auto-generated metadata for key 'post_minor_board_condition'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description of at least 5 characters and no more than 20 characters.'**
  String get post_minor_board_condition;

  /// Auto-generated metadata for key 'post_minor_board_description'.
  ///
  /// In en, this message translates to:
  /// **'Minor bulletin board descriptions'**
  String get post_minor_board_description;

  /// Auto-generated metadata for key 'post_minor_board_description_input'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description for your minor board.'**
  String get post_minor_board_description_input;

  /// Auto-generated metadata for key 'post_minor_board_name'.
  ///
  /// In en, this message translates to:
  /// **'Minor board name'**
  String get post_minor_board_name;

  /// Auto-generated metadata for key 'post_minor_board_name_input'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your minor board.'**
  String get post_minor_board_name_input;

  /// Auto-generated metadata for key 'post_my_compatibilities'.
  ///
  /// In en, this message translates to:
  /// **'My Goong-Hap'**
  String get post_my_compatibilities;

  /// Auto-generated metadata for key 'post_my_written_post'.
  ///
  /// In en, this message translates to:
  /// **'Posts I\'ve written'**
  String get post_my_written_post;

  /// Auto-generated metadata for key 'post_my_written_reply'.
  ///
  /// In en, this message translates to:
  /// **'Comments I wrote'**
  String get post_my_written_reply;

  /// Auto-generated metadata for key 'post_my_written_scrap'.
  ///
  /// In en, this message translates to:
  /// **'My Scraps'**
  String get post_my_written_scrap;

  /// Auto-generated metadata for key 'post_no_comment'.
  ///
  /// In en, this message translates to:
  /// **'No comments.'**
  String get post_no_comment;

  /// Auto-generated metadata for key 'post_not_found'.
  ///
  /// In en, this message translates to:
  /// **'No posts were found.'**
  String get post_not_found;

  /// Title shown for deleted posts
  ///
  /// In en, this message translates to:
  /// **'Deleted Post'**
  String get post_deleted_title;

  /// Description shown for deleted posts
  ///
  /// In en, this message translates to:
  /// **'This post has been deleted by the author.'**
  String get post_deleted_desc;

  /// Auto-generated metadata for key 'post_report_fail'.
  ///
  /// In en, this message translates to:
  /// **'The report failed.'**
  String get post_report_fail;

  /// Auto-generated metadata for key 'post_report_label'.
  ///
  /// In en, this message translates to:
  /// **'Make a report'**
  String get post_report_label;

  /// Auto-generated metadata for key 'post_report_other_input'.
  ///
  /// In en, this message translates to:
  /// **'Please enter any other reason.'**
  String get post_report_other_input;

  /// Auto-generated metadata for key 'post_report_reason_1'.
  ///
  /// In en, this message translates to:
  /// **'Unsavory posts'**
  String get post_report_reason_1;

  /// Auto-generated metadata for key 'post_report_reason_2'.
  ///
  /// In en, this message translates to:
  /// **'Sexist, racist posts'**
  String get post_report_reason_2;

  /// Auto-generated metadata for key 'post_report_reason_3'.
  ///
  /// In en, this message translates to:
  /// **'Posts containing offensive profanity'**
  String get post_report_reason_3;

  /// Auto-generated metadata for key 'post_report_reason_4'.
  ///
  /// In en, this message translates to:
  /// **'Advertising/Promotional Posts'**
  String get post_report_reason_4;

  /// Auto-generated metadata for key 'post_report_reason_5'.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get post_report_reason_5;

  /// Auto-generated metadata for key 'post_report_reason_input'.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for your report.'**
  String get post_report_reason_input;

  /// Auto-generated metadata for key 'post_report_reason_label'.
  ///
  /// In en, this message translates to:
  /// **'Reasons for reporting'**
  String get post_report_reason_label;

  /// Auto-generated metadata for key 'post_report_success'.
  ///
  /// In en, this message translates to:
  /// **'The report is complete.'**
  String get post_report_success;

  /// Auto-generated metadata for key 'post_title_placeholder'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get post_title_placeholder;

  /// Auto-generated metadata for key 'post_youtube_link'.
  ///
  /// In en, this message translates to:
  /// **'YouTube link'**
  String get post_youtube_link;

  /// Auto-generated metadata for key 'purchase_confirm_button'.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase_confirm_button;

  /// Auto-generated metadata for key 'purchase_confirm_message'.
  ///
  /// In en, this message translates to:
  /// **'Would you like to purchase the following item?'**
  String get purchase_confirm_message;

  /// Auto-generated metadata for key 'purchase_confirm_title'.
  ///
  /// In en, this message translates to:
  /// **'Purchase Confirmation'**
  String get purchase_confirm_title;

  /// Auto-generated metadata for key 'previousTransactionPendingError'.
  ///
  /// In en, this message translates to:
  /// **'Your previous payment is still being processed by the Store. Please try again shortly.'**
  String get previousTransactionPendingError;

  /// Auto-generated metadata for key 'purchase_in_progress_message'.
  ///
  /// In en, this message translates to:
  /// **'Purchase is in progress. Please wait a moment.'**
  String get purchase_in_progress_message;

  /// Auto-generated metadata for key 'purchase_initializing_message'.
  ///
  /// In en, this message translates to:
  /// **'Initializing. Please try again in a moment.'**
  String get purchase_initializing_message;

  /// Auto-generated metadata for key 'purchase_cancelled_message'.
  ///
  /// In en, this message translates to:
  /// **'Purchase has been cancelled.'**
  String get purchase_cancelled_message;

  /// Auto-generated metadata for key 'purchase_payment_amount'.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get purchase_payment_amount;

  /// Auto-generated metadata for key 'purchase_web_message'.
  ///
  /// In en, this message translates to:
  /// **'This is the payment window for those who can\'t pay with the app.\n Please copy the random ID in advance.\n After copying it, click the button below to proceed with the payment.'**
  String get purchase_web_message;

  /// Auto-generated metadata for key 'qna_content'.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get qna_content;

  /// Auto-generated metadata for key 'qna_create_page_title'.
  ///
  /// In en, this message translates to:
  /// **'Create Inquiry'**
  String get qna_create_page_title;

  /// Auto-generated metadata for key 'qna_no_inquiries'.
  ///
  /// In en, this message translates to:
  /// **'No inquiry history'**
  String get qna_no_inquiries;

  /// Auto-generated metadata for key 'qna_status_closed'.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get qna_status_closed;

  /// Auto-generated metadata for key 'qna_status_open'.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get qna_status_open;

  /// Auto-generated metadata for key 'qna_submit_button'.
  ///
  /// In en, this message translates to:
  /// **'Submit Inquiry'**
  String get qna_submit_button;

  /// Auto-generated metadata for key 'qna_title'.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get qna_title;

  /// Auto-generated metadata for key 'replies'.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get replies;

  /// Auto-generated metadata for key 'reward'.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get reward;

  /// Auto-generated metadata for key 'save'.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Auto-generated metadata for key 'seconds'.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// Auto-generated metadata for key 'share'.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Auto-generated metadata for key 'text_community_board_search'.
  ///
  /// In en, this message translates to:
  /// **'Searching the Artist Board'**
  String get text_community_board_search;

  /// Auto-generated metadata for key 'text_community_post_search'.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get text_community_post_search;

  /// Shown after copying text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get text_copied;

  /// Instruction text on ban screen to contact support with logs
  ///
  /// In en, this message translates to:
  /// **'Please copy the logs below and contact support.'**
  String get ban_support_instruction;

  /// Copy button label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get action_copy;

  /// Auto-generated metadata for key 'text_draw_image'.
  ///
  /// In en, this message translates to:
  /// **'Confirmed ownership of 1 image from the entire gallery.'**
  String get text_draw_image;

  /// Auto-generated metadata for key 'text_hint_search'.
  ///
  /// In en, this message translates to:
  /// **'Search for artists'**
  String get text_hint_search;

  /// Auto-generated metadata for key 'text_moveto_celeb_gallery'.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the selected artist\'s home.'**
  String get text_moveto_celeb_gallery;

  /// Auto-generated metadata for key 'text_need_recharge'.
  ///
  /// In en, this message translates to:
  /// **'Requires charging.'**
  String get text_need_recharge;

  /// Auto-generated metadata for key 'text_no_search_result'.
  ///
  /// In en, this message translates to:
  /// **'No search results.'**
  String get text_no_search_result;

  /// Auto-generated metadata for key 'text_purchase_vat_included'.
  ///
  /// In en, this message translates to:
  /// **'*Price includes VAT.'**
  String get text_purchase_vat_included;

  /// Auto-generated metadata for key 'text_vote_complete'.
  ///
  /// In en, this message translates to:
  /// **'Voting complete'**
  String get text_vote_complete;

  /// No description provided for @text_vote_rank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String text_vote_rank(int rank);

  /// Auto-generated metadata for key 'text_vote_rank_in_reward'.
  ///
  /// In en, this message translates to:
  /// **'Rank in Rewards'**
  String get text_vote_rank_in_reward;

  /// Auto-generated metadata for key 'text_vote_where_is_my_bias'.
  ///
  /// In en, this message translates to:
  /// **'Where\'s My Favorite?'**
  String get text_vote_where_is_my_bias;

  /// Auto-generated metadata for key 'title_dialog_library_add'.
  ///
  /// In en, this message translates to:
  /// **'Add a new album'**
  String get title_dialog_library_add;

  /// Auto-generated metadata for key 'title_select_language'.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get title_select_language;

  /// Toast message when bookmark is added successfully.
  ///
  /// In en, this message translates to:
  /// **'Added to bookmarks.'**
  String get toast_bookmark_added;

  /// Toast message when bookmark is removed successfully.
  ///
  /// In en, this message translates to:
  /// **'Removed from bookmarks.'**
  String get toast_bookmark_removed;

  /// Auto-generated metadata for key 'toast_max_five_celeb'.
  ///
  /// In en, this message translates to:
  /// **'You can add up to five of your own artists.'**
  String get toast_max_five_celeb;

  /// Auto-generated metadata for key 'update_button'.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update_button;

  /// Auto-generated metadata for key 'update_cannot_open_appstore'.
  ///
  /// In en, this message translates to:
  /// **'I can\'t open the app store.'**
  String get update_cannot_open_appstore;

  /// Auto-generated metadata for key 'update_required_title'.
  ///
  /// In en, this message translates to:
  /// **'An update is required.'**
  String get update_required_title;

  /// Auto-generated metadata for key 'views'.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// Auto-generated metadata for key 'vote_item_request_can_apply'.
  ///
  /// In en, this message translates to:
  /// **'Can apply'**
  String get vote_item_request_can_apply;

  /// Auto-generated metadata for key 'vote_item_request_search_artist'.
  ///
  /// In en, this message translates to:
  /// **'Search Artist'**
  String get vote_item_request_search_artist;

  /// Auto-generated metadata for key 'vote_item_request_status'.
  ///
  /// In en, this message translates to:
  /// **'Request status'**
  String get vote_item_request_status;

  /// Auto-generated metadata for key 'vote_item_request_status_approved'.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get vote_item_request_status_approved;

  /// Auto-generated metadata for key 'vote_item_request_status_pending'.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get vote_item_request_status_pending;

  /// Auto-generated metadata for key 'vote_item_request_status_rejected'.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get vote_item_request_status_rejected;

  /// Auto-generated metadata for key 'vote_item_request_submit'.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get vote_item_request_submit;

  /// Auto-generated metadata for key 'vote_item_request_title'.
  ///
  /// In en, this message translates to:
  /// **'Vote Artist Request'**
  String get vote_item_request_title;

  /// Auto-generated metadata for key 'vote_share_message'.
  ///
  /// In en, this message translates to:
  /// **'Voted!'**
  String get vote_share_message;

  /// Auto-generated metadata for key 'vote_completed_message'.
  ///
  /// In en, this message translates to:
  /// **'I voted!'**
  String get vote_completed_message;

  /// Auto-generated metadata for key 'voting_share_benefit_text'.
  ///
  /// In en, this message translates to:
  /// **'Get 1 bonus star candy for every 100 votes and share!'**
  String get voting_share_benefit_text;

  /// Auto-generated metadata for key 'cancel'.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Auto-generated metadata for key 'confirm'.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Auto-generated metadata for key 'loading'.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Auto-generated metadata for key 'retry'.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Auto-generated metadata for key 'update'.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Auto-generated metadata for key 'ban_title'.
  ///
  /// In en, this message translates to:
  /// **'Device Suspended'**
  String get ban_title;

  /// Auto-generated metadata for key 'ban_message'.
  ///
  /// In en, this message translates to:
  /// **'This device has been temporarily suspended due to policy violations.'**
  String get ban_message;

  /// Auto-generated metadata for key 'ban_contact'.
  ///
  /// In en, this message translates to:
  /// **'If you believe this is a mistake, please contact customer support.'**
  String get ban_contact;

  /// Auto-generated metadata for key 'goonghap_empty_state_title'.
  ///
  /// In en, this message translates to:
  /// **'No Goong-Hap information'**
  String get goonghap_empty_state_title;

  /// Auto-generated metadata for key 'goonghap_empty_state_subtitle'.
  ///
  /// In en, this message translates to:
  /// **'Create your first Goong-Hap!'**
  String get goonghap_empty_state_subtitle;

  /// Title shown when user needs to login to see goonghap
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get goonghap_login_required_title;

  /// Subtitle shown when user needs to login to see goonghap
  ///
  /// In en, this message translates to:
  /// **'Please log in to see your Goong-Hap results'**
  String get goonghap_login_required_subtitle;

  /// Login button text on goonghap page
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get goonghap_login_button;

  /// Auto-generated metadata for key 'network_error_title'.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get network_error_title;

  /// Auto-generated metadata for key 'network_error_message'.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get network_error_message;

  /// Auto-generated metadata for key 'notice_pinned'.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notice_pinned;

  /// Auto-generated metadata for key 'title_dialog_error'.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get title_dialog_error;

  /// Auto-generated metadata for key 'vote_item_request_waiting'.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get vote_item_request_waiting;

  /// Auto-generated metadata for key 'capture_failed'.
  ///
  /// In en, this message translates to:
  /// **'Capture failed'**
  String get capture_failed;

  /// Auto-generated metadata for key 'qna_submit_success'.
  ///
  /// In en, this message translates to:
  /// **'Your inquiry has been successfully submitted'**
  String get qna_submit_success;

  /// Auto-generated metadata for key 'qna_list_title'.
  ///
  /// In en, this message translates to:
  /// **'My Inquiries'**
  String get qna_list_title;

  /// Auto-generated metadata for key 'starCandy100'.
  ///
  /// In en, this message translates to:
  /// **'100 Star Candy'**
  String get starCandy100;

  /// Auto-generated metadata for key 'starCandy200'.
  ///
  /// In en, this message translates to:
  /// **'200 Star Candy'**
  String get starCandy200;

  /// Auto-generated metadata for key 'starCandy600'.
  ///
  /// In en, this message translates to:
  /// **'600 Star Candy'**
  String get starCandy600;

  /// Auto-generated metadata for key 'starCandy1000'.
  ///
  /// In en, this message translates to:
  /// **'1,000 Star Candy'**
  String get starCandy1000;

  /// Auto-generated metadata for key 'starCandy2000'.
  ///
  /// In en, this message translates to:
  /// **'2,000 Star Candy'**
  String get starCandy2000;

  /// Auto-generated metadata for key 'starCandy3000'.
  ///
  /// In en, this message translates to:
  /// **'3,000 Star Candy'**
  String get starCandy3000;

  /// Auto-generated metadata for key 'starCandy4000'.
  ///
  /// In en, this message translates to:
  /// **'4,000 Star Candy'**
  String get starCandy4000;

  /// Auto-generated metadata for key 'starCandy5000'.
  ///
  /// In en, this message translates to:
  /// **'5,000 Star Candy'**
  String get starCandy5000;

  /// Auto-generated metadata for key 'update_required_message'.
  ///
  /// In en, this message translates to:
  /// **'App update required'**
  String get update_required_message;

  /// Auto-generated metadata for key 'vote_item_request_no_search_results'.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get vote_item_request_no_search_results;

  /// Auto-generated metadata for key 'jma_voting_my_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'My Star Candy'**
  String get jma_voting_my_star_candy;

  /// Auto-generated metadata for key 'jma_voting_usable_jma_votes'.
  ///
  /// In en, this message translates to:
  /// **'Available JMA Votes'**
  String get jma_voting_usable_jma_votes;

  /// Auto-generated metadata for key 'jma_voting_use_all'.
  ///
  /// In en, this message translates to:
  /// **'Use All'**
  String get jma_voting_use_all;

  /// Auto-generated metadata for key 'jma_voting_input_amount'.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount of Star Candy.'**
  String get jma_voting_input_amount;

  /// Auto-generated metadata for key 'jma_voting_daily_limit_error'.
  ///
  /// In en, this message translates to:
  /// **'You can vote up to 5 times per day.'**
  String get jma_voting_daily_limit_error;

  /// Auto-generated metadata for key 'jma_voting_exchange_failed'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while exchanging Star Candy. Please try again.'**
  String get jma_voting_exchange_failed;

  /// Auto-generated metadata for key 'jma_voting_daily_limit_title'.
  ///
  /// In en, this message translates to:
  /// **'Voting Limit'**
  String get jma_voting_daily_limit_title;

  /// Auto-generated metadata for key 'jma_voting_exchange_failed_title'.
  ///
  /// In en, this message translates to:
  /// **'Exchange Failed'**
  String get jma_voting_exchange_failed_title;

  /// Auto-generated metadata for key 'expiring_bonus_candy_guide'.
  ///
  /// In en, this message translates to:
  /// **'Expiring Bonus Guide'**
  String get expiring_bonus_candy_guide;

  /// Auto-generated metadata for key 'qna_form_title_hint'.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title of at least 5 characters.'**
  String get qna_form_title_hint;

  /// Auto-generated metadata for key 'qna_form_content_hint'.
  ///
  /// In en, this message translates to:
  /// **'Please enter content of at least 10 characters.'**
  String get qna_form_content_hint;

  /// Auto-generated metadata for key 'qna_attach_media'.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo/Video'**
  String get qna_attach_media;

  /// No description provided for @file_too_large_message.
  ///
  /// In en, this message translates to:
  /// **'{fileName} exceeds the {maxSize}MB size limit.'**
  String file_too_large_message(String fileName, int maxSize);

  /// Auto-generated metadata for key 'qna_submit_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit inquiry'**
  String get qna_submit_fail;

  /// No description provided for @qna_file_size_limit_notice.
  ///
  /// In en, this message translates to:
  /// **'You can attach files up to {maxSize}MB.'**
  String qna_file_size_limit_notice(int maxSize);

  /// Auto-generated metadata for key 'qna_cannot_send_message_closed'.
  ///
  /// In en, this message translates to:
  /// **'This inquiry has been closed and you can no longer send messages.'**
  String get qna_cannot_send_message_closed;

  /// Auto-generated metadata for key 'qna_message_sent_success'.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully.'**
  String get qna_message_sent_success;

  /// Auto-generated metadata for key 'qna_message_sent_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get qna_message_sent_fail;

  /// Auto-generated metadata for key 'qna_no_answer_yet'.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get qna_no_answer_yet;

  /// Auto-generated metadata for key 'qna_add_media_tooltip'.
  ///
  /// In en, this message translates to:
  /// **'Add Media'**
  String get qna_add_media_tooltip;

  /// Auto-generated metadata for key 'qna_load_fail_title'.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inquiries'**
  String get qna_load_fail_title;

  /// QnA category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get qna_category_label;

  /// Error message when category is required
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get qna_category_required;

  /// Auto-generated metadata for key 'qna_message_hint'.
  ///
  /// In en, this message translates to:
  /// **'Enter message'**
  String get qna_message_hint;

  /// Auto-generated metadata for key 'label_my_vote_history'.
  ///
  /// In en, this message translates to:
  /// **'My Vote History'**
  String get label_my_vote_history;

  /// Auto-generated metadata for key 'bonus_candy_example_2_expire'.
  ///
  /// In en, this message translates to:
  /// **'__THE_MONTH_AFTER_NEXT__ 15th 00:00(KST)'**
  String get bonus_candy_example_2_expire;

  /// Auto-generated metadata for key 'bonus_candy_example_earn_date'.
  ///
  /// In en, this message translates to:
  /// **'Earn Date'**
  String get bonus_candy_example_earn_date;

  /// Auto-generated metadata for key 'vote_item_request_status_unknown'.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get vote_item_request_status_unknown;

  /// Auto-generated metadata for key 'bonus_candy_expiration_policy_load_fail'.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expiring bonus information.'**
  String get bonus_candy_expiration_policy_load_fail;

  /// Auto-generated metadata for key 'bonus_candy_example_1_expire'.
  ///
  /// In en, this message translates to:
  /// **'__NEXT_MONTH__ 15th 00:00(KST)'**
  String get bonus_candy_example_1_expire;

  /// Auto-generated metadata for key 'vote_item_request_status_in_progress'.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get vote_item_request_status_in_progress;

  /// Auto-generated metadata for key 'bonus_candy_policy_2'.
  ///
  /// In en, this message translates to:
  /// **'- When using Star Candy, the Bonus Star Candy with the nearest expiration date will be deducted first.'**
  String get bonus_candy_policy_2;

  /// No description provided for @goonghap_purchase_message.
  ///
  /// In en, this message translates to:
  /// **'Want to know the Goong-Hap score between me and {artistName}?'**
  String goonghap_purchase_message(String artistName);

  /// Charge history menu for admin users
  ///
  /// In en, this message translates to:
  /// **'Charges (Admin)'**
  String get label_mypage_charge_history;

  /// Auto-generated metadata for key 'goonghap_time_slot_unknown'.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get goonghap_time_slot_unknown;

  /// Auto-generated metadata for key 'label_popup_hide_7days'.
  ///
  /// In en, this message translates to:
  /// **'Don\'t view for 7 days'**
  String get label_popup_hide_7days;

  /// Auto-generated metadata for key 'expiring_soon_bonus_candy'.
  ///
  /// In en, this message translates to:
  /// **'Expiring Bonus Star Candy'**
  String get expiring_soon_bonus_candy;

  /// Auto-generated metadata for key 'bonus_candy_expiration_policy_earn_period'.
  ///
  /// In en, this message translates to:
  /// **'Earn Period'**
  String get bonus_candy_expiration_policy_earn_period;

  /// Auto-generated metadata for key 'message_setting_remove_cache'.
  ///
  /// In en, this message translates to:
  /// **'Cache memory deletion is complete.'**
  String get message_setting_remove_cache;

  /// Auto-generated metadata for key 'error_loading_more_comments'.
  ///
  /// In en, this message translates to:
  /// **'There was an error loading the comment.'**
  String get error_loading_more_comments;

  /// Auto-generated metadata for key 'purchase_timeout_message'.
  ///
  /// In en, this message translates to:
  /// **'Purchase processing is taking too long.\nPlease try again later.'**
  String get purchase_timeout_message;

  /// Auto-generated metadata for key 'label_tabbar_vote_upcoming'.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get label_tabbar_vote_upcoming;

  /// Auto-generated metadata for key 'bonus_candy_example_1_earn'.
  ///
  /// In en, this message translates to:
  /// **'__MONTH__ 10th 14:00(KST)'**
  String get bonus_candy_example_1_earn;

  /// Auto-generated metadata for key 'error_receipt_verification_failed'.
  ///
  /// In en, this message translates to:
  /// **'Receipt verification failed.'**
  String get error_receipt_verification_failed;

  /// Auto-generated metadata for key 'vote_item_request_status_cancelled'.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get vote_item_request_status_cancelled;

  /// Auto-generated metadata for key 'post_write_board_post'.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get post_write_board_post;

  /// Auto-generated metadata for key 'bonus_candy_policy_3'.
  ///
  /// In en, this message translates to:
  /// **'- Expired Bonus Star Candy cannot be recovered, so please be sure to use it within the period.'**
  String get bonus_candy_policy_3;

  /// Auto-generated metadata for key 'message_update_nickname_fail'.
  ///
  /// In en, this message translates to:
  /// **'Nickname change failed.\nPlease select a different nickname.'**
  String get message_update_nickname_fail;

  /// Auto-generated metadata for key 'bonus_candy_expiration_time_title'.
  ///
  /// In en, this message translates to:
  /// **'Expiration Time'**
  String get bonus_candy_expiration_time_title;

  /// Auto-generated metadata for key 'post_comment_action_show_translation'.
  ///
  /// In en, this message translates to:
  /// **'View translations'**
  String get post_comment_action_show_translation;

  /// Auto-generated metadata for key 'fortune_lucky_direction'.
  ///
  /// In en, this message translates to:
  /// **'Direction of Fortune'**
  String get fortune_lucky_direction;

  /// Auto-generated metadata for key 'error_message_login_failed'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login.'**
  String get error_message_login_failed;

  /// Auto-generated metadata for key 'dialog_withdraw_button_ok'.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribing'**
  String get dialog_withdraw_button_ok;

  /// Auto-generated metadata for key 'goonghap_birthtime_subtitle'.
  ///
  /// In en, this message translates to:
  /// **'Increase accuracy!'**
  String get goonghap_birthtime_subtitle;

  /// Auto-generated metadata for key 'title_dialog_success'.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get title_dialog_success;

  /// Auto-generated metadata for key 'bonus_candy_policy_title'.
  ///
  /// In en, this message translates to:
  /// **'Bonus Star Candy Policy'**
  String get bonus_candy_policy_title;

  /// Auto-generated metadata for key 'bonus_candy_example_expiration_date'.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get bonus_candy_example_expiration_date;

  /// Auto-generated metadata for key 'label_tab_free_charge_station'.
  ///
  /// In en, this message translates to:
  /// **'Free charging stations'**
  String get label_tab_free_charge_station;

  /// Auto-generated metadata for key 'error_user_not_authenticated'.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in. Please log in again.'**
  String get error_user_not_authenticated;

  /// Auto-generated metadata for key 'text_dialog_vote_amount_should_not_zero'.
  ///
  /// In en, this message translates to:
  /// **'The number of votes cannot be zero.'**
  String get text_dialog_vote_amount_should_not_zero;

  /// Auto-generated metadata for key 'message_agreement_success'.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of the terms is complete.'**
  String get message_agreement_success;

  /// Auto-generated metadata for key 'bonus_candy_earn_period_1_to_15'.
  ///
  /// In en, this message translates to:
  /// **'1st 00:00:00 ~ 15th 23:59:59'**
  String get bonus_candy_earn_period_1_to_15;

  /// Auto-generated metadata for key 'goonghap_snackbar_need_birthday'.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth.'**
  String get goonghap_snackbar_need_birthday;

  /// No description provided for @update_recommend_text.
  ///
  /// In en, this message translates to:
  /// **'A new version ({version}) is available.'**
  String update_recommend_text(String version);

  /// Auto-generated metadata for key 'error_product_not_found'.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the purchased product.'**
  String get error_product_not_found;

  /// Auto-generated metadata for key 'label_popup_close'.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get label_popup_close;

  /// Auto-generated metadata for key 'jma_voting_info_text'.
  ///
  /// In en, this message translates to:
  /// **'-Bonus star candy can be used for JMA voting up to 5 times a day.\n-The required star candy is automatically converted. (30 Star Candy = 1 JMA Vote)\n-Participation in the vote will automatically enter you into the Jakarta concert.'**
  String get jma_voting_info_text;

  /// Auto-generated metadata for key 'vote_item_request_search_artist_hint'.
  ///
  /// In en, this message translates to:
  /// **'Search for artist or group'**
  String get vote_item_request_search_artist_hint;

  /// Auto-generated metadata for key 'bonus_candy_expiration_month_after_next'.
  ///
  /// In en, this message translates to:
  /// **'Month after next 15th 00:00:00'**
  String get bonus_candy_expiration_month_after_next;

  /// Auto-generated metadata for key 'post_comment_action_show_original'.
  ///
  /// In en, this message translates to:
  /// **'View full text'**
  String get post_comment_action_show_original;

  /// Auto-generated metadata for key 'goonghap_snackbar_need_profile_save_agree'.
  ///
  /// In en, this message translates to:
  /// **'Give your consent to save your profile.'**
  String get goonghap_snackbar_need_profile_save_agree;

  /// Auto-generated metadata for key 'qna_content_min_length'.
  ///
  /// In en, this message translates to:
  /// **'Inquiry content must be at least 10 characters'**
  String get qna_content_min_length;

  /// Auto-generated metadata for key 'post_ask_go_to_temporary_save_list'.
  ///
  /// In en, this message translates to:
  /// **'Want to go to the Drafts list?'**
  String get post_ask_go_to_temporary_save_list;

  /// Auto-generated metadata for key 'label_pic_pic_synthesizing_image'.
  ///
  /// In en, this message translates to:
  /// **'Compositing an image...'**
  String get label_pic_pic_synthesizing_image;

  /// Auto-generated metadata for key 'label_tab_buy_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Buy star candy'**
  String get label_tab_buy_star_candy;

  /// No description provided for @jma_voting_max_votes_exceeded.
  ///
  /// In en, this message translates to:
  /// **'The current maximum possible votes is {maxVotes}.'**
  String jma_voting_max_votes_exceeded(int maxVotes);

  /// No description provided for @jma_voting_daily_limit_remaining.
  ///
  /// In en, this message translates to:
  /// **'Today\'s remaining bonus votes: {remaining} times (max {max} times)'**
  String jma_voting_daily_limit_remaining(int remaining, int max);

  /// Auto-generated metadata for key 'post_temporary_save_complete'.
  ///
  /// In en, this message translates to:
  /// **'Draft complete.'**
  String get post_temporary_save_complete;

  /// Auto-generated metadata for key 'bonus_candy_example_title'.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get bonus_candy_example_title;

  /// Auto-generated metadata for key 'label_pic_pic_initializing_camera'.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get label_pic_pic_initializing_camera;

  /// Auto-generated metadata for key 'post_write_post_recommend_write'.
  ///
  /// In en, this message translates to:
  /// **'Please create a post.'**
  String get post_write_post_recommend_write;

  /// Auto-generated metadata for key 'jma_voting_daily_limit_exhausted'.
  ///
  /// In en, this message translates to:
  /// **'You have used all bonus votes for today.'**
  String get jma_voting_daily_limit_exhausted;

  /// Auto-generated metadata for key 'bonus_candy_policy_1'.
  ///
  /// In en, this message translates to:
  /// **'- Bonus Star Candy from free charging stations and bonus Star Candy from purchases have an expiration date.'**
  String get bonus_candy_policy_1;

  /// Auto-generated metadata for key 'goonghap_perfect_score_exists_title'.
  ///
  /// In en, this message translates to:
  /// **'Already Winning Matches Data'**
  String get goonghap_perfect_score_exists_title;

  /// Auto-generated metadata for key 'goonghap_duplicate_data_message'.
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap data with the same conditions already exists.'**
  String get goonghap_duplicate_data_message;

  /// No description provided for @label_time_ago_minute.
  ///
  /// In en, this message translates to:
  /// **'{minute} minutes ago'**
  String label_time_ago_minute(int minute);

  /// No description provided for @update_required_text.
  ///
  /// In en, this message translates to:
  /// **'You need to update to a new version ({version}).'**
  String update_required_text(String version);

  /// No description provided for @jma_voting_star_candy_shortage.
  ///
  /// In en, this message translates to:
  /// **'You need {shortage} more star candies.'**
  String jma_voting_star_candy_shortage(int shortage);

  /// Auto-generated metadata for key 'bonus_candy_earn_period_16_to_end'.
  ///
  /// In en, this message translates to:
  /// **'16th 00:00:00 ~ end of month 23:59:59'**
  String get bonus_candy_earn_period_16_to_end;

  /// Auto-generated metadata for key 'error_message_withdrawal'.
  ///
  /// In en, this message translates to:
  /// **'A member who has unsubscribed.'**
  String get error_message_withdrawal;

  /// No description provided for @text_achievement.
  ///
  /// In en, this message translates to:
  /// **'🎉 You\'ve reached {count} goals so far! 🎉'**
  String text_achievement(int count);

  /// Auto-generated metadata for key 'label_login_with_wechat'.
  ///
  /// In en, this message translates to:
  /// **'Login with WeChat'**
  String get label_login_with_wechat;

  /// Auto-generated metadata for key 'withdrawal_success'.
  ///
  /// In en, this message translates to:
  /// **'The unsubscribe was processed successfully.'**
  String get withdrawal_success;

  /// Auto-generated metadata for key 'vote_item_request_already_applied_artist'.
  ///
  /// In en, this message translates to:
  /// **'You have already applied for this artist.'**
  String get vote_item_request_already_applied_artist;

  /// Auto-generated metadata for key 'bonus_candy_expiration_policy_expiration_date'.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get bonus_candy_expiration_policy_expiration_date;

  /// Auto-generated metadata for key 'bonus_candy_example_2_earn'.
  ///
  /// In en, this message translates to:
  /// **'__MONTH__ 20th 14:00(KST)'**
  String get bonus_candy_example_2_earn;

  /// Auto-generated metadata for key 'message_agreement_fail'.
  ///
  /// In en, this message translates to:
  /// **'Terms agreement required'**
  String get message_agreement_fail;

  /// Auto-generated metadata for key 'vote_item_request_button'.
  ///
  /// In en, this message translates to:
  /// **'Recommend Candidate'**
  String get vote_item_request_button;

  /// Auto-generated metadata for key 'bonus_candy_expiration_next_month'.
  ///
  /// In en, this message translates to:
  /// **'Next month 15th 00:00:00'**
  String get bonus_candy_expiration_next_month;

  /// Auto-generated metadata for key 'error_delete_post'.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting the post.'**
  String get error_delete_post;

  /// Auto-generated metadata for key 'qna_title_min_length'.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters'**
  String get qna_title_min_length;

  /// Auto-generated metadata for key 'message_update_nickname_success'.
  ///
  /// In en, this message translates to:
  /// **'Your nickname has been successfully changed.'**
  String get message_update_nickname_success;

  /// Auto-generated metadata for key 'goonghap_new_ask'.
  ///
  /// In en, this message translates to:
  /// **'Want to see a new Goong-Hap?'**
  String get goonghap_new_ask;

  /// No description provided for @post_replying_comment.
  ///
  /// In en, this message translates to:
  /// **'Replying to {nickname}...'**
  String post_replying_comment(String nickname);

  /// Auto-generated metadata for key 'button_pic_pic_save'.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get button_pic_pic_save;

  /// Auto-generated metadata for key 'goonghap_perfect_score_exists'.
  ///
  /// In en, this message translates to:
  /// **'Please note that the Goong-Hap data for this condition has already earned rewards, so we are unable to award additional rewards.'**
  String get goonghap_perfect_score_exists;

  /// Auto-generated metadata for key 'post_minor_board_create_request_message_input'.
  ///
  /// In en, this message translates to:
  /// **'Enter a message requesting to open a board.'**
  String get post_minor_board_create_request_message_input;

  /// Auto-generated metadata for key 'fortune_purchase_by_star_candy'.
  ///
  /// In en, this message translates to:
  /// **'Check with StarCandy'**
  String get fortune_purchase_by_star_candy;

  /// Auto-generated metadata for key 'post_minor_board_create_request_message_condition'.
  ///
  /// In en, this message translates to:
  /// **'Please include at least 10 characters in your message requesting to open a board.'**
  String get post_minor_board_create_request_message_condition;

  /// Auto-generated metadata for key 'post_board_create_request_reviewing'.
  ///
  /// In en, this message translates to:
  /// **'Reviewing a request to open a board'**
  String get post_board_create_request_reviewing;

  /// Auto-generated metadata for key 'post_minor_board_create_request_message'.
  ///
  /// In en, this message translates to:
  /// **'* Message requesting to open a board.'**
  String get post_minor_board_create_request_message;

  /// Auto-generated metadata for key 'goonghap_purchase_confirm_title'.
  ///
  /// In en, this message translates to:
  /// **'Purchase with Star Candy'**
  String get goonghap_purchase_confirm_title;

  /// Auto-generated metadata for key 'post_board_create_request_label'.
  ///
  /// In en, this message translates to:
  /// **'Request to open a board'**
  String get post_board_create_request_label;

  /// Notice shown when the last message is from admin in QnA thread.
  ///
  /// In en, this message translates to:
  /// **'If there is no additional conversation for 14 days, the inquiry will be closed automatically.'**
  String get qna_auto_close_after_14_days_notice;

  /// QnA status when inquiry is received (waiting for admin)
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get qna_status_received;

  /// QnA status when processing is ongoing
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get qna_status_in_progress;

  /// QnA status when resolved/closed
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get qna_status_resolved;

  /// Title for closing ad confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Close the ad?'**
  String get ad_close_confirm_title;

  /// Message for closing ad confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Closing now will not grant the bonus reward. Are you sure you want to close?'**
  String get ad_close_confirm_message;

  /// CTA button after ad finished
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get ad_more_info_button;

  /// Ad view credited success message
  ///
  /// In en, this message translates to:
  /// **'Reward credited.'**
  String get ad_reward_success_message;

  /// Weekly vote info popup title
  ///
  /// In en, this message translates to:
  /// **'🎖️ Weekly Vote Guide'**
  String get weekly_vote_info_title;

  /// Weekly vote info popup body
  ///
  /// In en, this message translates to:
  /// **'Picnic\'s Hall of Fame Award opens every week!\n\nEach weekly winner is automatically nominated for the year-end \'Hall of Fame Award\',\n\nwith a total of 50 weekly winners selected annually.\n\n(※ Once an artist wins, they are excluded from weekly vote candidates for the rest of that year.)'**
  String get weekly_vote_info_body;

  /// Link label asking what weekly voting is
  ///
  /// In en, this message translates to:
  /// **'What is Weekly Vote?'**
  String get weekly_vote_info_link;

  /// Title for the patch status section in Settings.
  ///
  /// In en, this message translates to:
  /// **'Patch status'**
  String get label_setting_patch_section_title;

  /// Button label for manually checking Shorebird patches.
  ///
  /// In en, this message translates to:
  /// **'Check for patches'**
  String get label_setting_patch_check_button;

  /// Button label for manually applying a downloaded patch.
  ///
  /// In en, this message translates to:
  /// **'Apply update'**
  String get label_setting_patch_apply_button;

  /// Status text shown while patch status check is running.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get label_setting_patch_checking;

  /// Label that shows when the patch status was last checked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {time}'**
  String label_setting_patch_last_checked(String time);

  /// Status label when a restart is required to apply a patch.
  ///
  /// In en, this message translates to:
  /// **'Update ready (restart required)'**
  String get label_setting_patch_status_restart_required;

  /// Status label when a patch has been downloaded.
  ///
  /// In en, this message translates to:
  /// **'Update downloaded'**
  String get label_setting_patch_status_downloaded;

  /// Status label when a patch is available.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get label_setting_patch_status_available;

  /// Status label showing the current patch number.
  ///
  /// In en, this message translates to:
  /// **'Current patch: {patchNumber}'**
  String label_setting_patch_status_current_patch(int patchNumber);

  /// Status label when no patch is applied.
  ///
  /// In en, this message translates to:
  /// **'No patch applied'**
  String get label_setting_patch_status_none;

  /// Hint shown when a restart is required after downloading a patch.
  ///
  /// In en, this message translates to:
  /// **'A new patch has been downloaded. Tap Restart to apply it.'**
  String get message_setting_patch_restart_hint;

  /// iOS-specific hint since iOS cannot programmatically restart the app.
  ///
  /// In en, this message translates to:
  /// **'A new update has been downloaded. Please close and reopen the app to apply it.'**
  String get message_setting_patch_restart_hint_ios;

  /// Warning shown when patch actions are attempted on web platforms.
  ///
  /// In en, this message translates to:
  /// **'Patch updates aren\'t available on web.'**
  String get message_setting_patch_web_not_supported;

  /// Snackbar text when a patch update is available.
  ///
  /// In en, this message translates to:
  /// **'A new patch is available.'**
  String get message_setting_patch_update_available;

  /// Snackbar text when a patch update completes successfully.
  ///
  /// In en, this message translates to:
  /// **'Patch update complete!'**
  String get message_setting_patch_update_success;

  /// Dialog text shown while the app is restarting after patch update.
  ///
  /// In en, this message translates to:
  /// **'Restarting app...'**
  String get message_setting_patch_restarting;

  /// Snackbar text when applying a patch fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply the patch: {error}'**
  String message_setting_patch_update_failed(String error);

  /// Snackbar text when checking patch status fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to check patch status: {error}'**
  String message_setting_patch_status_failed(String error);

  /// Snackbar text when patch status is unavailable (e.g., offline).
  ///
  /// In en, this message translates to:
  /// **'Patch status unavailable. Please try again later.'**
  String get message_setting_patch_status_unavailable;

  /// Snackbar text when the user is already on the latest patch.
  ///
  /// In en, this message translates to:
  /// **'You\'re already on the latest patch.'**
  String get message_setting_patch_up_to_date;

  /// Snackbar shown when patch download completes (medium notification level).
  ///
  /// In en, this message translates to:
  /// **'Update ready. It will apply when you switch apps.'**
  String get message_patch_download_complete;

  /// Toast shown after a patch has been applied on app restart.
  ///
  /// In en, this message translates to:
  /// **'App has been updated to the latest version.'**
  String get message_patch_applied;

  /// Title for the restart confirmation dialog on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Restart app'**
  String get dialog_setting_restart_title;

  /// Body text for the restart confirmation dialog on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'A new update is ready. The app will restart to apply the changes.\n\nContinue?'**
  String get dialog_setting_restart_body;

  /// Label for restart buttons.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get button_restart;

  /// Label for update buttons.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get button_update;

  /// Local push notification title when a patch update is ready to apply.
  ///
  /// In en, this message translates to:
  /// **'Update Ready'**
  String get notification_patch_update_ready_title;

  /// Local push notification body when a patch update is ready to apply.
  ///
  /// In en, this message translates to:
  /// **'Please close and reopen the app to apply the update.'**
  String get notification_patch_update_ready_body;

  /// Local push notification title when a patch has been downloaded.
  ///
  /// In en, this message translates to:
  /// **'Update Downloaded'**
  String get notification_patch_downloaded_title;

  /// Local push notification body when a patch has been downloaded.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to apply the update.'**
  String get notification_patch_downloaded_body;

  /// Suffix appended to build information to show the current patch number.
  ///
  /// In en, this message translates to:
  /// **' / Patch: {patchNumber}'**
  String label_setting_patch_number(int patchNumber);

  /// Guide text shown before user starts searching for artist
  ///
  /// In en, this message translates to:
  /// **'Search for an artist to request'**
  String get vote_item_request_search_initial_guide;

  /// Suggestion text when no search results are found
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get vote_item_request_search_try_other_keyword;

  /// Button text for opening Goong-Hap intro dialog
  ///
  /// In en, this message translates to:
  /// **'What is Goong-Hap?'**
  String get goong_hap_what_is;

  /// Title of Goong-Hap intro dialog
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap'**
  String get goong_hap_title;

  /// Subtitle of Goong-Hap intro dialog
  ///
  /// In en, this message translates to:
  /// **'What\'s your destiny with your bias?'**
  String get goong_hap_subtitle;

  /// Tradition section title in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'Korean Traditional Culture'**
  String get goong_hap_tradition_title;

  /// Tradition section description in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'Goong-Hap is a traditional Korean culture that has been passed down for hundreds of years. It\'s a special way to discover the destined chemistry between two people based on their birthdates!'**
  String get goong_hap_tradition_desc;

  /// K-POP section title in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'My Chemistry with K-POP Artists'**
  String get goong_hap_kpop_title;

  /// K-POP section description in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'How well do you match with your favorite idol? Check out your destined Goong-Hap with your bias!'**
  String get goong_hap_kpop_desc;

  /// Fun section title in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'A New Way to Enjoy Fandom'**
  String get goong_hap_fun_title;

  /// Fun section description in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'Compare and share your Goong-Hap scores with friends! Who matches best with their bias?'**
  String get goong_hap_fun_desc;

  /// Notice text in Goong-Hap intro
  ///
  /// In en, this message translates to:
  /// **'Enjoy Goong-Hap results just for fun! Experience Korean traditional culture with K-POP'**
  String get goong_hap_notice;

  /// Close button text in Goong-Hap intro dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get goong_hap_close_button;

  /// Title for patch restart dialog
  ///
  /// In en, this message translates to:
  /// **'Update Ready'**
  String get patch_update_ready_title;

  /// Message for iOS users to manually restart app
  ///
  /// In en, this message translates to:
  /// **'A new update has been downloaded. Please close and reopen the app to apply the update.'**
  String get patch_update_ios_message;

  /// Message for Android users asking to restart
  ///
  /// In en, this message translates to:
  /// **'A new update has been downloaded. Restart the app now to apply the update?'**
  String get patch_update_android_message;

  /// Button to dismiss patch restart dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get patch_button_later;

  /// Button to restart app for patch
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get patch_button_restart;

  /// OK button for iOS patch dialog
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get patch_button_ok;

  /// Detailed message for iOS users explaining how to apply patch
  ///
  /// In en, this message translates to:
  /// **'A new update has been downloaded and is ready to apply. Please completely close the app and reopen it to apply the update.'**
  String get patch_update_ios_message_detailed;

  /// Countdown message before auto restart on Android
  ///
  /// In en, this message translates to:
  /// **'Auto restart in {seconds} seconds...'**
  String patch_auto_restart_countdown(int seconds);

  /// Title for iOS app close instructions
  ///
  /// In en, this message translates to:
  /// **'How to close the app:'**
  String get patch_ios_how_to_close_title;

  /// Step 1 for closing app on iOS
  ///
  /// In en, this message translates to:
  /// **'1. Swipe up from the bottom of the screen'**
  String get patch_ios_how_to_close_step1;

  /// Step 2 for closing app on iOS
  ///
  /// In en, this message translates to:
  /// **'2. Find this app in the app switcher'**
  String get patch_ios_how_to_close_step2;

  /// Step 3 for closing app on iOS
  ///
  /// In en, this message translates to:
  /// **'3. Swipe up on the app to close it'**
  String get patch_ios_how_to_close_step3;

  /// Button to restart app immediately
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get patch_button_restart_now;

  /// Button to acknowledge iOS restart instructions
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get patch_button_understood;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'es',
    'fil',
    'id',
    'ja',
    'ko',
    'my',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'bn':
      {
        switch (locale.countryCode) {
          case 'BD':
            return AppLocalizationsBnBd();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fil':
      return AppLocalizationsFil();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'my':
      return AppLocalizationsMy();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
