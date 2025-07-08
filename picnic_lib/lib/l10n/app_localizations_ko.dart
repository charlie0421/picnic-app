// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '피크닉';

  @override
  String get vote_item_request_title => '투표 후보 신청';

  @override
  String get vote_item_request_button => '투표 신청하기';

  @override
  String get artist_name_label => '아티스트명';

  @override
  String get group_name_label => '그룹명';

  @override
  String get application_reason_label => '신청 사유';

  @override
  String get artist_name_hint => '아티스트명을 입력하세요';

  @override
  String get group_name_hint => '그룹명을 입력하세요 (선택사항)';

  @override
  String get application_reason_hint => '신청 사유를 입력하세요 (선택사항)';

  @override
  String get submit_application => '신청하기';

  @override
  String get vote_item_request_search_artist_hint => '아티스트나 그룹을 검색하세요';

  @override
  String get application_success => '투표 후보 신청이 완료되었습니다.';

  @override
  String get success => '성공';

  @override
  String get vote_period => '투표 기간';

  @override
  String get error_artist_not_selected => '아티스트를 선택해주세요';

  @override
  String get error_application_reason_required => '신청 사유를 입력해주세요';

  @override
  String get searching => '검색 중...';

  @override
  String get no_search_results => '검색 결과가 없습니다';

  @override
  String get vote_item_request_current_item_request => '현재 아이템 요청';

  @override
  String get vote_item_request_no_item_request_yet => '아직 아이템 요청이 없습니다';

  @override
  String get vote_item_request_search_artist => '아티스트 검색';

  @override
  String get vote_item_request_search_artist_prompt => '아티스트를 검색하여 신청하세요';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count개 아이템 요청';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return '총 $count개 아이템 요청';
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
  String get label_tabbar_vote_active => '진행중';

  @override
  String get label_tabbar_vote_image => '이미지 투표';

  @override
  String get label_tabbar_vote_end => '종료됨';

  @override
  String get label_tabbar_vote_upcoming => '예정됨';
}
