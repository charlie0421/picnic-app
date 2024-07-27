// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ko';

  static String m0(day) => "${day}일 전";

  static String m1(hour) => "${hour}시간 전";

  static String m2(minute) => "${minute}분 전";

  static String m3(num1) => "${num1}개 +${num1}개 보너스";

  static String m4(rank) => "${rank}위";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "app_name": MessageLookupByLibrary.simpleMessage("피크닠"),
        "button_cancel": MessageLookupByLibrary.simpleMessage("취소"),
        "button_complete": MessageLookupByLibrary.simpleMessage("완료"),
        "button_login": MessageLookupByLibrary.simpleMessage("로그인"),
        "button_ok": MessageLookupByLibrary.simpleMessage("확인"),
        "button_pic_pic_save": MessageLookupByLibrary.simpleMessage("저장하기"),
        "candy_disappear_next_month":
            MessageLookupByLibrary.simpleMessage("다음 달 사라지는 별사탕😢"),
        "candy_usage_policy_contents": MessageLookupByLibrary.simpleMessage(
            "구매한 별사탕은 무제한으로 사용 가능하지만 보너스 별사탕은 획득한 달의 다음 달 15일에 일괄 소멸됩니다."),
        "candy_usage_policy_contents2": MessageLookupByLibrary.simpleMessage(
            "별사탕 사용 시, 소멸이 임박한 별사탕이 우선적으로 사용됩니다."),
        "candy_usage_policy_guide":
            MessageLookupByLibrary.simpleMessage("*보너스는 획득한 다음달에 사라져요! ⓘ"),
        "candy_usage_policy_title":
            MessageLookupByLibrary.simpleMessage("별사탕 사용정책"),
        "dialog_button_cancel": MessageLookupByLibrary.simpleMessage("취소"),
        "dialog_button_ok": MessageLookupByLibrary.simpleMessage("확인"),
        "dialog_content_ads_exhausted": MessageLookupByLibrary.simpleMessage(
            "광고가 모두 소진되었습니다. 다음에 다시 시도해주세요."),
        "dialog_content_ads_loading":
            MessageLookupByLibrary.simpleMessage("광고 로딩중입니다."),
        "dialog_content_ads_retrying": MessageLookupByLibrary.simpleMessage(
            "광고를 다시 불러오는 중입니다. 잠시 후 다시 시도해 주세요."),
        "dialog_content_login_required":
            MessageLookupByLibrary.simpleMessage("로그인이 필요합니다"),
        "dialog_message_can_resignup":
            MessageLookupByLibrary.simpleMessage("지금 회원 탈퇴 시 재 가입 가능 일자"),
        "dialog_message_purchase_canceled":
            MessageLookupByLibrary.simpleMessage("구매가 취소되었습니다."),
        "dialog_message_purchase_failed": MessageLookupByLibrary.simpleMessage(
            "구매 중 오류가 발생했습니다. 나중에 다시 시도해 주세요."),
        "dialog_message_purchase_success":
            MessageLookupByLibrary.simpleMessage("구매가 성공적으로 완료되었습니다."),
        "dialog_purchases_fail":
            MessageLookupByLibrary.simpleMessage("구매에 실패했습니다."),
        "dialog_purchases_success":
            MessageLookupByLibrary.simpleMessage("구매가 완료되었습니다."),
        "dialog_title_ads_exhausted":
            MessageLookupByLibrary.simpleMessage("광고 모두 소진"),
        "dialog_title_vote_fail": MessageLookupByLibrary.simpleMessage("투표 실패"),
        "dialog_will_delete_star_candy":
            MessageLookupByLibrary.simpleMessage("삭제 예정 별사탕"),
        "dialog_withdraw_button_cancel":
            MessageLookupByLibrary.simpleMessage("다시 한 번 생각해 볼게요"),
        "dialog_withdraw_button_ok":
            MessageLookupByLibrary.simpleMessage("탈퇴하기"),
        "dialog_withdraw_error":
            MessageLookupByLibrary.simpleMessage("탈퇴중 에러가 발생했습니다."),
        "dialog_withdraw_message": MessageLookupByLibrary.simpleMessage(
            "회원 탈퇴 시 피크닠에 보유하신 별사탕과 계정 정보는 즉시 삭제되며, 재 가입시 기존 정보 및 데이터는 복구가 되지 않습니다."),
        "dialog_withdraw_success":
            MessageLookupByLibrary.simpleMessage("탈퇴가 성공적으로 처리 되었습니다."),
        "dialog_withdraw_title":
            MessageLookupByLibrary.simpleMessage("정말 탈퇴하시겠어요?"),
        "error_message_login_failed":
            MessageLookupByLibrary.simpleMessage("로그인 중 오류가 발생했습니다."),
        "error_message_no_user":
            MessageLookupByLibrary.simpleMessage("회원 정보가 존재하지 않습니다."),
        "error_message_withdrawal":
            MessageLookupByLibrary.simpleMessage("탈퇴한 회원입니다."),
        "error_title": MessageLookupByLibrary.simpleMessage("에러"),
        "hint_library_add": MessageLookupByLibrary.simpleMessage("앨범명"),
        "hint_nickname_input":
            MessageLookupByLibrary.simpleMessage("닉네임을 입력해주세요."),
        "image_save_success":
            MessageLookupByLibrary.simpleMessage("이미지가 저장되었습니다."),
        "label_agreement_privacy":
            MessageLookupByLibrary.simpleMessage("개인정보 수집 및 이용 동의"),
        "label_agreement_terms":
            MessageLookupByLibrary.simpleMessage("이용 약관 동의"),
        "label_album_add": MessageLookupByLibrary.simpleMessage("새로운 앨범 추가"),
        "label_article_comment_empty":
            MessageLookupByLibrary.simpleMessage("첫 댓글의 주인공이 되세요!"),
        "label_bonus": MessageLookupByLibrary.simpleMessage("보너스"),
        "label_button_agreement": MessageLookupByLibrary.simpleMessage("동의"),
        "label_button_close": MessageLookupByLibrary.simpleMessage("닫기"),
        "label_button_disagreement":
            MessageLookupByLibrary.simpleMessage("비동의"),
        "label_button_recharge": MessageLookupByLibrary.simpleMessage("충전하기"),
        "label_button_save_vote_paper":
            MessageLookupByLibrary.simpleMessage("투표증 저장"),
        "label_button_share": MessageLookupByLibrary.simpleMessage("공유하기"),
        "label_button_vote": MessageLookupByLibrary.simpleMessage("투표하기"),
        "label_button_watch_and_charge":
            MessageLookupByLibrary.simpleMessage("광고보고 충전하기"),
        "label_celeb_ask_to_you":
            MessageLookupByLibrary.simpleMessage("아티스트가 당신에게 묻다!"),
        "label_celeb_gallery": MessageLookupByLibrary.simpleMessage("아티스트 갤러리"),
        "label_celeb_recommend":
            MessageLookupByLibrary.simpleMessage("아티스트 추천"),
        "label_checkbox_entire_use":
            MessageLookupByLibrary.simpleMessage("전체사용"),
        "label_current_language": MessageLookupByLibrary.simpleMessage("현재 언어"),
        "label_draw_image":
            MessageLookupByLibrary.simpleMessage("랜덤 이미지 획득 기회"),
        "label_dropdown_oldest": MessageLookupByLibrary.simpleMessage("오래된순"),
        "label_dropdown_recent": MessageLookupByLibrary.simpleMessage("최신순"),
        "label_find_celeb":
            MessageLookupByLibrary.simpleMessage("더 많은 아티스트 찾기"),
        "label_gallery_tab_article":
            MessageLookupByLibrary.simpleMessage("아티클"),
        "label_gallery_tab_chat": MessageLookupByLibrary.simpleMessage("채팅"),
        "label_hint_comment":
            MessageLookupByLibrary.simpleMessage("댓글을 남겨주세요."),
        "label_input_input": MessageLookupByLibrary.simpleMessage("입력"),
        "label_last_provider": MessageLookupByLibrary.simpleMessage("최근 로그인"),
        "label_library_save": MessageLookupByLibrary.simpleMessage("라이브러리 저장"),
        "label_library_tab_ai_photo":
            MessageLookupByLibrary.simpleMessage("AI 포토"),
        "label_library_tab_library":
            MessageLookupByLibrary.simpleMessage("라이브러리"),
        "label_library_tab_pic": MessageLookupByLibrary.simpleMessage("PIC"),
        "label_loading_ads": MessageLookupByLibrary.simpleMessage("광고 로딩중"),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("아티스트 갤러리로 이동"),
        "label_mypage_charge_history":
            MessageLookupByLibrary.simpleMessage("충전내역"),
        "label_mypage_customer_center":
            MessageLookupByLibrary.simpleMessage("고객센터"),
        "label_mypage_logout": MessageLookupByLibrary.simpleMessage("로그아웃"),
        "label_mypage_membership_history":
            MessageLookupByLibrary.simpleMessage("멤버십 내역"),
        "label_mypage_my_artist":
            MessageLookupByLibrary.simpleMessage("나의 아티스트"),
        "label_mypage_notice": MessageLookupByLibrary.simpleMessage("공지사항"),
        "label_mypage_privacy_policy":
            MessageLookupByLibrary.simpleMessage("개인정보처리방침"),
        "label_mypage_setting":
            MessageLookupByLibrary.simpleMessage("Settings"),
        "label_mypage_should_login":
            MessageLookupByLibrary.simpleMessage("로그인 해 주세요"),
        "label_mypage_terms_of_use":
            MessageLookupByLibrary.simpleMessage("이용약관"),
        "label_mypage_vote_history":
            MessageLookupByLibrary.simpleMessage("별사탕 투표내역"),
        "label_mypage_withdrawal": MessageLookupByLibrary.simpleMessage("회원탈퇴"),
        "label_no_ads": MessageLookupByLibrary.simpleMessage("광고 없음"),
        "label_no_celeb":
            MessageLookupByLibrary.simpleMessage("아직 북마크한 아티스트가 없습니다!"),
        "label_pic_image_cropping":
            MessageLookupByLibrary.simpleMessage("이미지 자르기"),
        "label_pic_pic_initializing_camera":
            MessageLookupByLibrary.simpleMessage("카메라 초기화중..."),
        "label_pic_pic_save_gallery":
            MessageLookupByLibrary.simpleMessage("갤러리에 저장"),
        "label_pic_pic_synthesizing_image":
            MessageLookupByLibrary.simpleMessage("이미지 합성중..."),
        "label_read_more_comment":
            MessageLookupByLibrary.simpleMessage("댓글 더보기"),
        "label_reply": MessageLookupByLibrary.simpleMessage("답글 달기"),
        "label_retry": MessageLookupByLibrary.simpleMessage("재시도 하기"),
        "label_screen_title_agreement":
            MessageLookupByLibrary.simpleMessage("약관 동의"),
        "label_setting_alarm": MessageLookupByLibrary.simpleMessage("알림"),
        "label_setting_appinfo": MessageLookupByLibrary.simpleMessage("앱정보"),
        "label_setting_current_version":
            MessageLookupByLibrary.simpleMessage("현재버전"),
        "label_setting_event_alarm":
            MessageLookupByLibrary.simpleMessage("이벤트알림"),
        "label_setting_event_alarm_desc":
            MessageLookupByLibrary.simpleMessage("각종 이벤트와 행사를 안내드려요."),
        "label_setting_language": MessageLookupByLibrary.simpleMessage("언어설정"),
        "label_setting_push_alarm":
            MessageLookupByLibrary.simpleMessage("푸시알림"),
        "label_setting_recent_version":
            MessageLookupByLibrary.simpleMessage("최신버전"),
        "label_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("캐시메모리 삭제"),
        "label_setting_remove_cache_complete":
            MessageLookupByLibrary.simpleMessage("완료"),
        "label_setting_storage":
            MessageLookupByLibrary.simpleMessage("저장공간 관리"),
        "label_setting_update": MessageLookupByLibrary.simpleMessage("업데이트"),
        "label_star_candy_pouch":
            MessageLookupByLibrary.simpleMessage("별사탕 주머니"),
        "label_tab_buy_star_candy":
            MessageLookupByLibrary.simpleMessage("별사탕 구매"),
        "label_tab_free_charge_station":
            MessageLookupByLibrary.simpleMessage("무료충전소"),
        "label_tabbar_picchart_daily":
            MessageLookupByLibrary.simpleMessage("일간차트"),
        "label_tabbar_picchart_monthly":
            MessageLookupByLibrary.simpleMessage("월간차트"),
        "label_tabbar_picchart_weekly":
            MessageLookupByLibrary.simpleMessage("주간차트"),
        "label_tabbar_vote_active": MessageLookupByLibrary.simpleMessage("진행중"),
        "label_tabbar_vote_end": MessageLookupByLibrary.simpleMessage("종료"),
        "label_tabbar_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("예정"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now":
            MessageLookupByLibrary.simpleMessage("방금 전"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("댓글"),
        "label_title_report": MessageLookupByLibrary.simpleMessage("신고하기"),
        "label_vote_reward_list":
            MessageLookupByLibrary.simpleMessage("리워드 리스트"),
        "label_vote_screen_title": MessageLookupByLibrary.simpleMessage("투표"),
        "label_vote_tab_birthday":
            MessageLookupByLibrary.simpleMessage("생일 투표"),
        "label_vote_tab_pic": MessageLookupByLibrary.simpleMessage("PIC 투표"),
        "label_vote_upcoming": MessageLookupByLibrary.simpleMessage("투표 시작까지"),
        "label_vote_vote_gather":
            MessageLookupByLibrary.simpleMessage("투표 모아보기"),
        "label_watch_ads": MessageLookupByLibrary.simpleMessage("광고보기"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("나의 아티스트"),
        "message_agreement_success":
            MessageLookupByLibrary.simpleMessage("약관 동의가 완료되었습니다."),
        "message_error_occurred":
            MessageLookupByLibrary.simpleMessage("오류가 발생했습니다."),
        "message_noitem_vote_active":
            MessageLookupByLibrary.simpleMessage("현재 진행중인 투표가 없습니다."),
        "message_noitem_vote_end":
            MessageLookupByLibrary.simpleMessage("현재 종료된 투표가 없습니다."),
        "message_noitem_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("현재 예정중인 투표가 없습니다."),
        "message_pic_pic_save_fail":
            MessageLookupByLibrary.simpleMessage("이미지 저장에 실패했습니다."),
        "message_pic_pic_save_success":
            MessageLookupByLibrary.simpleMessage("이미지가 저장되었습니다."),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("신고하시겠습니까?"),
        "message_report_ok":
            MessageLookupByLibrary.simpleMessage("신고가 완료되었습니다."),
        "message_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("캐시메모리 삭제가 완료되었습니다"),
        "message_update_nickname_fail": MessageLookupByLibrary.simpleMessage(
            "닉네임 변경에 실패했습니다.\n다른 닉네임을 선택해주세요."),
        "message_update_nickname_success":
            MessageLookupByLibrary.simpleMessage("닉네임이 성공적으로 변경되었습니다."),
        "message_vote_is_ended":
            MessageLookupByLibrary.simpleMessage("종료된 투표입니다"),
        "message_vote_is_upcoming":
            MessageLookupByLibrary.simpleMessage("예정된 투표입니다"),
        "mypage_comment": MessageLookupByLibrary.simpleMessage("댓글관리"),
        "mypage_language": MessageLookupByLibrary.simpleMessage("언어설정"),
        "mypage_purchases": MessageLookupByLibrary.simpleMessage("내 구매"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("설정"),
        "mypage_subscription": MessageLookupByLibrary.simpleMessage("구독정보"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("광고"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("갤러리"),
        "nav_home": MessageLookupByLibrary.simpleMessage("홈"),
        "nav_library": MessageLookupByLibrary.simpleMessage("라이브러리"),
        "nav_media": MessageLookupByLibrary.simpleMessage("미디어"),
        "nav_picchart": MessageLookupByLibrary.simpleMessage("PIC차트"),
        "nav_purchases": MessageLookupByLibrary.simpleMessage("구매"),
        "nav_setting": MessageLookupByLibrary.simpleMessage("설정"),
        "nav_store": MessageLookupByLibrary.simpleMessage("상점"),
        "nav_subscription": MessageLookupByLibrary.simpleMessage("구독"),
        "nav_vote": MessageLookupByLibrary.simpleMessage("투표"),
        "nickname_validation_error":
            MessageLookupByLibrary.simpleMessage("20자 이내, 특수문자 제외 가능합니다."),
        "page_title_mypage": MessageLookupByLibrary.simpleMessage("마이페이지"),
        "page_title_myprofile": MessageLookupByLibrary.simpleMessage("나의 프로필"),
        "page_title_privacy": MessageLookupByLibrary.simpleMessage("개인정보처리방침"),
        "page_title_setting": MessageLookupByLibrary.simpleMessage("환경설정"),
        "page_title_terms_of_use": MessageLookupByLibrary.simpleMessage("이용약관"),
        "page_title_vote_detail": MessageLookupByLibrary.simpleMessage("투표하기"),
        "page_title_vote_gather":
            MessageLookupByLibrary.simpleMessage("투표 모아보기"),
        "share_image_fail": MessageLookupByLibrary.simpleMessage("이미지 공유 실패"),
        "share_image_success":
            MessageLookupByLibrary.simpleMessage("이미지 공유 성공"),
        "share_no_twitter": MessageLookupByLibrary.simpleMessage("트위터 앱이 없습니다"),
        "share_twitter": MessageLookupByLibrary.simpleMessage("트위터 공유"),
        "text_ads_random":
            MessageLookupByLibrary.simpleMessage("광고 보기 및 무작위 이미지 수집."),
        "text_bonus": MessageLookupByLibrary.simpleMessage("보너스"),
        "text_comming_soon_pic_chart1": MessageLookupByLibrary.simpleMessage(
            "핔 차트에 오신 여러분을 환영합니다!\n2024년 8월에 만나요!"),
        "text_comming_soon_pic_chart2": MessageLookupByLibrary.simpleMessage(
            "핔차트는 일간, 주간, 월간 점수를 반영하는\n피크닠만의 새로운 차트입니다."),
        "text_comming_soon_pic_chart3": MessageLookupByLibrary.simpleMessage(
            "실시간으로 반영되는\n아티스트의 브랜드 평판을 확인해 보세요!"),
        "text_comming_soon_pic_chart_title":
            MessageLookupByLibrary.simpleMessage("핔차트란?"),
        "text_copied_address":
            MessageLookupByLibrary.simpleMessage("주소가 복사되었습니다."),
        "text_dialog_ad_dismissed":
            MessageLookupByLibrary.simpleMessage("광고를 중간에 멈추었습니다."),
        "text_dialog_ad_failed_to_show":
            MessageLookupByLibrary.simpleMessage("광고 불러오기 실패"),
        "text_dialog_star_candy_received":
            MessageLookupByLibrary.simpleMessage("별사탕이 지급되었습니다."),
        "text_dialog_vote_amount_should_not_zero":
            MessageLookupByLibrary.simpleMessage("투표수량은 0이 될 수 없습니다."),
        "text_draw_image":
            MessageLookupByLibrary.simpleMessage("전체 갤러리 중 이미지 1개 확정 소장"),
        "text_hint_search":
            MessageLookupByLibrary.simpleMessage("아티스트를 검색하세요."),
        "text_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("선택한 아티스트의 집으로 이동합니다."),
        "text_need_recharge":
            MessageLookupByLibrary.simpleMessage("충전이 필요합니다."),
        "text_no_search_result":
            MessageLookupByLibrary.simpleMessage("검색결과가 없어요."),
        "text_purchase_vat_included":
            MessageLookupByLibrary.simpleMessage("*VAT 포함 가격입니다."),
        "text_star_candy": MessageLookupByLibrary.simpleMessage("별사탕"),
        "text_star_candy_with_bonus": m3,
        "text_this_time_vote": MessageLookupByLibrary.simpleMessage("이번 투표"),
        "text_vote_complete": MessageLookupByLibrary.simpleMessage("투표 완료"),
        "text_vote_rank": m4,
        "text_vote_rank_in_reward":
            MessageLookupByLibrary.simpleMessage("랭크 인 리워드"),
        "text_vote_where_is_my_bias":
            MessageLookupByLibrary.simpleMessage("나의 최애는 어디에?"),
        "title_dialog_library_add":
            MessageLookupByLibrary.simpleMessage("새로운 앨범 추가"),
        "title_dialog_success": MessageLookupByLibrary.simpleMessage("성공"),
        "title_select_language": MessageLookupByLibrary.simpleMessage("언어 선택"),
        "toast_max_five_celeb":
            MessageLookupByLibrary.simpleMessage("내 아티스트를 최대 5개까지 추가할 수 있습니다.")
      };
}
