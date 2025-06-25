import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
    Locale('en'),
    Locale('ko')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Picnic'**
  String get appTitle;

  /// Title for vote application dialog
  ///
  /// In en, this message translates to:
  /// **'Vote Candidate Application'**
  String get vote_item_request_title;

  /// Button text for applying as vote candidate
  ///
  /// In en, this message translates to:
  /// **'Apply for Vote Candidate'**
  String get vote_item_request_button;

  /// Label for artist name field
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artist_name_label;

  /// Label for group name field
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get group_name_label;

  /// Label for application reason field
  ///
  /// In en, this message translates to:
  /// **'Application Reason'**
  String get application_reason_label;

  /// Hint text for artist name field
  ///
  /// In en, this message translates to:
  /// **'Enter artist name'**
  String get artist_name_hint;

  /// Hint text for group name field
  ///
  /// In en, this message translates to:
  /// **'Enter group name (optional)'**
  String get group_name_hint;

  /// Hint text for application reason field
  ///
  /// In en, this message translates to:
  /// **'Enter application reason (optional)'**
  String get application_reason_hint;

  /// Submit button text
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submit_application;

  /// Hint text for artist search field
  ///
  /// In en, this message translates to:
  /// **'Search for artist or group'**
  String get vote_item_request_search_artist_hint;

  /// Success message for application submission
  ///
  /// In en, this message translates to:
  /// **'Vote candidate application has been completed.'**
  String get application_success;

  /// Success dialog title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Label for vote period
  ///
  /// In en, this message translates to:
  /// **'Vote Period'**
  String get vote_period;

  /// Error message when no artist is selected
  ///
  /// In en, this message translates to:
  /// **'Please select an artist'**
  String get error_artist_not_selected;

  /// Error message when application reason is empty
  ///
  /// In en, this message translates to:
  /// **'Application reason is required'**
  String get error_application_reason_required;

  /// Text shown while searching
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// Text shown when no search results are found
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get no_search_results;

  /// No description provided for @vote_item_request_current_item_request.
  ///
  /// In en, this message translates to:
  /// **'Current Item Request'**
  String get vote_item_request_current_item_request;

  /// No description provided for @vote_item_request_no_item_request_yet.
  ///
  /// In en, this message translates to:
  /// **'No item request yet'**
  String get vote_item_request_no_item_request_yet;

  /// No description provided for @vote_item_request_search_artist.
  ///
  /// In en, this message translates to:
  /// **'Search Artist'**
  String get vote_item_request_search_artist;

  /// No description provided for @vote_item_request_search_artist_prompt.
  ///
  /// In en, this message translates to:
  /// **'Search for an artist to apply'**
  String get vote_item_request_search_artist_prompt;

  /// No description provided for @vote_item_request_item_request_count.
  ///
  /// In en, this message translates to:
  /// **'{count} item requests'**
  String vote_item_request_item_request_count(Object count);

  /// No description provided for @vote_item_request_total_item_requests.
  ///
  /// In en, this message translates to:
  /// **'Total {count} item requests'**
  String vote_item_request_total_item_requests(Object count);

  /// No description provided for @vote_item_request_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get vote_item_request_submit;

  /// No description provided for @vote_item_request_already_registered.
  ///
  /// In en, this message translates to:
  /// **'Already registered'**
  String get vote_item_request_already_registered;

  /// No description provided for @vote_item_request_can_apply.
  ///
  /// In en, this message translates to:
  /// **'Can apply'**
  String get vote_item_request_can_apply;

  /// No description provided for @vote_item_request_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get vote_item_request_status_pending;

  /// No description provided for @vote_item_request_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get vote_item_request_status_approved;

  /// No description provided for @vote_item_request_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get vote_item_request_status_rejected;

  /// No description provided for @vote_item_request_status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get vote_item_request_status_in_progress;

  /// No description provided for @vote_item_request_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get vote_item_request_status_cancelled;

  /// No description provided for @vote_item_request_status_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get vote_item_request_status_unknown;

  /// No description provided for @vote_item_request_artist_name_missing.
  ///
  /// In en, this message translates to:
  /// **'Artist name missing'**
  String get vote_item_request_artist_name_missing;

  /// No description provided for @vote_item_request_user_info_not_found.
  ///
  /// In en, this message translates to:
  /// **'User information not found.'**
  String get vote_item_request_user_info_not_found;

  /// No description provided for @vote_item_request_already_applied_artist.
  ///
  /// In en, this message translates to:
  /// **'You have already applied for this artist.'**
  String get vote_item_request_already_applied_artist;

  /// No description provided for @vote_item_request_addition_request.
  ///
  /// In en, this message translates to:
  /// **'Vote item addition request'**
  String get vote_item_request_addition_request;

  /// No description provided for @label_tabbar_vote_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get label_tabbar_vote_active;

  /// No description provided for @label_tabbar_vote_image.
  ///
  /// In en, this message translates to:
  /// **'Image Vote'**
  String get label_tabbar_vote_image;

  /// No description provided for @label_tabbar_vote_end.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get label_tabbar_vote_end;

  /// No description provided for @label_tabbar_vote_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get label_tabbar_vote_upcoming;

  /// No description provided for @label_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get label_reply;

  /// No description provided for @post_comment_action_show_translation.
  ///
  /// In en, this message translates to:
  /// **'Show Translation'**
  String get post_comment_action_show_translation;

  /// No description provided for @post_comment_action_show_original.
  ///
  /// In en, this message translates to:
  /// **'Show Original'**
  String get post_comment_action_show_original;

  /// No description provided for @post_comment_action_translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get post_comment_action_translate;

  /// No description provided for @post_comment_reported_comment.
  ///
  /// In en, this message translates to:
  /// **'Reported Comment'**
  String get post_comment_reported_comment;

  /// No description provided for @post_comment_deleted_comment.
  ///
  /// In en, this message translates to:
  /// **'Deleted Comment'**
  String get post_comment_deleted_comment;

  /// No description provided for @post_comment_content_more.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get post_comment_content_more;

  /// No description provided for @post_comment_translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get post_comment_translated;

  /// No description provided for @post_my_written_reply.
  ///
  /// In en, this message translates to:
  /// **'My Comments'**
  String get post_my_written_reply;

  /// No description provided for @post_comment_delete_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete comment.'**
  String get post_comment_delete_fail;

  /// No description provided for @post_comment_loading_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments.'**
  String get post_comment_loading_fail;

  /// No description provided for @common_retry_label.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry_label;

  /// No description provided for @error_action_failed.
  ///
  /// In en, this message translates to:
  /// **'Action failed.'**
  String get error_action_failed;

  /// No description provided for @label_article_comment_empty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get label_article_comment_empty;

  /// No description provided for @error_loading_more_comments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more comments.'**
  String get error_loading_more_comments;

  /// No description provided for @label_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get label_retry;

  /// No description provided for @label_hint_comment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get label_hint_comment;

  /// No description provided for @dialog_caution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get dialog_caution;

  /// No description provided for @post_flagged.
  ///
  /// In en, this message translates to:
  /// **'This post has been reported.'**
  String get post_flagged;

  /// No description provided for @post_comment_registered_comment.
  ///
  /// In en, this message translates to:
  /// **'Comment has been posted.'**
  String get post_comment_registered_comment;

  /// No description provided for @post_comment_register_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment.'**
  String get post_comment_register_fail;

  /// No description provided for @post_comment_translate_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to translate comment.'**
  String get post_comment_translate_fail;

  /// No description provided for @label_read_more_comment.
  ///
  /// In en, this message translates to:
  /// **'Read More Comments'**
  String get label_read_more_comment;

  /// No description provided for @popup_label_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get popup_label_delete;

  /// No description provided for @post_comment_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get post_comment_delete_confirm;

  /// No description provided for @label_title_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get label_title_report;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
