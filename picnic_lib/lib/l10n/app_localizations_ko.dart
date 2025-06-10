// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Picnic';

  @override
  String get vote_item_request_title => 'Vote Candidate Application';

  @override
  String get vote_item_request_button => '투표 신청하기';

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
  String get search_artist_hint => '아티스트나 그룹을 검색하세요';

  @override
  String get application_success =>
      'Vote candidate application has been completed.';

  @override
  String get success => '성공';

  @override
  String get vote_period => 'Vote Period';

  @override
  String get error_artist_not_selected => 'Please select an artist';

  @override
  String get error_application_reason_required =>
      'Application reason is required';

  @override
  String get searching => '검색 중...';

  @override
  String get no_search_results => 'No search results found';
}
