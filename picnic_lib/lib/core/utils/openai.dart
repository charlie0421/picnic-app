import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';

/// Fallback response when OpenAI API is unavailable (rate limited, etc.)
/// Returns a safe default that allows content through
Map<String, dynamic> _getFallbackResponse() => {
      'flagged': false,
      'categories': {
        'sexual': false,
        'hate': false,
        'harassment': false,
        'self-harm': false,
        'sexual/minors': false,
        'hate/threatening': false,
        'violence/graphic': false,
        'self-harm/intent': false,
        'self-harm/instructions': false,
        'harassment/threatening': false,
        'violence': false,
      },
      'category_scores': {
        'sexual': 0.0,
        'hate': 0.0,
        'harassment': 0.0,
        'self-harm': 0.0,
        'sexual/minors': 0.0,
        'hate/threatening': 0.0,
        'violence/graphic': 0.0,
        'self-harm/intent': 0.0,
        'self-harm/instructions': 0.0,
        'harassment/threatening': 0.0,
        'violence': 0.0,
      },
    };

Future<Map<String, dynamic>> checkContent(String text) async {
  try {
    final response = await supabase.functions.invoke(
      'openai-moderation',
      body: {'text': text},
    );

    logger.i('Response status: ${response.status}');
    logger.i('Raw response data: ${response.data}');

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

    // Handle rate limiting (429) errors gracefully
    final errorMessage = e.toString();
    if (errorMessage.contains('429') ||
        errorMessage.contains('Too Many Requests')) {
      logger.w('OpenAI rate limited, using client-side fallback');
      return _getFallbackResponse();
    }

    rethrow;
  }
}
