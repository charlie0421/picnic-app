import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

/// 한국어 초성 검색과 하이라이팅 기능을 제공하는 유틸리티 클래스
///
/// 이 클래스는 다음 기능들을 제공합니다:
/// - 한국어 초성 추출
/// - 초성 검색 매칭
/// - 검색어 하이라이팅
/// - 다국어 텍스트에서 검색어 매칭된 언어 반환
class KoreanSearchUtils {
  /// 한국어 초성 배열
  static const List<String> _initials = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ'
  ];

  /// 한국어 텍스트에서 초성을 추출합니다.
  ///
  /// [text] 초성을 추출할 텍스트
  ///
  /// 반환값: 추출된 초성 문자열
  ///
  /// 예시:
  /// ```dart
  /// KoreanSearchUtils.extractKoreanInitials('방탄소년단'); // 'ㅂㅌㅅㄴㄷ'
  /// KoreanSearchUtils.extractKoreanInitials('BTS'); // 'BTS'
  /// ```
  static String extractKoreanInitials(String text) {
    String result = '';
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);

      // 한글 완성형 문자인지 확인 (가-힣)
      if (code >= 0xAC00 && code <= 0xD7A3) {
        // 초성 추출: (문자코드 - 0xAC00) / (21 * 28)
        final initialIndex = (code - 0xAC00) ~/ (21 * 28);
        result += _initials[initialIndex];
      } else {
        // 한글이 아닌 문자는 그대로 추가
        result += char;
      }
    }
    return result;
  }

  /// 텍스트가 검색어와 매칭되는지 확인합니다 (초성 검색 포함).
  ///
  /// [text] 검색 대상 텍스트
  /// [query] 검색어
  ///
  /// 반환값: 매칭 여부
  ///
  /// 예시:
  /// ```dart
  /// KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌㅅ'); // true
  /// KoreanSearchUtils.matchesKoreanInitials('방탄소년단', '방탄'); // true
  /// KoreanSearchUtils.matchesKoreanInitials('BTS', 'bt'); // true
  /// KoreanSearchUtils.matchesKoreanInitials('블랙핑크', 'ㅂㄹㅍㅋ'); // true
  /// KoreanSearchUtils.matchesKoreanInitials('블랙핑크', 'ㅍㄹㅍㅋ'); // true (부분매칭)
  /// ```
  static bool matchesKoreanInitials(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    final textInitials = extractKoreanInitials(text).toLowerCase();
    final queryLower = query.toLowerCase();

    // 일반 텍스트 검색도 포함
    if (text.toLowerCase().contains(queryLower)) {
      return true;
    }

    // 초성 검색 - 정확한 매칭
    if (textInitials.contains(queryLower)) {
      return true;
    }

    // 초성 검색 - 부분 매칭 (각 초성이 순서대로 포함되는지 확인)
    if (_isKoreanInitials(queryLower) && textInitials.isNotEmpty) {
      return _matchesPartialInitials(textInitials, queryLower);
    }

    return false;
  }

  /// 초성인지 확인
  static bool _isKoreanInitials(String text) {
    return text.split('').every((char) => _initials.contains(char));
  }

  /// 부분 초성 매칭 확인 (순서 상관없이 모든 초성이 포함되어 있는지)
  static bool _matchesPartialInitials(
      String textInitials, String queryInitials) {
    // 검색어의 각 초성이 텍스트 초성에 포함되어 있는지 확인
    final textChars = textInitials.split('');
    final queryChars = queryInitials.split('');

    // 유연한 매칭: 검색어 초성의 80% 이상이 매칭되면 true
    int matchCount = 0;
    for (final queryChar in queryChars) {
      if (textChars.contains(queryChar)) {
        matchCount++;
      }
    }

    final matchRatio = matchCount / queryChars.length;
    return matchRatio >= 0.8; // 80% 이상 매칭
  }

  /// 검색어에 맞는 하이라이트된 TextSpan 리스트를 생성합니다.
  ///
  /// [text] 하이라이트할 텍스트
  /// [query] 검색어
  /// [baseStyle] 기본 텍스트 스타일 (선택사항)
  /// [highlightColor] 하이라이트 색상 (선택사항, 기본값: primary500 with 30% opacity)
  ///
  /// 반환값: 하이라이트가 적용된 TextSpan 리스트
  ///
  /// 예시:
  /// ```dart
  /// final spans = KoreanSearchUtils.buildHighlightedTextSpans(
  ///   '방탄소년단',
  ///   'ㅂㅌㅅ',
  ///   TextStyle(fontSize: 16),
  /// );
  /// ```
  static List<TextSpan> buildHighlightedTextSpans(
    String text,
    String query, {
    TextStyle? baseStyle,
    Color? highlightColor,
  }) {
    if (query.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final effectiveHighlightColor =
        highlightColor ?? AppColors.primary500.withOpacity(0.3);

    // 일반 텍스트 검색 시도
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    if (index != -1) {
      // 일반 텍스트 검색 하이라이트
      while (index != -1) {
        // 하이라이트 이전 텍스트 추가
        if (index > start) {
          spans.add(TextSpan(
            text: text.substring(start, index),
            style: baseStyle,
          ));
        }

        // 하이라이트 효과
        spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: (baseStyle ?? const TextStyle()).copyWith(
            backgroundColor: effectiveHighlightColor,
            fontWeight: FontWeight.bold,
            color: baseStyle?.color ?? AppColors.grey900,
          ),
        ));

        start = index + query.length;
        index = lowerText.indexOf(lowerQuery, start);
      }

      // 남은 텍스트 추가
      if (start < text.length) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: baseStyle,
        ));
      }
    } else {
      // 초성 검색인지 확인
      final textInitials = extractKoreanInitials(text).toLowerCase();
      if (textInitials.contains(lowerQuery)) {
        // 초성 검색의 경우 전체 텍스트를 하이라이트
        spans.add(TextSpan(
          text: text,
          style: (baseStyle ?? const TextStyle()).copyWith(
            backgroundColor: effectiveHighlightColor,
            fontWeight: FontWeight.bold,
            color: baseStyle?.color ?? AppColors.grey900,
          ),
        ));
      } else {
        // 매칭되지 않는 경우 일반 텍스트
        spans.add(TextSpan(text: text, style: baseStyle));
      }
    }

    return spans;
  }

  /// 다국어 텍스트에서 검색어가 포함된 언어의 텍스트를 반환합니다.
  ///
  /// [nameMap] 다국어 텍스트 맵 (예: {'ko': '방탄소년단', 'en': 'BTS'})
  /// [query] 검색어
  ///
  /// 반환값: 검색어가 매칭된 언어의 텍스트, 매칭되지 않으면 기본 로케일 텍스트
  ///
  /// 예시:
  /// ```dart
  /// final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
  /// KoreanSearchUtils.getMatchingText(nameMap, 'ㅂㅌㅅ'); // '방탄소년단'
  /// KoreanSearchUtils.getMatchingText(nameMap, 'bts'); // 'BTS'
  /// ```
  static String getMatchingText(Map<String, dynamic> nameMap, String query) {
    final lowerQuery = query.toLowerCase();

    // 한국어에서 검색어 찾기 (일반 텍스트 + 초성)
    final koText = nameMap['ko']?.toString() ?? '';
    if (matchesKoreanInitials(koText, query)) {
      return koText;
    }

    // 영어에서 검색어 찾기
    final enText = nameMap['en']?.toString() ?? '';
    if (enText.toLowerCase().contains(lowerQuery)) {
      return enText;
    }

    // 일본어에서 검색어 찾기
    final jaText = nameMap['ja']?.toString() ?? '';
    if (jaText.toLowerCase().contains(lowerQuery)) {
      return jaText;
    }

    // 중국어에서 검색어 찾기
    final zhText = nameMap['zh']?.toString() ?? '';
    if (zhText.toLowerCase().contains(lowerQuery)) {
      return zhText;
    }

    // 검색어가 없으면 기본 로케일 텍스트 반환
    return getLocaleTextFromJson(nameMap);
  }

  /// 검색어가 있을 때 하이라이트된 RichText 위젯을 생성합니다.
  ///
  /// [text] 표시할 텍스트
  /// [query] 검색어
  /// [baseStyle] 기본 텍스트 스타일
  /// [highlightColor] 하이라이트 색상 (선택사항)
  /// [overflow] 텍스트 오버플로우 처리 방식 (선택사항)
  /// [maxLines] 최대 라인 수 (선택사항)
  ///
  /// 반환값: 하이라이트가 적용된 RichText 위젯
  static Widget buildHighlightedRichText(
    String text,
    String query,
    TextStyle baseStyle, {
    Color? highlightColor,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return RichText(
      overflow: overflow ?? TextOverflow.clip,
      maxLines: maxLines,
      text: TextSpan(
        style: baseStyle,
        children: buildHighlightedTextSpans(
          text,
          query,
          baseStyle: baseStyle,
          highlightColor: highlightColor,
        ),
      ),
    );
  }

  /// 검색어가 있을 때는 하이라이트된 RichText를, 없을 때는 일반 Text를 반환합니다.
  ///
  /// [text] 표시할 텍스트
  /// [query] 검색어
  /// [baseStyle] 기본 텍스트 스타일
  /// [highlightColor] 하이라이트 색상 (선택사항)
  /// [overflow] 텍스트 오버플로우 처리 방식 (선택사항)
  /// [maxLines] 최대 라인 수 (선택사항)
  ///
  /// 반환값: 조건에 따른 Text 또는 RichText 위젯
  static Widget buildConditionalHighlightText(
    String text,
    String query,
    TextStyle baseStyle, {
    Color? highlightColor,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    return buildHighlightedRichText(
      text,
      query,
      baseStyle,
      highlightColor: highlightColor,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
