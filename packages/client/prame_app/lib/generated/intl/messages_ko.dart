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

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "button_cancel": MessageLookupByLibrary.simpleMessage("취소"),
        "button_ok": MessageLookupByLibrary.simpleMessage("확인"),
        "label_celeb_gallery": MessageLookupByLibrary.simpleMessage("샐럽 갤러리"),
        "label_celeb_recommend": MessageLookupByLibrary.simpleMessage("유명인 추천"),
        "label_current_language": MessageLookupByLibrary.simpleMessage("현재 언어"),
        "label_draw_image":
            MessageLookupByLibrary.simpleMessage("랜덤 이미지 획득 기회"),
        "label_find_celeb": MessageLookupByLibrary.simpleMessage("더 많은 유명인 찾기"),
        "label_gallery_tab_chat": MessageLookupByLibrary.simpleMessage("채팅"),
        "label_gallery_tab_gallery":
            MessageLookupByLibrary.simpleMessage("갤러리"),
        "label_hint_comment":
            MessageLookupByLibrary.simpleMessage("댓글을 남겨주세요."),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("셀러브리티 갤러리로 이동"),
        "label_no_celeb":
            MessageLookupByLibrary.simpleMessage("아직 북마크한 유명인이 없습니다!"),
        "label_read_more_comment":
            MessageLookupByLibrary.simpleMessage("댓글 더보기"),
        "label_reply": MessageLookupByLibrary.simpleMessage("답글 달기"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now":
            MessageLookupByLibrary.simpleMessage("방금 전"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("댓글"),
        "label_title_report": MessageLookupByLibrary.simpleMessage("신고하기"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("내 셀럽"),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("신고하시겠습니까?"),
        "message_report_ok":
            MessageLookupByLibrary.simpleMessage("신고가 완료되었습니다."),
        "mypage_comment": MessageLookupByLibrary.simpleMessage("댓글관리"),
        "mypage_language": MessageLookupByLibrary.simpleMessage("언어설정"),
        "mypage_purchases": MessageLookupByLibrary.simpleMessage("내 구매"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("설정"),
        "mypage_subscription": MessageLookupByLibrary.simpleMessage("구독정보"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("광고"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("갤러리"),
        "nav_home": MessageLookupByLibrary.simpleMessage("홈"),
        "nav_library": MessageLookupByLibrary.simpleMessage("라이브러리"),
        "nav_purchases": MessageLookupByLibrary.simpleMessage("구매"),
        "text_ads_random":
            MessageLookupByLibrary.simpleMessage("광고 보기 및 무작위 이미지 수집."),
        "text_draw_image":
            MessageLookupByLibrary.simpleMessage("전체 갤러리 중 이미지 1개 확정 소장"),
        "text_hint_search": MessageLookupByLibrary.simpleMessage("유명인을 검색하세요."),
        "text_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("선택한 셀러브리티의 집으로 이동합니다."),
        "title_select_language": MessageLookupByLibrary.simpleMessage("언어 선택"),
        "toast_max_5_celeb":
            MessageLookupByLibrary.simpleMessage("내 셀러브리티를 최대 5개까지 추가할 수 있습니다.")
      };
}
