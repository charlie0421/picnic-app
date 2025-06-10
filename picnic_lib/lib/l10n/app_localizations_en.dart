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
  String get vote_item_request_search_artist_hint =>
      'Search for artist or group';

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

  @override
  String get vote_item_request_current_item_request => 'Current Item Request';

  @override
  String get vote_item_request_no_item_request_yet => 'No item request yet';

  @override
  String get vote_item_request_search_artist => 'Search Artist';

  @override
  String get vote_item_request_search_artist_prompt =>
      'Search for an artist to apply';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count item requests';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return 'Total $count item requests';
  }

  @override
  String get vote_item_request_submit => 'Submit';

  @override
  String get vote_item_request_already_registered => 'Already registered';

  @override
  String get vote_item_request_can_apply => 'Can apply';

  @override
  String get vote_item_request_status_pending => 'Pending';

  @override
  String get vote_item_request_status_approved => 'Approved';

  @override
  String get vote_item_request_status_rejected => 'Rejected';

  @override
  String get vote_item_request_status_in_progress => 'In Progress';

  @override
  String get vote_item_request_status_cancelled => 'Cancelled';

  @override
  String get vote_item_request_status_unknown => 'Unknown';

  @override
  String get vote_item_request_artist_name_missing => 'Artist name missing';

  @override
  String get vote_item_request_user_info_not_found =>
      'User information not found.';

  @override
  String get vote_item_request_already_applied_artist =>
      'You have already applied for this artist.';

  @override
  String get vote_item_request_addition_request => 'Vote item addition request';
}
