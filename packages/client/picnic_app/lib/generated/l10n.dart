// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `피크닠`
  String get app_name {
    return Intl.message(
      '피크닠',
      name: 'app_name',
      desc: '',
      args: [],
    );
  }

  /// `취소`
  String get button_cancel {
    return Intl.message(
      '취소',
      name: 'button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `완료`
  String get button_complete {
    return Intl.message(
      '완료',
      name: 'button_complete',
      desc: '',
      args: [],
    );
  }

  /// `로그인`
  String get button_login {
    return Intl.message(
      '로그인',
      name: 'button_login',
      desc: '',
      args: [],
    );
  }

  /// `확인`
  String get button_ok {
    return Intl.message(
      '확인',
      name: 'button_ok',
      desc: '',
      args: [],
    );
  }

  /// `저장하기`
  String get button_pic_pic_save {
    return Intl.message(
      '저장하기',
      name: 'button_pic_pic_save',
      desc: '',
      args: [],
    );
  }

  /// `### 유효기간\n\n- 별사탕은 획득일로부터 1년간 유효합니다.\n\n### 별사탕 획득\n\n로그인 : 1일 1회\n- 투표 : 1회당 1개\n구매 별사탕 : 없음 (무제한)\n보너스 별사탕 : 획득한 다음 달 15일에 일괄 소멸\n\n##### 별사탕 사용\n\n소멸일자가 임박한 별사탕부터 사용됩니다.\n유효기간이 동일한 경우, 그 중 획득일자가 빠른 순으로 사용됩니다.`
  String get candy_usage_policy_contents {
    return Intl.message(
      '### 유효기간\n\n- 별사탕은 획득일로부터 1년간 유효합니다.\n\n### 별사탕 획득\n\n로그인 : 1일 1회\n- 투표 : 1회당 1개\n구매 별사탕 : 없음 (무제한)\n보너스 별사탕 : 획득한 다음 달 15일에 일괄 소멸\n\n##### 별사탕 사용\n\n소멸일자가 임박한 별사탕부터 사용됩니다.\n유효기간이 동일한 경우, 그 중 획득일자가 빠른 순으로 사용됩니다.',
      name: 'candy_usage_policy_contents',
      desc: '',
      args: [],
    );
  }

  /// `*보너스는 획득한 다음달에 사라져요! ⓘ`
  String get candy_usage_policy_guide {
    return Intl.message(
      '*보너스는 획득한 다음달에 사라져요! ⓘ',
      name: 'candy_usage_policy_guide',
      desc: '',
      args: [],
    );
  }

  /// `별사탕 사용정책`
  String get candy_usage_policy_title {
    return Intl.message(
      '별사탕 사용정책',
      name: 'candy_usage_policy_title',
      desc: '',
      args: [],
    );
  }

  /// `취소`
  String get dialog_button_cancel {
    return Intl.message(
      '취소',
      name: 'dialog_button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `확인`
  String get dialog_button_ok {
    return Intl.message(
      '확인',
      name: 'dialog_button_ok',
      desc: '',
      args: [],
    );
  }

  /// `광고 로딩중입니다.`
  String get dialog_content_ads_loading {
    return Intl.message(
      '광고 로딩중입니다.',
      name: 'dialog_content_ads_loading',
      desc: '',
      args: [],
    );
  }

  /// `로그인이 필요합니다`
  String get dialog_content_login_required {
    return Intl.message(
      '로그인이 필요합니다',
      name: 'dialog_content_login_required',
      desc: '',
      args: [],
    );
  }

  /// `투표 실패`
  String get dialog_title_vote_fail {
    return Intl.message(
      '투표 실패',
      name: 'dialog_title_vote_fail',
      desc: '',
      args: [],
    );
  }

  /// `다시 한 번 생각해 볼께요`
  String get dialog_withdraw_button_cancel {
    return Intl.message(
      '다시 한 번 생각해 볼께요',
      name: 'dialog_withdraw_button_cancel',
      desc: '',
      args: [],
    );
  }

  /// `탈퇴하기`
  String get dialog_withdraw_button_ok {
    return Intl.message(
      '탈퇴하기',
      name: 'dialog_withdraw_button_ok',
      desc: '',
      args: [],
    );
  }

  /// `탈퇴중 에러가 발생했습니다.`
  String get dialog_withdraw_error {
    return Intl.message(
      '탈퇴중 에러가 발생했습니다.',
      name: 'dialog_withdraw_error',
      desc: '',
      args: [],
    );
  }

  /// `회원 탈퇴 시 피크닠에 보유하고 계신 별사탕과 계정정보는 즉시 삭제됩니다.`
  String get dialog_withdraw_message {
    return Intl.message(
      '회원 탈퇴 시 피크닠에 보유하고 계신 별사탕과 계정정보는 즉시 삭제됩니다.',
      name: 'dialog_withdraw_message',
      desc: '',
      args: [],
    );
  }

  /// `탈퇴가 성공적으로 처리 되었습니다.`
  String get dialog_withdraw_success {
    return Intl.message(
      '탈퇴가 성공적으로 처리 되었습니다.',
      name: 'dialog_withdraw_success',
      desc: '',
      args: [],
    );
  }

  /// `정말 탈퇴하시겠어요?`
  String get dialog_withdraw_title {
    return Intl.message(
      '정말 탈퇴하시겠어요?',
      name: 'dialog_withdraw_title',
      desc: '',
      args: [],
    );
  }

  /// `회원 정보가 존재하지 않습니다.`
  String get error_message_no_user {
    return Intl.message(
      '회원 정보가 존재하지 않습니다.',
      name: 'error_message_no_user',
      desc: '',
      args: [],
    );
  }

  /// `탈퇴한 회원입니다.`
  String get error_message_withdrawal {
    return Intl.message(
      '탈퇴한 회원입니다.',
      name: 'error_message_withdrawal',
      desc: '',
      args: [],
    );
  }

  /// `앨범명`
  String get hint_library_add {
    return Intl.message(
      '앨범명',
      name: 'hint_library_add',
      desc: '',
      args: [],
    );
  }

  /// `닉네임을 입력해주세요.`
  String get hint_nickname_input {
    return Intl.message(
      '닉네임을 입력해주세요.',
      name: 'hint_nickname_input',
      desc: '',
      args: [],
    );
  }

  /// `이미지가 저장되었습니다.`
  String get image_save_success {
    return Intl.message(
      '이미지가 저장되었습니다.',
      name: 'image_save_success',
      desc: '',
      args: [],
    );
  }

  /// `개인정보 수집 및 이용 동의`
  String get label_agreement_privacy {
    return Intl.message(
      '개인정보 수집 및 이용 동의',
      name: 'label_agreement_privacy',
      desc: '',
      args: [],
    );
  }

  /// `이용 약관 동의`
  String get label_agreement_terms {
    return Intl.message(
      '이용 약관 동의',
      name: 'label_agreement_terms',
      desc: '',
      args: [],
    );
  }

  /// `새로운 앨범 추가`
  String get label_album_add {
    return Intl.message(
      '새로운 앨범 추가',
      name: 'label_album_add',
      desc: '',
      args: [],
    );
  }

  /// `첫 댓글의 주인공이 되세요!`
  String get label_article_comment_empty {
    return Intl.message(
      '첫 댓글의 주인공이 되세요!',
      name: 'label_article_comment_empty',
      desc: '',
      args: [],
    );
  }

  /// `보너스`
  String get label_bonus {
    return Intl.message(
      '보너스',
      name: 'label_bonus',
      desc: '',
      args: [],
    );
  }

  /// `동의`
  String get label_button_agreement {
    return Intl.message(
      '동의',
      name: 'label_button_agreement',
      desc: '',
      args: [],
    );
  }

  /// `닫기`
  String get label_button_clse {
    return Intl.message(
      '닫기',
      name: 'label_button_clse',
      desc: '',
      args: [],
    );
  }

  /// `비동의`
  String get label_button_disagreement {
    return Intl.message(
      '비동의',
      name: 'label_button_disagreement',
      desc: '',
      args: [],
    );
  }

  /// `충전하기`
  String get label_button_recharge {
    return Intl.message(
      '충전하기',
      name: 'label_button_recharge',
      desc: '',
      args: [],
    );
  }

  /// `투표증 저장`
  String get label_button_save_vote_paper {
    return Intl.message(
      '투표증 저장',
      name: 'label_button_save_vote_paper',
      desc: '',
      args: [],
    );
  }

  /// `공유하기`
  String get label_button_share {
    return Intl.message(
      '공유하기',
      name: 'label_button_share',
      desc: '',
      args: [],
    );
  }

  /// `투표하기`
  String get label_button_vote {
    return Intl.message(
      '투표하기',
      name: 'label_button_vote',
      desc: '',
      args: [],
    );
  }

  /// `광고보고 충전하기`
  String get label_button_watch_and_charge {
    return Intl.message(
      '광고보고 충전하기',
      name: 'label_button_watch_and_charge',
      desc: '',
      args: [],
    );
  }

  /// `아티스트가 당신에게 묻다!`
  String get label_celeb_ask_to_you {
    return Intl.message(
      '아티스트가 당신에게 묻다!',
      name: 'label_celeb_ask_to_you',
      desc: '',
      args: [],
    );
  }

  /// `아티스트 갤러리`
  String get label_celeb_gallery {
    return Intl.message(
      '아티스트 갤러리',
      name: 'label_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `아티스트 추천`
  String get label_celeb_recommend {
    return Intl.message(
      '아티스트 추천',
      name: 'label_celeb_recommend',
      desc: '',
      args: [],
    );
  }

  /// `전체사용`
  String get label_checkbox_entire_use {
    return Intl.message(
      '전체사용',
      name: 'label_checkbox_entire_use',
      desc: '',
      args: [],
    );
  }

  /// `현재 언어`
  String get label_current_language {
    return Intl.message(
      '현재 언어',
      name: 'label_current_language',
      desc: '',
      args: [],
    );
  }

  /// `랜덤 이미지 획득 기회`
  String get label_draw_image {
    return Intl.message(
      '랜덤 이미지 획득 기회',
      name: 'label_draw_image',
      desc: '',
      args: [],
    );
  }

  /// `오래된순`
  String get label_dropdown_oldest {
    return Intl.message(
      '오래된순',
      name: 'label_dropdown_oldest',
      desc: '',
      args: [],
    );
  }

  /// `최신순`
  String get label_dropdown_recent {
    return Intl.message(
      '최신순',
      name: 'label_dropdown_recent',
      desc: '',
      args: [],
    );
  }

  /// `더 많은 아티스트 찾기`
  String get label_find_celeb {
    return Intl.message(
      '더 많은 아티스트 찾기',
      name: 'label_find_celeb',
      desc: '',
      args: [],
    );
  }

  /// `아티클`
  String get label_gallery_tab_article {
    return Intl.message(
      '아티클',
      name: 'label_gallery_tab_article',
      desc: '',
      args: [],
    );
  }

  /// `채팅`
  String get label_gallery_tab_chat {
    return Intl.message(
      '채팅',
      name: 'label_gallery_tab_chat',
      desc: '',
      args: [],
    );
  }

  /// `댓글을 남겨주세요.`
  String get label_hint_comment {
    return Intl.message(
      '댓글을 남겨주세요.',
      name: 'label_hint_comment',
      desc: '',
      args: [],
    );
  }

  /// `입력`
  String get label_input_input {
    return Intl.message(
      '입력',
      name: 'label_input_input',
      desc: '',
      args: [],
    );
  }

  /// `라이브러리 저장`
  String get label_library_save {
    return Intl.message(
      '라이브러리 저장',
      name: 'label_library_save',
      desc: '',
      args: [],
    );
  }

  /// `AI 포토`
  String get label_library_tab_ai_photo {
    return Intl.message(
      'AI 포토',
      name: 'label_library_tab_ai_photo',
      desc: '',
      args: [],
    );
  }

  /// `라이브러리`
  String get label_library_tab_library {
    return Intl.message(
      '라이브러리',
      name: 'label_library_tab_library',
      desc: '',
      args: [],
    );
  }

  /// `PIC`
  String get label_library_tab_pic {
    return Intl.message(
      'PIC',
      name: 'label_library_tab_pic',
      desc: '',
      args: [],
    );
  }

  /// `아티스트 갤러리로 이동`
  String get label_moveto_celeb_gallery {
    return Intl.message(
      '아티스트 갤러리로 이동',
      name: 'label_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `충전내역`
  String get label_mypage_charge_history {
    return Intl.message(
      '충전내역',
      name: 'label_mypage_charge_history',
      desc: '',
      args: [],
    );
  }

  /// `고객센터`
  String get label_mypage_customer_center {
    return Intl.message(
      '고객센터',
      name: 'label_mypage_customer_center',
      desc: '',
      args: [],
    );
  }

  /// `로그아웃`
  String get label_mypage_logout {
    return Intl.message(
      '로그아웃',
      name: 'label_mypage_logout',
      desc: '',
      args: [],
    );
  }

  /// `멤버십 내역`
  String get label_mypage_membership_history {
    return Intl.message(
      '멤버십 내역',
      name: 'label_mypage_membership_history',
      desc: '',
      args: [],
    );
  }

  /// `마이 스타`
  String get label_mypage_mystar {
    return Intl.message(
      '마이 스타',
      name: 'label_mypage_mystar',
      desc: '',
      args: [],
    );
  }

  /// `공지사항`
  String get label_mypage_notice {
    return Intl.message(
      '공지사항',
      name: 'label_mypage_notice',
      desc: '',
      args: [],
    );
  }

  /// `개인정보처리방침`
  String get label_mypage_privacy_policy {
    return Intl.message(
      '개인정보처리방침',
      name: 'label_mypage_privacy_policy',
      desc: '',
      args: [],
    );
  }

  /// `설정`
  String get label_mypage_setting {
    return Intl.message(
      '설정',
      name: 'label_mypage_setting',
      desc: '',
      args: [],
    );
  }

  /// `이용약관`
  String get label_mypage_terms_of_use {
    return Intl.message(
      '이용약관',
      name: 'label_mypage_terms_of_use',
      desc: '',
      args: [],
    );
  }

  /// `투표내역`
  String get label_mypage_vote_history {
    return Intl.message(
      '투표내역',
      name: 'label_mypage_vote_history',
      desc: '',
      args: [],
    );
  }

  /// `회원탈퇴`
  String get label_mypage_withdrawal {
    return Intl.message(
      '회원탈퇴',
      name: 'label_mypage_withdrawal',
      desc: '',
      args: [],
    );
  }

  /// `아직 북마크한 아티스트가 없습니다!`
  String get label_no_celeb {
    return Intl.message(
      '아직 북마크한 아티스트가 없습니다!',
      name: 'label_no_celeb',
      desc: '',
      args: [],
    );
  }

  /// `이미지 자르기`
  String get label_pic_image_cropping {
    return Intl.message(
      '이미지 자르기',
      name: 'label_pic_image_cropping',
      desc: '',
      args: [],
    );
  }

  /// `카메라 초기화중...`
  String get label_pic_pic_initializing_camera {
    return Intl.message(
      '카메라 초기화중...',
      name: 'label_pic_pic_initializing_camera',
      desc: '',
      args: [],
    );
  }

  /// `갤러리에 저장`
  String get label_pic_pic_save_gallery {
    return Intl.message(
      '갤러리에 저장',
      name: 'label_pic_pic_save_gallery',
      desc: '',
      args: [],
    );
  }

  /// `이미지 합성중...`
  String get label_pic_pic_synthesizing_image {
    return Intl.message(
      '이미지 합성중...',
      name: 'label_pic_pic_synthesizing_image',
      desc: '',
      args: [],
    );
  }

  /// `댓글 더보기`
  String get label_read_more_comment {
    return Intl.message(
      '댓글 더보기',
      name: 'label_read_more_comment',
      desc: '',
      args: [],
    );
  }

  /// `답글 달기`
  String get label_reply {
    return Intl.message(
      '답글 달기',
      name: 'label_reply',
      desc: '',
      args: [],
    );
  }

  /// `재시도 하기`
  String get label_retry {
    return Intl.message(
      '재시도 하기',
      name: 'label_retry',
      desc: '',
      args: [],
    );
  }

  /// `약관 동의`
  String get label_screen_title_agreement {
    return Intl.message(
      '약관 동의',
      name: 'label_screen_title_agreement',
      desc: '',
      args: [],
    );
  }

  /// `알림`
  String get label_setting_alarm {
    return Intl.message(
      '알림',
      name: 'label_setting_alarm',
      desc: '',
      args: [],
    );
  }

  /// `앱정보`
  String get label_setting_appinfo {
    return Intl.message(
      '앱정보',
      name: 'label_setting_appinfo',
      desc: '',
      args: [],
    );
  }

  /// `현재버전`
  String get label_setting_current_version {
    return Intl.message(
      '현재버전',
      name: 'label_setting_current_version',
      desc: '',
      args: [],
    );
  }

  /// `이벤트알림`
  String get label_setting_event_alarm {
    return Intl.message(
      '이벤트알림',
      name: 'label_setting_event_alarm',
      desc: '',
      args: [],
    );
  }

  /// `각종 이벤트와 행사를 안내드려요.`
  String get label_setting_event_alarm_desc {
    return Intl.message(
      '각종 이벤트와 행사를 안내드려요.',
      name: 'label_setting_event_alarm_desc',
      desc: '',
      args: [],
    );
  }

  /// `언어설정`
  String get label_setting_language {
    return Intl.message(
      '언어설정',
      name: 'label_setting_language',
      desc: '',
      args: [],
    );
  }

  /// `푸시알림`
  String get label_setting_push_alarm {
    return Intl.message(
      '푸시알림',
      name: 'label_setting_push_alarm',
      desc: '',
      args: [],
    );
  }

  /// `최신버전`
  String get label_setting_recent_version {
    return Intl.message(
      '최신버전',
      name: 'label_setting_recent_version',
      desc: '',
      args: [],
    );
  }

  /// `캐시삭제`
  String get label_setting_remove_cache {
    return Intl.message(
      '캐시삭제',
      name: 'label_setting_remove_cache',
      desc: '',
      args: [],
    );
  }

  /// `저장공간 관리`
  String get label_setting_storage {
    return Intl.message(
      '저장공간 관리',
      name: 'label_setting_storage',
      desc: '',
      args: [],
    );
  }

  /// `업데이트`
  String get label_setting_update {
    return Intl.message(
      '업데이트',
      name: 'label_setting_update',
      desc: '',
      args: [],
    );
  }

  /// `별사탕 주머니`
  String get label_star_candy_pouch {
    return Intl.message(
      '별사탕 주머니',
      name: 'label_star_candy_pouch',
      desc: '',
      args: [],
    );
  }

  /// `별사탕 구매`
  String get label_tab_buy_star_candy {
    return Intl.message(
      '별사탕 구매',
      name: 'label_tab_buy_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `무료충전소`
  String get label_tab_free_charge_station {
    return Intl.message(
      '무료충전소',
      name: 'label_tab_free_charge_station',
      desc: '',
      args: [],
    );
  }

  /// `일간차트`
  String get label_tabbar_picchart_daily {
    return Intl.message(
      '일간차트',
      name: 'label_tabbar_picchart_daily',
      desc: '',
      args: [],
    );
  }

  /// `월간차트`
  String get label_tabbar_picchart_monthly {
    return Intl.message(
      '월간차트',
      name: 'label_tabbar_picchart_monthly',
      desc: '',
      args: [],
    );
  }

  /// `주간차트`
  String get label_tabbar_picchart_weekly {
    return Intl.message(
      '주간차트',
      name: 'label_tabbar_picchart_weekly',
      desc: '',
      args: [],
    );
  }

  /// `진행중`
  String get label_tabbar_vote_active {
    return Intl.message(
      '진행중',
      name: 'label_tabbar_vote_active',
      desc: '',
      args: [],
    );
  }

  /// `종료`
  String get label_tabbar_vote_end {
    return Intl.message(
      '종료',
      name: 'label_tabbar_vote_end',
      desc: '',
      args: [],
    );
  }

  /// `{day}일 전`
  String label_time_ago_day(Object day) {
    return Intl.message(
      '$day일 전',
      name: 'label_time_ago_day',
      desc: '',
      args: [day],
    );
  }

  /// `{hour}시간 전`
  String label_time_ago_hour(Object hour) {
    return Intl.message(
      '$hour시간 전',
      name: 'label_time_ago_hour',
      desc: '',
      args: [hour],
    );
  }

  /// `{minute}분 전`
  String label_time_ago_minute(Object minute) {
    return Intl.message(
      '$minute분 전',
      name: 'label_time_ago_minute',
      desc: '',
      args: [minute],
    );
  }

  /// `방금 전`
  String get label_time_ago_right_now {
    return Intl.message(
      '방금 전',
      name: 'label_time_ago_right_now',
      desc: '',
      args: [],
    );
  }

  /// `댓글`
  String get label_title_comment {
    return Intl.message(
      '댓글',
      name: 'label_title_comment',
      desc: '',
      args: [],
    );
  }

  /// `신고하기`
  String get label_title_report {
    return Intl.message(
      '신고하기',
      name: 'label_title_report',
      desc: '',
      args: [],
    );
  }

  /// `리워드 리스트`
  String get label_vote_reward_list {
    return Intl.message(
      '리워드 리스트',
      name: 'label_vote_reward_list',
      desc: '',
      args: [],
    );
  }

  /// `투표`
  String get label_vote_screen_title {
    return Intl.message(
      '투표',
      name: 'label_vote_screen_title',
      desc: '',
      args: [],
    );
  }

  /// `생일 투표`
  String get label_vote_tab_birthday {
    return Intl.message(
      '생일 투표',
      name: 'label_vote_tab_birthday',
      desc: '',
      args: [],
    );
  }

  /// `PIC 투표`
  String get label_vote_tab_pic {
    return Intl.message(
      'PIC 투표',
      name: 'label_vote_tab_pic',
      desc: '',
      args: [],
    );
  }

  /// `투표 모아보기`
  String get label_vote_vote_gather {
    return Intl.message(
      '투표 모아보기',
      name: 'label_vote_vote_gather',
      desc: '',
      args: [],
    );
  }

  /// `광고보기`
  String get label_watch_ads {
    return Intl.message(
      '광고보기',
      name: 'label_watch_ads',
      desc: '',
      args: [],
    );
  }

  /// `나의 아티스트`
  String get lable_my_celeb {
    return Intl.message(
      '나의 아티스트',
      name: 'lable_my_celeb',
      desc: '',
      args: [],
    );
  }

  /// `약관 동의가 완료되었습니다.`
  String get message_agreement_success {
    return Intl.message(
      '약관 동의가 완료되었습니다.',
      name: 'message_agreement_success',
      desc: '',
      args: [],
    );
  }

  /// `오류가 발생했습니다.`
  String get message_error_occurred {
    return Intl.message(
      '오류가 발생했습니다.',
      name: 'message_error_occurred',
      desc: '',
      args: [],
    );
  }

  /// `이미지 저장에 실패했습니다.`
  String get message_pic_pic_save_fail {
    return Intl.message(
      '이미지 저장에 실패했습니다.',
      name: 'message_pic_pic_save_fail',
      desc: '',
      args: [],
    );
  }

  /// `이미지가 저장되었습니다.`
  String get message_pic_pic_save_success {
    return Intl.message(
      '이미지가 저장되었습니다.',
      name: 'message_pic_pic_save_success',
      desc: '',
      args: [],
    );
  }

  /// `신고하시겠습니까?`
  String get message_report_confirm {
    return Intl.message(
      '신고하시겠습니까?',
      name: 'message_report_confirm',
      desc: '',
      args: [],
    );
  }

  /// `신고가 완료되었습니다.`
  String get message_report_ok {
    return Intl.message(
      '신고가 완료되었습니다.',
      name: 'message_report_ok',
      desc: '',
      args: [],
    );
  }

  /// `댓글관리`
  String get mypage_comment {
    return Intl.message(
      '댓글관리',
      name: 'mypage_comment',
      desc: '',
      args: [],
    );
  }

  /// `언어설정`
  String get mypage_language {
    return Intl.message(
      '언어설정',
      name: 'mypage_language',
      desc: '',
      args: [],
    );
  }

  /// `내 구매`
  String get mypage_purchases {
    return Intl.message(
      '내 구매',
      name: 'mypage_purchases',
      desc: '',
      args: [],
    );
  }

  /// `설정`
  String get mypage_setting {
    return Intl.message(
      '설정',
      name: 'mypage_setting',
      desc: '',
      args: [],
    );
  }

  /// `구독정보`
  String get mypage_subscription {
    return Intl.message(
      '구독정보',
      name: 'mypage_subscription',
      desc: '',
      args: [],
    );
  }

  /// `광고`
  String get nav_ads {
    return Intl.message(
      '광고',
      name: 'nav_ads',
      desc: '',
      args: [],
    );
  }

  /// `갤러리`
  String get nav_gallery {
    return Intl.message(
      '갤러리',
      name: 'nav_gallery',
      desc: '',
      args: [],
    );
  }

  /// `홈`
  String get nav_home {
    return Intl.message(
      '홈',
      name: 'nav_home',
      desc: '',
      args: [],
    );
  }

  /// `라이브러리`
  String get nav_library {
    return Intl.message(
      '라이브러리',
      name: 'nav_library',
      desc: '',
      args: [],
    );
  }

  /// `미디어`
  String get nav_media {
    return Intl.message(
      '미디어',
      name: 'nav_media',
      desc: '',
      args: [],
    );
  }

  /// `PIC차트`
  String get nav_picchart {
    return Intl.message(
      'PIC차트',
      name: 'nav_picchart',
      desc: '',
      args: [],
    );
  }

  /// `구매`
  String get nav_purchases {
    return Intl.message(
      '구매',
      name: 'nav_purchases',
      desc: '',
      args: [],
    );
  }

  /// `설정`
  String get nav_setting {
    return Intl.message(
      '설정',
      name: 'nav_setting',
      desc: '',
      args: [],
    );
  }

  /// `상점`
  String get nav_store {
    return Intl.message(
      '상점',
      name: 'nav_store',
      desc: '',
      args: [],
    );
  }

  /// `구독`
  String get nav_subscription {
    return Intl.message(
      '구독',
      name: 'nav_subscription',
      desc: '',
      args: [],
    );
  }

  /// `투표`
  String get nav_vote {
    return Intl.message(
      '투표',
      name: 'nav_vote',
      desc: '',
      args: [],
    );
  }

  /// `20자 이내, 특수문자 제외 가능합니다.`
  String get nickname_validation_error {
    return Intl.message(
      '20자 이내, 특수문자 제외 가능합니다.',
      name: 'nickname_validation_error',
      desc: '',
      args: [],
    );
  }

  /// `마이페이지`
  String get page_title_mypage {
    return Intl.message(
      '마이페이지',
      name: 'page_title_mypage',
      desc: '',
      args: [],
    );
  }

  /// `나의 프로필`
  String get page_title_myprofile {
    return Intl.message(
      '나의 프로필',
      name: 'page_title_myprofile',
      desc: '',
      args: [],
    );
  }

  /// `개인정보처리방침`
  String get page_title_privacy {
    return Intl.message(
      '개인정보처리방침',
      name: 'page_title_privacy',
      desc: '',
      args: [],
    );
  }

  /// `환경설정`
  String get page_title_setting {
    return Intl.message(
      '환경설정',
      name: 'page_title_setting',
      desc: '',
      args: [],
    );
  }

  /// `이용약관`
  String get page_title_terms_of_use {
    return Intl.message(
      '이용약관',
      name: 'page_title_terms_of_use',
      desc: '',
      args: [],
    );
  }

  /// `투표하기`
  String get page_title_vote_detail {
    return Intl.message(
      '투표하기',
      name: 'page_title_vote_detail',
      desc: '',
      args: [],
    );
  }

  /// `투표 모아보기`
  String get page_title_vote_gather {
    return Intl.message(
      '투표 모아보기',
      name: 'page_title_vote_gather',
      desc: '',
      args: [],
    );
  }

  /// `이미지 공유 실패`
  String get share_image_fail {
    return Intl.message(
      '이미지 공유 실패',
      name: 'share_image_fail',
      desc: '',
      args: [],
    );
  }

  /// `이미지 공유 성공`
  String get share_image_success {
    return Intl.message(
      '이미지 공유 성공',
      name: 'share_image_success',
      desc: '',
      args: [],
    );
  }

  /// `트위터 앱이 없습니다`
  String get share_no_twitter {
    return Intl.message(
      '트위터 앱이 없습니다',
      name: 'share_no_twitter',
      desc: '',
      args: [],
    );
  }

  /// `트위터 공유`
  String get share_twitter {
    return Intl.message(
      '트위터 공유',
      name: 'share_twitter',
      desc: '',
      args: [],
    );
  }

  /// `광고 보기 및 무작위 이미지 수집.`
  String get text_ads_random {
    return Intl.message(
      '광고 보기 및 무작위 이미지 수집.',
      name: 'text_ads_random',
      desc: '',
      args: [],
    );
  }

  /// `보너스`
  String get text_bonus {
    return Intl.message(
      '보너스',
      name: 'text_bonus',
      desc: '',
      args: [],
    );
  }

  /// `핔 차트에 오신 여러분을 환영합니다!\n2024년 8월에 만나요!`
  String get text_comming_soon_pic_chart1 {
    return Intl.message(
      '핔 차트에 오신 여러분을 환영합니다!\n2024년 8월에 만나요!',
      name: 'text_comming_soon_pic_chart1',
      desc: '',
      args: [],
    );
  }

  /// `핔차트는 일간, 주간, 월간 점수를 반영하는\n피크닠만의 새로운 차트입니다.`
  String get text_comming_soon_pic_chart2 {
    return Intl.message(
      '핔차트는 일간, 주간, 월간 점수를 반영하는\n피크닠만의 새로운 차트입니다.',
      name: 'text_comming_soon_pic_chart2',
      desc: '',
      args: [],
    );
  }

  /// `실시간으로 반영되는\n아티스트의 브랜드 평판을 확인해 보세요!`
  String get text_comming_soon_pic_chart3 {
    return Intl.message(
      '실시간으로 반영되는\n아티스트의 브랜드 평판을 확인해 보세요!',
      name: 'text_comming_soon_pic_chart3',
      desc: '',
      args: [],
    );
  }

  /// `핔차트란?`
  String get text_comming_soon_pic_chart_title {
    return Intl.message(
      '핔차트란?',
      name: 'text_comming_soon_pic_chart_title',
      desc: '',
      args: [],
    );
  }

  /// `주소가 복사되었습니다.`
  String get text_copied_address {
    return Intl.message(
      '주소가 복사되었습니다.',
      name: 'text_copied_address',
      desc: '',
      args: [],
    );
  }

  /// `별사탕이 지급되었습니다.`
  String get text_dialog_star_candy_received {
    return Intl.message(
      '별사탕이 지급되었습니다.',
      name: 'text_dialog_star_candy_received',
      desc: '',
      args: [],
    );
  }

  /// `투표수량은 0이 될 수 없습니다.`
  String get text_dialog_vote_amount_should_not_zero {
    return Intl.message(
      '투표수량은 0이 될 수 없습니다.',
      name: 'text_dialog_vote_amount_should_not_zero',
      desc: '',
      args: [],
    );
  }

  /// `전체 갤러리 중 이미지 1개 확정 소장`
  String get text_draw_image {
    return Intl.message(
      '전체 갤러리 중 이미지 1개 확정 소장',
      name: 'text_draw_image',
      desc: '',
      args: [],
    );
  }

  /// `아티스트를 검색하세요.`
  String get text_hint_search {
    return Intl.message(
      '아티스트를 검색하세요.',
      name: 'text_hint_search',
      desc: '',
      args: [],
    );
  }

  /// `선택한 아티스트의 집으로 이동합니다.`
  String get text_moveto_celeb_gallery {
    return Intl.message(
      '선택한 아티스트의 집으로 이동합니다.',
      name: 'text_moveto_celeb_gallery',
      desc: '',
      args: [],
    );
  }

  /// `충전이 필요합니다.`
  String get text_need_recharge {
    return Intl.message(
      '충전이 필요합니다.',
      name: 'text_need_recharge',
      desc: '',
      args: [],
    );
  }

  /// `검색결과가 없어요.`
  String get text_no_search_result {
    return Intl.message(
      '검색결과가 없어요.',
      name: 'text_no_search_result',
      desc: '',
      args: [],
    );
  }

  /// `*VAT 포함 가격입니다.`
  String get text_purchase_vat_included {
    return Intl.message(
      '*VAT 포함 가격입니다.',
      name: 'text_purchase_vat_included',
      desc: '',
      args: [],
    );
  }

  /// `별사탕`
  String get text_star_candy {
    return Intl.message(
      '별사탕',
      name: 'text_star_candy',
      desc: '',
      args: [],
    );
  }

  /// `{num1}개 +{num1}개 보너스`
  String text_star_candy_with_bonus(Object num1) {
    return Intl.message(
      '$num1개 +$num1개 보너스',
      name: 'text_star_candy_with_bonus',
      desc: '',
      args: [num1],
    );
  }

  /// `이번 투표`
  String get text_this_time_vote {
    return Intl.message(
      '이번 투표',
      name: 'text_this_time_vote',
      desc: '',
      args: [],
    );
  }

  /// `투표 완료`
  String get text_vote_complete {
    return Intl.message(
      '투표 완료',
      name: 'text_vote_complete',
      desc: '',
      args: [],
    );
  }

  /// `{rank}위`
  String text_vote_rank(Object rank) {
    return Intl.message(
      '$rank위',
      name: 'text_vote_rank',
      desc: '',
      args: [rank],
    );
  }

  /// `랭크 인 리워드`
  String get text_vote_rank_in_reward {
    return Intl.message(
      '랭크 인 리워드',
      name: 'text_vote_rank_in_reward',
      desc: '',
      args: [],
    );
  }

  /// `나의 최애는 어디에?`
  String get text_vote_where_is_my_bias {
    return Intl.message(
      '나의 최애는 어디에?',
      name: 'text_vote_where_is_my_bias',
      desc: '',
      args: [],
    );
  }

  /// `새로운 앨범 추가`
  String get title_dialog_library_add {
    return Intl.message(
      '새로운 앨범 추가',
      name: 'title_dialog_library_add',
      desc: '',
      args: [],
    );
  }

  /// `성공`
  String get title_dialog_success {
    return Intl.message(
      '성공',
      name: 'title_dialog_success',
      desc: '',
      args: [],
    );
  }

  /// `언어 선택`
  String get title_select_language {
    return Intl.message(
      '언어 선택',
      name: 'title_select_language',
      desc: '',
      args: [],
    );
  }

  /// `내 아티스트를 최대 5개까지 추가할 수 있습니다.`
  String get toast_max_five_celeb {
    return Intl.message(
      '내 아티스트를 최대 5개까지 추가할 수 있습니다.',
      name: 'toast_max_five_celeb',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
