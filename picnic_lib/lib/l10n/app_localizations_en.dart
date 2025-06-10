// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Picnic';

  @override
  String get vote_item_request_title => 'Vote Candidate Application';

  @override
  String get vote_item_request_button => 'Apply for Vote Candidate';

  @override
  String get artist_name_label => 'Artist Name';

  @override
  String get group_name_label => 'Group Name';

  @override
  String get application_reason_label => 'Application Reason';

  @override
  String get artist_name_hint => 'Enter artist name';

  @override
  String get group_name_hint => 'Enter group name (optional)';

  @override
  String get application_reason_hint => 'Enter application reason (optional)';

  @override
  String get submit_application => 'Submit Application';

  @override
  String get search_artist_hint => 'Search for artist or group';

  @override
  String get application_success =>
      'Vote candidate application has been completed.';

  @override
  String get success => 'Success';

  @override
  String get vote_period => 'Vote Period';

  @override
  String get error_artist_not_selected => 'Please select an artist';

  @override
  String get error_application_reason_required =>
      'Application reason is required';

  @override
  String get searching => 'Searching...';

  @override
  String get no_search_results => 'No search results found';
}
