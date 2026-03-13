import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// PostViewPage에서 추출한 순수 로직 헬퍼
@visibleForTesting
class PostViewHelper {
  /// Quill content를 List<dynamic> 형태로 파싱
  ///
  /// null, List, Map, String 등 다양한 입력을 처리하여
  /// Quill Document에 사용할 수 있는 ops 리스트를 반환합니다.
  static List<dynamic> parseContent(dynamic content) {
    try {
      if (content == null) {
        return [
          {"insert": "\n"},
        ];
      }

      if (content is List) {
        return content;
      }

      if (content is Map<String, dynamic>) {
        final ops = extractOpsFromMap(content);
        if (ops != null) {
          return ops;
        }
        return [content];
      }

      if (content is String) {
        final trimmed = content.trim();
        if (trimmed.isEmpty) {
          return [
            {"insert": "\n"},
          ];
        }

        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded;
          }
          if (decoded is Map<String, dynamic>) {
            final ops = extractOpsFromMap(decoded);
            if (ops != null) {
              return ops;
            }
            return [decoded];
          }
        } catch (_) {
          // fallthrough to treat as plain text
        }

        return [
          {"insert": content},
        ];
      }

      return [
        {"insert": content.toString()},
      ];
    } catch (e) {
      return [
        {"insert": "Content parse error"},
      ];
    }
  }

  /// Map에서 ops 또는 delta를 추출
  static List<dynamic>? extractOpsFromMap(Map<String, dynamic> map) {
    final ops = map['ops'];
    if (ops is List) {
      return ops;
    }
    final delta = map['delta'];
    if (delta is List) {
      return delta;
    }
    if (delta is Map<String, dynamic>) {
      final deltaOps = delta['ops'];
      if (deltaOps is List) {
        return deltaOps;
      }
    }
    return null;
  }

  /// 원본 콘텐츠에서 폴백 텍스트 추출
  static String extractFallbackText(dynamic rawContent) {
    if (rawContent == null) {
      return '';
    }
    if (rawContent is String) {
      return rawContent;
    }
    try {
      return jsonEncode(rawContent);
    } catch (_) {
      return rawContent.toString();
    }
  }

  /// 에러 타입을 분류하여 에러 코드 반환
  static String classifyError(dynamic error) {
    if (error is SocketException) {
      return 'network';
    } else if (error is TimeoutException) {
      return 'timeout';
    } else if (error is FormatException) {
      return 'format';
    } else {
      return 'unknown';
    }
  }

  /// 게시물이 삭제되었는지 확인
  static bool isPostDeleted(DateTime? deletedAt) {
    return deletedAt != null;
  }

  /// 게시물 작성자 표시 이름 결정
  static String resolveAuthorName({
    required bool isAnonymous,
    required String? nickname,
    required String anonymousLabel,
  }) {
    if (isAnonymous) {
      return anonymousLabel;
    }
    return nickname ?? '';
  }
}
