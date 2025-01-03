import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';

Future<Map<String, dynamic>> checkContent(String text) async {
  try {
    final response = await supabase.functions.invoke(
      'openai-moderation',
      body: {'text': text},
    );

    logger.i('Response status: ${response.status}');
    logger.i('Raw response data: ${response.data}'); // 전체 응답 데이터 로깅

    // 응답 데이터 유효성 검사
    if (response.data == null || response.data['data'] == null) {
      throw Exception('응답 데이터 형식이 올바르지 않습니다');
    }

    final data = response.data['data'] as Map<String, dynamic>;
    final source = response.data['source'] as String?;
    if (source == 'fallback') {
      logger.i('Using fallback content checking');
    }

    return data;
  } catch (e, s) {
    logger.e('Error in checkContent: $e', stackTrace: s);
    rethrow;
  }
}
