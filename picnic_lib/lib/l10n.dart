// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 전역 변수 추가
bool _isSettingLanguage = false;

/// 로컬라이제이션 설정 클래스 (Crowdin 제거, 로컬 번역만 사용)
class PicnicLibL10n {
  static bool _isInitialized = false;
  static Setting? _currentSetting;
  static String _currentLanguage = 'ko'; // 기본 언어

  /// 지원되는 로케일 목록 (언어 코드만 사용)
  static const List<Locale> supportedLocales = [
    Locale('en'), // 영어
    Locale('en', 'US'), // 미국 영어
    Locale('ja'), // 일본어
    Locale('ja', 'JP'), // 일본어 (일본)
    Locale('ko'), // 한국어
    Locale('ko', 'KR'), // 한국어 (한국)
    Locale('zh'), // 중국어
    Locale('zh', 'CN'), // 중국어 (중국)
    Locale('id'), // 인도네시아어
    Locale('id', 'ID'), // 인도네시아어 (인도네시아)
  ];

  /// 기본 로케일
  static const Locale defaultLocale = Locale('en');

  /// 현재 로케일 설정
  static void setCurrentLocale(String languageCode) {
    if (!_isInitialized || _isSettingLanguage) {
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았거나 이미 언어 설정 중입니다.');
      return;
    }

    _isSettingLanguage = true;

    try {
      logger.i('언어 변경 시작 (PicnicLibL10n): $languageCode');
      _currentLanguage = languageCode;
    } finally {
      _isSettingLanguage = false;
    }
  }

  /// 현재 로케일 가져오기
  static Locale getCurrentLocale() {
    if (!_isInitialized) {
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았습니다. 기본 로케일(en) 사용');
      return const Locale('en');
    }
    return Locale(_getLanguage());
  }

  /// 현재 언어 코드 가져오기
  static String _getLanguage() {
    try {
      // _currentSetting이 있으면 사용, 없으면 _currentLanguage 사용
      if (_currentSetting != null) {
        return _currentSetting!.language;
      }
      return _currentLanguage;
    } catch (e) {
      logger.e('언어 코드 가져오기 실패', error: e);
      return 'en';
    }
  }

