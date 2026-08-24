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

  /// Extract the StoreKit `transactionId` from a JWS receipt.
  ///
  /// Unlike [makeIdemKeyFromJWS] this deliberately does NOT mix in
  /// `signedDate`: it is used as the durable queue key, and the key for one
  /// store transaction must stay stable across re-deliveries of that same
  /// transaction. Returns null when the receipt is not a parseable StoreKit2
  /// JWS (callers fall back to a random key).
  static String? appleTransactionIdFromJWS(String jws) {
    try {
      if (!isStoreKit2JWT(jws)) return null;
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
      if (payload is! Map) return null;
      final transactionId =
          (payload['transactionId'] ?? payload['originalTransactionId'] ?? '')
              .toString();
      return transactionId.isEmpty ? null : transactionId;
    } catch (_) {
      return null;
    }
  }

  /// The `format` value verify-receipt-v2 request bodies carry, per platform.
  ///
  /// Single source of truth shared by the foreground request builders below
  /// and by the durable receipt queue's re-send path, so the two can never
  /// drift. (The queue used to hardcode `google_play` for every entry.)
  static String verificationFormatFor({
    required String platform,
    required String receipt,
  }) {
    if (platform.toLowerCase() == 'ios') {
      return getIOSReceiptFormatParam(detectReceiptFormat(receipt));
    }
    return 'google_play';
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

  /// 이 빌드가 파싱할 수 있는 정산 계약 확장.
  ///
  /// 서버는 이 목록을 보고 응답에 `currency`/`value` 를 넣을지 정한다. build
  /// number 로 추론하지 않는 이유는 Shorebird OTA 가 build number 를 바꾸지
  /// 않기 때문이다 — OTA 로 새 파서를 받은 기기와 아직 안 받은 기기가 서버에는
  /// 같은 build 로 보인다. 파서 코드 자체가 아는 사실을 매 요청 선언한다.
  ///
  /// 이 값은 인박스에 영속 저장되지 않는 순수 요청 파라미터이며, 서버의 멱등
  /// identity hash 에도 들어가지 않는다.
  static const List<String> parserCapabilities = <String>['purchase_revenue_v1'];

  /// Build the iOS verification request body.
  @visibleForTesting
  static Map<String, dynamic> buildIOSRequestBody({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String receiptFormat,
    String? clientObservedCurrency,
  }) {
    return {
      'receipt': receipt,
      'platform': 'ios',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': getIOSReceiptFormatParam(receiptFormat),
      'parser_capabilities': parserCapabilities,
      'client_observed_currency': ?clientObservedCurrency,
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
    String? clientObservedCurrency,
  }) {
    return {
      'receipt': receipt,
      'platform': 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': 'google_play',
      'client_trace_id': clientTraceId,
      'parser_capabilities': parserCapabilities,
      'client_observed_currency': ?clientObservedCurrency,
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
