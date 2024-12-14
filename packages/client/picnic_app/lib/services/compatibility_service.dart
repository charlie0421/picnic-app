// lib/services/compatibility_service.dart

import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/community/compatibility_result.dart';

class CompatibilityService {
  final String openAiApiKey;
  final SupabaseClient supabase;

  CompatibilityService({
    required this.openAiApiKey,
    required this.supabase,
  }) {
    OpenAI.apiKey = openAiApiKey;
  }

  Future<CompatibilityResult> getCompatibility({
    required String userId,
    required String idolName,
    required DateTime idolBirthDate,
    required DateTime userBirthDate,
    required String userGender,
    required String? birthTime,
  }) async {
    try {
      final prompt = '''
궁합 분석 정보:
- 아이돌: $idolName (${idolBirthDate.year}년 ${idolBirthDate.month}월 ${idolBirthDate.day}일)
- 사용자: ${userBirthDate.year}년 ${userBirthDate.month}월 ${userBirthDate.day}일
- 성별: $userGender
${birthTime == null ? '' : '- 태어난 시간: $birthTime'}

위 정보를 바탕으로 두 사람의 궁합을 분석하여 다음 JSON 형식으로 결과를 알려주세요:
{
  "compatibility_score": 85,
  "compatibility_summary": "뜨겁고 활기찬 에너지의 완벽한 조합! (200자 이내로 요약)",
  "details": {
    "style": {
      "idol_style": "아이돌의 패션과 스타일 특징 설명",
      "user_style": "사용자에게 어울리는 스타일 추천",
      "couple_style": "커플 스타일링 제안"
    },
    "activities": {
      "recommended": ["추천 활동 1", "추천 활동 2", "추천 활동 3"],
      "description": "추천 활동에 대한 상세 설명"
    }
  },
  "tips": [
    "궁합을 높이기 위한 팁 1",
    "궁합을 높이기 위한 팁 2",
    "궁합을 높이기 위한 팁 3"
  ]
}

결과는 긍정적이고 구체적으로 작성해주되, 현실적인 조언을 포함해주세요.
''';

      // OpenAI API 호출
      final completion = await OpenAI.instance.completion.create(
        model: "gpt-3.5-turbo-instruct",
        prompt: prompt,
        maxTokens: 1000,
        temperature: 0.7,
      );

      // JSON 파싱
      final resultJson = jsonDecode(completion.choices.first.text);

      // CompatibilityResult 객체 생성
      final compatibilityResult = CompatibilityResult(
        id: const Uuid().v4(),
        userId: userId,
        idolName: idolName,
        userBirthDate: userBirthDate,
        idolBirthDate: idolBirthDate,
        userGender: userGender,
        birthTime: birthTime,
        compatibilityScore: resultJson['score'],
        compatibilitySummary: resultJson['compatibility_summary'],
        details: resultJson['details'],
        tips: List<String>.from(resultJson['tips']),
        createdAt: DateTime.now(),
      );

      // Supabase에 저장
      await supabase
          .from('compatibility_results')
          .insert(compatibilityResult.toJson());

      return compatibilityResult;
    } catch (e, s) {
      logger.e('궁합 분석 중 오류가 발생했습니다', error: e, stackTrace: s);
      throw Exception('궁합 분석 중 오류가 발생했습니다: $e');
    }
  }

  Future<List<CompatibilityResult>> getUserCompatibilityHistory(
      String userId) async {
    try {
      final response = await supabase
          .from('compatibility_results')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((data) => CompatibilityResult.fromJson(data))
          .toList();
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);

      rethrow;
    }
  }
}
