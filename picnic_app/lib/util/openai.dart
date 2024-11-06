import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';

Future<Map<String, dynamic>> checkContent(String text) async {
  try {
    final response = await supabase.functions.invoke(
      'openai-moderation',
      body: {'text': text},
    );

    logger.i('Response status: ${response.status}');
    logger.i('Raw response data: ${response.data}'); // 전체 응답 데이터 로깅

    // 응답 데이터 유효성 검사
    if (response.data == null) {
      throw Exception('서버 응답이 비어있습니다');
    }
    // success 필드 확인
    final success = response.data['success'] as bool?;

    // data 필드 유효성 검사
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('응답 데이터 형식이 올바르지 않습니다');
    }

    final source = response.data['source'] as String?;
    if (source == 'fallback') {
      print('Using fallback content checking');
    }

    return data;
  } catch (e, stackTrace) {
    print('Error in checkContent: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