  /// 로컬라이제이션 델리게이트 목록
  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates {
    return [
      _PicnicLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
  }

  /// 로컬 번역 시스템 초기화 (Crowdin 제거)
  static Future<void> initialize(Setting appSetting,
      [ProviderContainer? container]) async {
    try {
      logger.i('PicnicLibL10n 로컬 번역 시스템 초기화 시작');

      // 앱 설정 객체 저장
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';

      // 로컬 번역만 사용하므로 바로 초기화 완료
      _isInitialized = true;
      logger.i('PicnicLibL10n 로컬 번역 시스템 초기화 완료 (언어: $_currentLanguage)');
    } catch (e, s) {
      logger.e('PicnicLibL10n 초기화 실패', error: e, stackTrace: s);

      // 초기화 실패 시에도 기본 설정으로 작동하도록 함
      _currentSetting = appSetting;
      _currentLanguage =
          appSetting.language.isNotEmpty ? appSetting.language : 'ko';
      _isInitialized = true;

      logger.w('PicnicLibL10n 기본 모드로 초기화됨 (언어: $_currentLanguage)');
    }
  }

  /// 특정 로케일의 번역 로드 (로컬 번역만 사용)
  static Future<void> loadTranslations(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      logger.w('지원되지 않는 로케일: ${locale.languageCode}');
      locale = defaultLocale;
    }

    try {
      final languageCode = locale.languageCode;
      logger.i('로컬 번역 로드 시작: $languageCode');

      // 로컬 번역이므로 즉시 완료
      logger.i('로컬 번역 로드 완료: $languageCode');
    } catch (e, s) {
      logger.e('번역 로드 실패', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 번역 텍스트 가져오기 (로컬 번역만 사용)
  static String getText(String languageCode, String key) {
    if (!_isInitialized) {
      logger.w('PicnicLibL10n이 초기화되지 않았습니다 (getText): $key');
      return key;
    }

    try {
      // 디버깅을 위한 언어 코드 확인
      if (!supportedLocales.any((l) => l.languageCode == languageCode)) {
        logger.w('지원되지 않는 언어 코드: $languageCode, $key에 대한 번역 시도');
        languageCode = 'en'; // 기본값으로 영어 사용
      }

      // 로컬 fallback 번역에서 가져오기
      final translation = _getFallbackTranslation(key, languageCode);
      if (translation != null && translation.isNotEmpty) {
        return translation;
      }

      // 번역 실패 시 최후의 대안으로 하드코딩된 기본값 시도
      if (key == 'app_name') return 'TTJA';
      if (key.startsWith('nav_')) return key.substring(4).toUpperCase();
      if (key.startsWith('label_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).map((part) => _capitalize(part)).join(' ');
        }
      }

      // 모든 시도가 실패하면 키 반환
      logger.w('번역을 찾을 수 없음: [$languageCode] $key');
      return key;
    } catch (e, s) {
      logger.e('번역 가져오기 중 오류: $key', error: e, stackTrace: s);
      return key;
    }
  }

  // 문자열의 첫 글자를 대문자로 변환
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String t(String key, [Map<String, String>? args]) {
    if (!_isInitialized) {
      // 초기화 안 된 경우에도 키를 기반으로 가능한 의미있는 문자열 반환
      logger.w('PicnicLibL10n이 완전히 초기화되지 않았습니다! 키: $key');

      // 키에서 의미 있는 텍스트 추출 시도
      if (key.contains('_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          // label_vote_upcoming -> Vote Upcoming 형태로 변환
          return parts.sublist(1).map((part) => _capitalize(part)).join(' ');
        }
      }

      return key;
    }

    try {
      // 현재 언어 코드 가져오기
      final languageCode = _getLanguage();

      // 로컬 fallback 번역에서 직접 가져오기
      final fallbackText = _getFallbackTranslation(key, languageCode);
      if (fallbackText != null) {
        return _formatTranslation(fallbackText, args);
      }

      // 모든 번역이 실패한 경우 키 기반 변환 시도
      if (key.contains('_')) {
        final parts = key.split('_');
        if (parts.length > 1) {
          final converted =
              parts.sublist(1).map((part) => _capitalize(part)).join(' ');
          return _formatTranslation(converted, args);
        }
      }

      return _formatTranslation(key, args);
    } catch (e, s) {
      logger.e('번역 과정에서 오류 발생: $key', error: e, stackTrace: s);
      return _formatTranslation(key, args);
    }
  }

  /// 기본 번역 제공 (Crowdin 실패 시 사용)
  static String? _getFallbackTranslation(String key, String languageCode) {
    // 한국어 기본 번역
    if (languageCode == 'ko') {
      switch (key) {
        case 'compatibility_purchase_message':
          return '나와 {artistName}의 궁합 점수가 궁금하다면? 🎯';
        case 'compatibility_empty_state_title':
          return '아직 궁합을 확인하지 않았어요';
        case 'compatibility_empty_state_subtitle':
          return '좋아하는 아티스트와의 궁합을 확인해보세요!';
        case 'label_reply':
          return '답글';
        case 'post_comment_action_show_translation':
          return '번역 보기';
        case 'post_comment_action_show_original':
          return '원문 보기';
        case 'post_comment_action_translate':
          return '번역하기';
        case 'post_comment_reported_comment':
          return '신고된 댓글';
        case 'post_comment_deleted_comment':
          return '삭제된 댓글';
        case 'post_comment_content_more':
          return '더보기';
        case 'post_comment_translated':
          return '번역됨';
        case 'error_action_failed':
          return '작업이 실패했습니다.';
        case 'label_hint_comment':
          return '댓글을 입력하세요';
        case 'common_retry_label':
          return '다시 시도';
        case 'label_retry':
          return '다시 시도';
        case 'popup_label_delete':
          return '삭제';
        case 'label_title_report':
          return '신고';
        case 'dialog_caution':
          return '주의';
        case 'ban_title':
          return '계정 정지';
        case 'ban_message':
          return '커뮤니티 가이드라인 위반으로 인해 계정이 일시적으로 정지되었습니다.';
        case 'ban_contact':
          return '문의사항이 있으시면 고객센터로 연락주세요.';
        // QnA 관련 번역 추가
        case 'qna_page_title':
          return 'Q&A';
        case 'qna_list_title':
          return 'Q&A 목록';
        case 'qna_create_page_title':
          return 'Q&A 작성';
        case 'qna_detail_page_title':
          return 'Q&A 상세';
        case 'qna_title_hint':
          return '제목을 입력해주세요';
        case 'qna_content_hint':
          return '문의 내용을 입력해주세요';
        case 'qna_submit_button':
          return '등록';
        case 'qna_submit_success':
          return '문의가 성공적으로 등록되었습니다';
        case 'qna_submit_error':
          return '문의 등록 중 오류가 발생했습니다';
        case 'qna_title_required':
          return '제목을 입력해 주세요';
        case 'qna_title_too_short':
          return '제목을 2글자 이상 입력해 주세요';
        case 'qna_content_required':
          return '내용을 입력해 주세요';
        case 'qna_content_too_short':
          return '내용을 10글자 이상 입력해 주세요';
        case 'qna_public_option':
          return '공개 문의';
        case 'qna_private':
          return '비공개';
        case 'qna_load_error':
          return '데이터를 불러오는 중 오류가 발생했습니다';
        case 'qna_info_title':
          return '문의 정보';
        case 'qna_status':
          return '상태';
        case 'qna_created_at':
          return '작성일';
        case 'qna_updated_at':
          return '수정일';
        case 'qna_public_status':
          return '공개 여부';
        case 'qna_answer_title':
          return '답변';
        case 'qna_answered_at':
          return '답변일';
        case 'retry':
          return '다시 시도';
        case 'qna_empty_list':
          return '등록된 문의가 없습니다';
        case 'qna_create_first':
          return '첫 번째 문의를 작성해보세요!';
        // QnA 상태 관련
        case 'qna_status_pending':
          return '대기중';
        case 'qna_status_answered':
          return '답변완료';
        case 'qna_status_resolved':
          return '해결됨';
        case 'qna_status_closed':
          return '종료';
        // 시간 관련
        case 'days_ago':
          return '일 전';
        case 'hours_ago':
          return '시간 전';
        case 'minutes_ago':
          return '분 전';
        case 'just_now':
          return '방금 전';
        // 기타
        case 'qna_error_message':
          return '오류가 발생했습니다';
        case 'qna_content':
          return '내용';
        case 'qna_title':
          return '제목';
        case 'qna_public':
          return '공개';
      }
    }

    // 영어 기본 번역
    switch (key) {
      case 'compatibility_purchase_message':
        return 'Curious about compatibility score with {artistName}? 🎯';
      case 'compatibility_empty_state_title':
        return 'No compatibility checked yet';
      case 'compatibility_empty_state_subtitle':
        return 'Check compatibility with your favorite artist!';
      case 'label_reply':
        return 'Reply';
      case 'post_comment_action_show_translation':
        return 'Show Translation';
      case 'post_comment_action_show_original':
        return 'Show Original';
      case 'post_comment_action_translate':
        return 'Translate';
      case 'post_comment_reported_comment':
        return 'Reported Comment';
      case 'post_comment_deleted_comment':
        return 'Deleted Comment';
      case 'post_comment_content_more':
        return 'Show More';
      case 'post_comment_translated':
        return 'Translated';
      case 'error_action_failed':
        return 'Action failed';
      case 'label_hint_comment':
        return 'Write a comment';
      case 'common_retry_label':
        return 'Retry';
      case 'label_retry':
        return 'Retry';
      case 'popup_label_delete':
        return 'Delete';
      case 'label_title_report':
        return 'Report';
      case 'dialog_caution':
        return 'Caution';
      case 'ban_title':
        return 'Account Suspended';
      case 'ban_message':
        return 'Your account has been temporarily suspended due to violation of community guidelines.';
      case 'ban_contact':
        return 'For inquiries, please contact customer support.';
      // QnA 관련 영어 번역 추가
      case 'qna_page_title':
        return 'Q&A';
      case 'qna_list_title':
        return 'Q&A List';
      case 'qna_create_page_title':
        return 'Create Q&A';
      case 'qna_detail_page_title':
        return 'Q&A Details';
      case 'qna_title_hint':
        return 'Please enter a title';
      case 'qna_content_hint':
        return 'Please enter your inquiry';
      case 'qna_submit_button':
        return 'Submit';
      case 'qna_submit_success':
        return 'Your inquiry has been submitted successfully';
      case 'qna_submit_error':
        return 'An error occurred while submitting your inquiry';
      case 'qna_title_required':
        return 'Please enter a title';
      case 'qna_title_too_short':
        return 'Please enter at least 2 characters for the title';
      case 'qna_content_required':
        return 'Please enter content';
      case 'qna_content_too_short':
        return 'Please enter at least 10 characters for content';
      case 'qna_public_option':
        return 'Public Inquiry';
      case 'qna_private':
        return 'Private';
      case 'qna_load_error':
        return 'An error occurred while loading data';
      case 'qna_info_title':
        return 'Inquiry Information';
      case 'qna_status':
        return 'Status';
      case 'qna_created_at':
        return 'Created';
      case 'qna_updated_at':
        return 'Updated';
      case 'qna_public_status':
        return 'Visibility';
      case 'qna_answer_title':
        return 'Answer';
      case 'qna_answered_at':
        return 'Answered';
      case 'retry':
        return 'Retry';
      case 'qna_empty_list':
        return 'No inquiries registered';
      case 'qna_create_first':
        return 'Write your first inquiry!';
      // QnA status related
      case 'qna_status_pending':
        return 'Pending';
      case 'qna_status_answered':
        return 'Answered';
      case 'qna_status_resolved':
        return 'Resolved';
      case 'qna_status_closed':
        return 'Closed';
      // Time related
      case 'days_ago':
        return ' days ago';
      case 'hours_ago':
        return ' hours ago';
      case 'minutes_ago':
        return ' minutes ago';
      case 'just_now':
        return 'Just now';
      // Others
      case 'qna_error_message':
        return 'An error occurred';
      case 'qna_content':
        return 'Content';
      case 'qna_title':
        return 'Title';
      case 'qna_public':
        return 'Public';
    }

    return null;
  }
}

/// 커스텀 로컬라이제이션 델리게이트
class _PicnicLocalizationsDelegate extends LocalizationsDelegate<dynamic> {
  const _PicnicLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return PicnicLibL10n.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<dynamic> load(Locale locale) async {
    return null;
  }

  @override
  bool shouldReload(_PicnicLocalizationsDelegate old) => false;
}

/// 번역 텍스트 포맷팅
String _formatTranslation(String text, Map<String, String>? args) {
  if (args == null || args.isEmpty) return text;

  String result = text;

  // 디버깅: compatibility 관련일 때 로그 출력
  if (text.contains('compatibility') || text.contains('궁합')) {
    logger.d('🔄 포맷팅 시작: "$text" with args: $args');
  }

  // Map 타입 처리 (이름 기반 플레이스홀더)
  args.forEach((key, value) {
    final placeholder = '{$key}';
    final beforeReplace = result;
    result = result.replaceAll(placeholder, value);

    // 디버깅: compatibility 관련일 때 각 치환 과정 로그
    if (text.contains('compatibility') || text.contains('궁합')) {
      logger.d(
          '🔄 치환: "$placeholder" -> "$value" | "$beforeReplace" -> "$result"');
    }
  });

  // 디버깅: 최종 결과
  if (text.contains('compatibility') || text.contains('궁합')) {
    logger.d('🔄 포맷팅 완료: "$result"');
  }

  return result;
}

/// 현재 로케일의 언어 코드 가져오기
String getLocaleLanguage() {
  return PlatformDispatcher.instance.locale.languageCode;
}

/// JSON에서 로케일별 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json) {
  if (json.isEmpty) return '';

  final locale = PicnicLibL10n.getCurrentLocale().languageCode;
  return json[locale] ?? json['en'] ?? '';
}

/// 전역 번역 함수
String t(String key, [Map<String, String>? args]) {
  return PicnicLibL10n.t(key, args);
}
