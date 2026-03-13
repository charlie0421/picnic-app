import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Extracted receipt format detection and JWS parsing helpers.
/// These were private methods in ReceiptVerificationService, made public
/// for testability.
class ReceiptFormatHelper {
  /// Detect the format of a receipt string.
  ///
  /// Returns one of:
  /// - 'StoreKit2 JWT'
  /// - 'StoreKit1 Base64'
  /// - 'JWT Custom'
  /// - 'Unknown'
  @visibleForTesting
  static String detectReceiptFormat(String receipt) {
    if (receipt.startsWith('eyJ')) {
      return 'StoreKit2 JWT';
    } else if (receipt.startsWith('MIIT') || receipt.startsWith('MIIK')) {
      return 'StoreKit1 Base64';
    } else if (receipt.contains('.') && receipt.split('.').length == 3) {
      return 'JWT Custom';
    }
    return 'Unknown';
  }

  /// Validate receipt inputs. Throws if any input is empty.
  @visibleForTesting
  static void validateInputs(String receipt, String productId, String userId) {
    if (receipt.isEmpty) {
      throw Exception('영수증 데이터가 비어있습니다');
    }
    if (productId.isEmpty) {
      throw Exception('상품 ID가 비어있습니다');
    }
    if (userId.isEmpty) {
      throw Exception('사용자 ID가 비어있습니다');
    }
  }

  /// Create an idempotency key from a JWS string for iOS duplicate detection.
  ///
  /// For valid StoreKit2 JWTs, extracts transactionId and signedDate from the payload.
  /// For non-JWT strings, falls back to a hash-based key.
  @visibleForTesting
  static String makeIdemKeyFromJWS(String jws) {
    try {
      if (!_isStoreKit2JWT(jws)) return 'raw:${jws.hashCode}';
      final parts = jws.split('.');
      String normalize(String s) {
        s = s.replaceAll('-', '+').replaceAll('_', '/');
        while (s.length % 4 != 0) {
          s += '=';
        }
        return s;
      }

      final payload = json.decode(
        utf8.decode(base64.decode(normalize(parts[1]))),
      );
      final tx =
          (payload['transactionId'] ?? payload['originalTransactionId'] ?? '')
              .toString();
      final time =
          (payload['signedDate'] ??
                  payload['purchaseDate'] ??
                  payload['originalPurchaseDate'] ??
                  '')
              .toString();
      return 'ios:$tx:$time';
    } catch (_) {
      return 'raw:${jws.hashCode}';
    }
  }

  /// Determine the iOS receipt format string for the verification request body.
  @visibleForTesting
  static String getIOSReceiptFormatParam(String receiptFormat) {
    return receiptFormat.contains('StoreKit2 JWT')
        ? 'storekit2_jwt'
        : 'legacy';
  }

  /// Check if a receipt string is a StoreKit2 JWT format.
  @visibleForTesting
  static bool isStoreKit2JWT(String receiptData) {
    try {
      return receiptData.startsWith('eyJ') &&
          receiptData.split('.').length == 3;
    } catch (e) {
      return false;
    }
  }

  // Keep private alias for internal use
  static bool _isStoreKit2JWT(String receiptData) => isStoreKit2JWT(receiptData);

  /// Decode a single JWT part (header or payload) from Base64URL to a Map.
  @visibleForTesting
  static Map<String, dynamic> decodeJWTPart(String part) {
    String normalized = part.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    final decoded = base64.decode(normalized);
    return json.decode(utf8.decode(decoded));
  }

  /// Determine iOS environment based on package info fields.
  ///
  /// Returns 'sandbox' or 'production'.
  @visibleForTesting
  static String detectIOSEnvironment({
    required String? installerStore,
    required String appName,
    required String buildSignature,
  }) {
    final isTestEnvironment =
        installerStore == 'com.apple.testflight' ||
        installerStore == null ||
        appName.toLowerCase().contains('testflight') ||
        buildSignature.isNotEmpty;
    return isTestEnvironment ? 'sandbox' : 'production';
  }

  /// Determine Android environment based on installer store.
  ///
  /// Returns 'sandbox' or 'production'.
  @visibleForTesting
  static String detectAndroidEnvironment({required String? installerStore}) {
    return installerStore != 'com.android.vending' ? 'sandbox' : 'production';
  }

  /// Build the iOS verification request body.
  @visibleForTesting
  static Map<String, dynamic> buildIOSRequestBody({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String receiptFormat,
  }) {
    return {
      'receipt': receipt,
      'platform': 'ios',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': getIOSReceiptFormatParam(receiptFormat),
    };
  }

  /// Build the Android verification request body.
  @visibleForTesting
  static Map<String, dynamic> buildAndroidRequestBody({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String clientTraceId,
  }) {
    return {
      'receipt': receipt,
      'platform': 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': 'google_play',
      'client_trace_id': clientTraceId,
    };
  }

  /// Determine if an exception represents a timeout error.
  @visibleForTesting
  static bool isTimeoutError(Exception? exception) {
    if (exception == null) return false;
    return exception is TimeoutException ||
        exception.toString().toLowerCase().contains('time');
  }

  /// Calculate retry delay for a given attempt number.
  ///
  /// Uses [baseRetryDelay] * [attempt] seconds.
  @visibleForTesting
  static Duration calculateRetryDelay({
    required int attempt,
    required int baseRetryDelaySeconds,
  }) {
    return Duration(seconds: baseRetryDelaySeconds * attempt);
  }
}
