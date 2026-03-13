import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

/// Pure logic helpers extracted from [Goonghap] provider for testability.
///
/// All methods are static and free of provider/state dependencies.
@visibleForTesting
class GoonghapProviderHelper {
  GoonghapProviderHelper._();

  /// Maximum number of retries for background processing.
  static const int maxRetries = 3;

  /// Whether [setGoonghap] should skip execution.
  ///
  /// Returns `true` when the state is loading or the current value
  /// already has the same id as the incoming goonghap.
  static bool shouldSkipSetGoonghap({
    required bool isLoading,
    required bool hasValue,
    required String? currentId,
    required String incomingId,
  }) {
    if (isLoading) return true;
    if (hasValue && currentId == incomingId) return true;
    return false;
  }

  /// Whether [loadGoonghap] should skip execution.
  ///
  /// Returns `true` when the state is loading, or when the current value
  /// already matches the requested id (unless [forceRefresh] is true).
  static bool shouldSkipLoadGoonghap({
    required bool isLoading,
    required bool hasValue,
    required String? currentId,
    required String requestedId,
    required bool forceRefresh,
  }) {
    if (isLoading) return true;
    if (!forceRefresh && hasValue && currentId == requestedId) return true;
    return false;
  }

  /// Validate inputs for creating a goonghap.
  ///
  /// Returns a [CreateGoonghapValidationError] if validation fails,
  /// or `null` if all inputs are valid.
  static CreateGoonghapValidationError? validateCreateGoonghapInput({
    required String? userId,
    required DateTime? artistBirthDate,
  }) {
    if (userId == null) return CreateGoonghapValidationError.notAuthenticated;
    if (artistBirthDate == null) {
      return CreateGoonghapValidationError.missingArtistBirthDate;
    }
    return null;
  }

  /// Build the data map for inserting a new goonghap record.
  static Map<String, dynamic> buildCreateGoonghapData({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) {
    return {
      'user_id': userId,
      'artist_id': artist.id,
      'idol_birth_date': artist.birthDate!.toIso8601String(),
      'user_birth_date': birthDate.toIso8601String(),
      'user_birth_time': birthTime,
      'gender': gender,
      'status': 'pending',
      'is_paid': false,
    };
  }

  /// Build the error message after all retries have been exhausted.
  static String buildRetryExhaustedErrorMessage({
    required int maxRetries,
    required String? lastErrorMessage,
  }) {
    return 'Failed after $maxRetries attempts: $lastErrorMessage';
  }

  /// Whether loading should remain active based on goonghap status.
  ///
  /// Loading should be turned off for all statuses except pending.
  static bool shouldTurnOffLoading(GoonghapStatus status) {
    return status != GoonghapStatus.pending;
  }

  /// Whether the goonghap is already paid based on current state.
  ///
  /// Returns `true` when the state has a value with the same goonghapId
  /// and isPaid is true.
  static bool isAlreadyPaidInState({
    required bool hasValue,
    required String? currentId,
    required bool? isPaid,
    required String goonghapId,
  }) {
    return hasValue && currentId == goonghapId && isPaid == true;
  }

  /// Parse the error response from the open-goonghap edge function.
  ///
  /// Returns [OpenGoonghapResult.insufficientBalance] if the error indicates
  /// insufficient balance, or [OpenGoonghapResult.error] otherwise.
  static OpenGoonghapResult parseOpenGoonghapError(
      Map<String, dynamic>? errorData) {
    final errorCode = errorData?['code'] as String?;

    if (errorCode == 'PAYMENT_FAILED') {
      final errorMessage = errorData?['message'] as String? ?? '';
      if (errorMessage.contains('부족') ||
          errorMessage.contains('insufficient')) {
        return OpenGoonghapResult.insufficientBalance;
      }
    }

    return OpenGoonghapResult.error;
  }

  /// Determine the result of openGoonghap from the edge function response.
  ///
  /// Returns [OpenGoonghapResult.alreadyPaid] if the response indicates
  /// the goonghap was already paid, or [OpenGoonghapResult.success] otherwise.
  static OpenGoonghapResult determineOpenGoonghapResult(
      Map<String, dynamic>? responseData) {
    final alreadyPaid = responseData?['alreadyPaid'] == true;
    return alreadyPaid
        ? OpenGoonghapResult.alreadyPaid
        : OpenGoonghapResult.success;
  }

  /// Merge main response data with i18n data for creating a GoonghapModel.
  ///
  /// When [status] is 'completed' and [i18nData] is empty, the status is
  /// overridden to 'error' with a 'No results found' message.
  static Map<String, dynamic> mergeResponseWithI18n({
    required Map<String, dynamic> mainResponse,
    required List<Map<String, dynamic>> i18nData,
  }) {
    final merged = Map<String, dynamic>.from(mainResponse);
    if (merged['status'] == 'completed' && i18nData.isEmpty) {
      merged['status'] = 'error';
      merged['error_message'] = 'No results found';
    }
    merged['i18n'] = i18nData;
    return merged;
  }

  /// Whether the retry count has been exhausted.
  static bool isRetryExhausted(int retryCount) {
    return retryCount >= maxRetries;
  }

  /// Calculate the delay duration for a given retry attempt.
  static Duration calculateRetryDelay({
    required int retryCount,
    Duration baseDelay = const Duration(seconds: 2),
  }) {
    return baseDelay * retryCount;
  }
}

/// Validation errors for creating a goonghap.
enum CreateGoonghapValidationError {
  /// User is not authenticated.
  notAuthenticated,

  /// Artist birth date is missing.
  missingArtistBirthDate,
}

/// 궁합 구매 결과
enum OpenGoonghapResult {
  /// 구매 성공
  success,

  /// 이미 구매됨 (중복 구매 방지)
  alreadyPaid,

  /// 잔액 부족
  insufficientBalance,

  /// 오류 발생
  error,
}
