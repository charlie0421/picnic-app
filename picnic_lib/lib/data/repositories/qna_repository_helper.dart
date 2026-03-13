import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure helper methods extracted from [QnaRepository] for testability.
///
/// All methods are static and free of I/O or Supabase dependencies.
@visibleForTesting
class QnaRepositoryHelper {
  QnaRepositoryHelper._();

  /// Generates a UUID-based file name with the given [extension].
  ///
  /// The [uuid] parameter should be a pre-generated UUID string (with or
  /// without dashes). Dashes are stripped and the result is concatenated
  /// with the normalised extension.
  ///
  /// Extension normalisation rules:
  /// - If [extension] already starts with `.`, it is used as-is.
  /// - If [extension] is non-empty but lacks a leading `.`, one is prepended.
  /// - If [extension] is empty, no extension is appended.
  static String generateUuidName(String uuid, String extension) {
    final sanitised = uuid.replaceAll('-', '');
    final normalizedExt = extension.isNotEmpty && extension.startsWith('.')
        ? extension
        : (extension.isNotEmpty ? '.$extension' : '');
    return '$sanitised$normalizedExt';
  }

  /// Normalises a thread status value.
  ///
  /// Returns `'RECEIVED'` when [status] is `null`, empty, or contains only
  /// whitespace. Otherwise returns the trimmed [status].
  static String normalizeThreadStatus(String? status) {
    final trimmed = status?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'RECEIVED';
    }
    return trimmed;
  }

  /// Builds a storage file path for a QnA attachment.
  ///
  /// Format: `qna/<userId>/<messageId>/<fileName>`
  static String buildAttachmentPath(
      String userId, int messageId, String fileName) {
    return 'qna/$userId/$messageId/$fileName';
  }

  /// Builds an attachment record map for database insertion.
  static Map<String, dynamic> buildAttachmentRecord({
    required int messageId,
    required String fileName,
    required String filePath,
    required String? fileType,
    required int fileSize,
  }) {
    return {
      'message_id': messageId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }

  /// Resolves a localised label from a JSON map field.
  ///
  /// Returns `null` if [labelField] is not a `Map<String, dynamic>` or
  /// if the resolved text is empty.
  ///
  /// The [resolveLocaleText] callback should perform locale-aware lookup
  /// (e.g. `getLocaleTextFromJson`).
  static String? resolveCategoryLabel(
    dynamic labelField,
    String Function(Map<String, dynamic>) resolveLocaleText,
  ) {
    if (labelField is Map<String, dynamic>) {
      final resolved = resolveLocaleText(labelField);
      return resolved.isEmpty ? null : resolved;
    }
    return null;
  }

  /// Parses a raw category row into its constituent parts.
  ///
  /// Returns a record of `(label, questionTemplate, answerTemplate)` after
  /// applying [resolveLocaleText] to each JSON field.
  static ({String label, String? questionTemplate, String? answerTemplate})
      parseCategoryRow(
    Map<String, dynamic> row,
    String Function(Map<String, dynamic>) resolveLocaleText,
  ) {
    final labelJson = row['label'] as Map<String, dynamic>?;
    final qJson = row['question_template'] as Map<String, dynamic>?;
    final aJson = row['answer_template'] as Map<String, dynamic>?;

    final label = labelJson != null ? resolveLocaleText(labelJson) : '';
    final qTmpl = qJson != null ? resolveLocaleText(qJson) : null;
    final aTmpl = aJson != null ? resolveLocaleText(aJson) : null;

    return (label: label, questionTemplate: qTmpl, answerTemplate: aTmpl);
  }
}
