import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/data/models/community/fortune.dart';

/// FortunePage에서 추출한 순수 로직 헬퍼
@visibleForTesting
class FortuneDialogHelper {
  /// Lucky 항목들을 콤마로 연결하여 표시 문자열로 변환
  static String formatLuckyItems(List<dynamic> items) {
    return items.map((e) => e.toString()).join(', ');
  }

  /// 특정 월의 운세를 찾기
  static MonthlyFortuneModel? findMonthlyFortune(
    List<MonthlyFortuneModel> fortunes,
    int month,
  ) {
    try {
      return fortunes.firstWhere((f) => f.month == month);
    } catch (_) {
      return null;
    }
  }

  /// 운세의 전체 카테고리 수 계산 (aspects)
  static int countAspectCategories(AspectModel aspects) {
    int count = 0;
    if (aspects.honor.isNotEmpty) count++;
    if (aspects.career.isNotEmpty) count++;
    if (aspects.health.isNotEmpty) count++;
    if (aspects.finances.isNotEmpty) count++;
    if (aspects.relationships.isNotEmpty) count++;
    return count;
  }

  /// Lucky 데이터가 비어있는지 확인
  static bool isLuckyEmpty(LuckyModel lucky) {
    return lucky.days.isEmpty &&
        lucky.colors.isEmpty &&
        lucky.numbers.isEmpty &&
        lucky.directions.isEmpty;
  }

  /// 조언 목록이 유효한지 확인
  static bool hasValidAdvice(List<String> advice) {
    return advice.isNotEmpty && advice.any((a) => a.trim().isNotEmpty);
  }

  /// ExpansionTile 상태를 맵으로 저장
  static Map<String, bool> saveOverallExpansionStates({
    required bool isOverallExpanded,
    required bool isLuckyExpanded,
    required bool isAdviceExpanded,
  }) {
    return {
      'overall': isOverallExpanded,
      'lucky': isLuckyExpanded,
      'advice': isAdviceExpanded,
    };
  }

  /// 월별 ExpansionTile 상태를 맵으로 저장
  static Map<int, bool> saveMonthlyExpansionStates(
    Map<int, bool> currentStates,
  ) {
    return Map<int, bool>.from(currentStates);
  }

  /// 아티스트 이름을 로케일에 맞게 가져오기
  static String resolveArtistName(
    Map<String, dynamic>? nameMap,
    String locale,
  ) {
    if (nameMap == null) return '';
    return (nameMap[locale] ?? nameMap['ko'] ?? nameMap['en'] ?? '').toString();
  }

  /// 운세 데이터의 완전성 검증
  static bool isFortuneComplete(FortuneModel fortune) {
    return fortune.overallLuck.isNotEmpty &&
        fortune.monthlyFortunes.length == 12 &&
        fortune.advice.isNotEmpty;
  }
}
