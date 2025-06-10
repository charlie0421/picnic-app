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
    Locale('ko'),
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
  String get search_artist_hint;

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
    'that was used.',
  );
}
