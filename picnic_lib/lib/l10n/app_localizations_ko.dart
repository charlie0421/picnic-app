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
  String get vote_item_request_search_artist_hint =>
      'Search for artist or group';

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

  @override
  String get vote_item_request_current_item_request => 'Current Item Request';

  @override
  String get vote_item_request_no_item_request_yet => 'No item request yet';

  @override
  String get vote_item_request_search_artist => '아티스트 검색';

  @override
  String get vote_item_request_search_artist_prompt => '아티스트명을 검색하여 신청해 보세요';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count item requests';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return 'Total $count item requests';
  }

  @override
  String get vote_item_request_submit => '신청';

  @override
  String get vote_item_request_already_registered => '이미 등록됨';

  @override
  String get vote_item_request_can_apply => '신청 가능';

  @override
  String get vote_item_request_status_pending => '대기중';

  @override
  String get vote_item_request_status_approved => '승인됨';

  @override
  String get vote_item_request_status_rejected => '거절됨';

  @override
  String get vote_item_request_status_in_progress => '진행중';

  @override
  String get vote_item_request_status_cancelled => '취소됨';

  @override
  String get vote_item_request_status_unknown => '알 수 없음';

  @override
  String get vote_item_request_artist_name_missing => '아티스트명 없음';

  @override
  String get vote_item_request_user_info_not_found => '사용자 정보를 찾을 수 없습니다.';

  @override
  String get vote_item_request_already_applied_artist =>
      '이미 해당 아티스트에 대해 신청하셨습니다.';

  @override
  String get vote_item_request_addition_request => '투표 아이템 추가 신청';

  @override
  String get label_tabbar_vote_active => 'Active';

  @override
  String get label_tabbar_vote_image => 'Image Vote';

  @override
  String get label_tabbar_vote_end => 'Ended';

  @override
  String get label_tabbar_vote_upcoming => 'Upcoming';

  @override
  String get label_reply => '답글';

  @override
  String get post_comment_action_show_translation => '번역 보기';

  @override
  String get post_comment_action_show_original => '원문 보기';

  @override
  String get post_comment_action_translate => '번역하기';

  @override
  String get post_comment_reported_comment => '신고된 댓글';

  @override
  String get post_comment_deleted_comment => '삭제된 댓글';

  @override
  String get post_comment_content_more => '더보기';

  @override
  String get post_comment_translated => '번역됨';

  @override
  String get post_my_written_reply => '내가 쓴 댓글';

  @override
  String get post_comment_delete_fail => '댓글 삭제에 실패했습니다.';

  @override
  String get post_comment_loading_fail => '댓글 로딩에 실패했습니다.';

  @override
  String get common_retry_label => '다시 시도';

  @override
  String get error_action_failed => '작업이 실패했습니다.';

  @override
  String get label_article_comment_empty => '댓글이 없습니다.';

  @override
  String get error_loading_more_comments => '댓글을 더 불러오는데 실패했습니다.';

  @override
  String get label_retry => '다시 시도';

  @override
  String get label_hint_comment => '댓글을 입력하세요';

  @override
  String get dialog_caution => '주의';

  @override
  String get post_flagged => '이 게시물은 신고되었습니다.';

  @override
  String get post_comment_registered_comment => '댓글이 등록되었습니다.';

  @override
  String get post_comment_register_fail => '댓글 등록에 실패했습니다.';

  @override
  String get post_comment_translate_fail => '댓글 번역에 실패했습니다.';

  @override
  String get label_read_more_comment => '댓글 더보기';

  @override
  String get popup_label_delete => '삭제';

  @override
  String get post_comment_delete_confirm => '댓글을 삭제하시겠습니까?';

  @override
  String get label_title_report => '신고';
}
