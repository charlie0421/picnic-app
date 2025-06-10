import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';

void main() {
  group('Korean Search Utils Tests', () {
    test('블랙핑크 초성 검색 테스트', () {
      const text = '블랙핑크';

      // 정확한 초성 추출 테스트
      final initials = KoreanSearchUtils.extractKoreanInitials(text);
      logger.d('블랙핑크 초성: $initials');

      // 정확한 초성 매칭 테스트
      expect(KoreanSearchUtils.matchesKoreanInitials(text, 'ㅂㄹㅍㅋ'), true);

      // 부분 매칭 테스트 (ㅍㄹㅍㅋ)
      expect(KoreanSearchUtils.matchesKoreanInitials(text, 'ㅍㄹㅍㅋ'), true);

      // 순서 무관 테스트
      expect(KoreanSearchUtils.matchesKoreanInitials(text, 'ㅍㅂㅋㄹ'), true);
    });

    test('다른 아티스트 초성 검색 테스트', () {
      // 방탄소년단
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌㅅ'), true);
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌㅅㄴㄷ'), true);

      // 아이유
      expect(KoreanSearchUtils.matchesKoreanInitials('아이유', 'ㅇㅇㅇ'), true);
      expect(KoreanSearchUtils.matchesKoreanInitials('아이유', 'ㅇㅇ'), true);
    });

    test('일반 텍스트 검색 테스트', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('블랙핑크', '블랙'), true);
      expect(KoreanSearchUtils.matchesKoreanInitials('블랙핑크', '핑크'), true);
      expect(
          KoreanSearchUtils.matchesKoreanInitials('BLACKPINK', 'black'), true);
    });
  });
}
