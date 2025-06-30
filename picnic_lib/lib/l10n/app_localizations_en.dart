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

  @override
  String get label_tabbar_vote_active => 'Active';

  @override
  String get label_tabbar_vote_image => 'Image Vote';

  @override
  String get label_tabbar_vote_end => 'Ended';

  @override
  String get label_tabbar_vote_upcoming => 'Upcoming';

  @override
  String get label_reply => 'Reply';

  @override
  String get post_comment_action_show_translation => 'Show Translation';

  @override
  String get post_comment_action_show_original => 'Show Original';

  @override
  String get post_comment_action_translate => 'Translate';

  @override
  String get post_comment_reported_comment => 'Reported Comment';

  @override
  String get post_comment_deleted_comment => 'Deleted Comment';

  @override
  String get post_comment_content_more => 'Show More';

  @override
  String get post_comment_translated => 'Translated';

  @override
  String get post_my_written_reply => 'My Comments';

  @override
  String get post_comment_delete_fail => 'Failed to delete comment.';

  @override
  String get post_comment_loading_fail => 'Failed to load comments.';

  @override
  String get common_retry_label => 'Retry';

  @override
  String get error_action_failed => 'Action failed.';

  @override
  String get label_article_comment_empty => 'No comments yet.';

  @override
  String get error_loading_more_comments => 'Failed to load more comments.';

  @override
  String get label_retry => 'Retry';

  @override
  String get label_hint_comment => 'Write a comment';

  @override
  String get dialog_caution => 'Caution';

  @override
  String get post_flagged => 'This post has been reported.';

  @override
  String get post_comment_registered_comment => 'Comment has been posted.';

  @override
  String get post_comment_register_fail => 'Failed to post comment.';

  @override
  String get post_comment_translate_fail => 'Failed to translate comment.';

  @override
  String get label_read_more_comment => 'Read More Comments';

  @override
  String get popup_label_delete => 'Delete';

  @override
  String get post_comment_delete_confirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get label_title_report => 'Report';
}
