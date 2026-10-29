import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A StoreKit 2 sandbox purchase that the server settled on this device.
///
/// The admin refund test tool opens Apple's refund request sheet for it.
/// StoreKit does not return finished consumables from its own history, so the
/// app keeps the identifier when the server settles the purchase.
@immutable
class SandboxRefundCandidate {
  const SandboxRefundCandidate({
    required this.transactionId,
    required this.productId,
    required this.purchasedAt,
  });

  /// StoreKit 2 `Transaction.id`: a decimal UInt64, at most 20 digits.
  static final RegExp _transactionIdPattern = RegExp(r'^[0-9]{6,20}$');

  final String transactionId;
  final String productId;
  final DateTime purchasedAt;

  /// Reads the payload of a StoreKit 2 JWS that the server already settled.
  ///
  /// Returns null unless Apple signed the transaction for the sandbox
  /// (`environment == "Sandbox"`). Production and Xcode transactions never
  /// become candidates, so the tool cannot open a real refund request.
  static SandboxRefundCandidate? fromVerifiedJws(String jws) {
    try {
      final parts = jws.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      if (payload['environment'] != 'Sandbox') return null;
      final purchaseDate = payload['purchaseDate'];
      if (purchaseDate is! int) return null;
      return _validated(
        transactionId: payload['transactionId'],
        productId: payload['productId'],
        purchasedAt: DateTime.fromMillisecondsSinceEpoch(
          purchaseDate,
          isUtc: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static SandboxRefundCandidate? fromJson(Object? json) {
    if (json is! Map) return null;
    final purchasedAt = DateTime.tryParse('${json['purchasedAt']}');
    if (purchasedAt == null) return null;
    return _validated(
      transactionId: json['transactionId'],
      productId: json['productId'],
      purchasedAt: purchasedAt.toUtc(),
    );
  }

  static SandboxRefundCandidate? _validated({
    required Object? transactionId,
    required Object? productId,
    required DateTime purchasedAt,
  }) {
    if (transactionId is! String ||
        !_transactionIdPattern.hasMatch(transactionId)) {
      return null;
    }
    if (productId is! String || productId.isEmpty) return null;
    return SandboxRefundCandidate(
      transactionId: transactionId,
      productId: productId,
      purchasedAt: purchasedAt,
    );
  }

  Map<String, Object> toJson() => {
    'transactionId': transactionId,
    'productId': productId,
    'purchasedAt': purchasedAt.toUtc().toIso8601String(),
  };
}

/// Keeps the newest sandbox purchases this device settled, for the admin
/// refund test tool. Production purchases are never written.
class SandboxRefundCandidateStore {
  SandboxRefundCandidateStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const String preferencesKey = 'sandbox_refund_candidates_v1';
  static const int maxCandidates = 20;

  final Future<SharedPreferences> Function() _preferences;

  /// Records a receipt that the server settled. Never throws: this record is
  /// a test aid and must not affect the purchase settlement.
  Future<void> recordVerifiedReceipt(String receipt) async {
    final candidate = SandboxRefundCandidate.fromVerifiedJws(receipt);
    if (candidate == null) return;
    try {
      final preferences = await _preferences();
      final kept = _decode(
        preferences.getString(preferencesKey),
      ).where((c) => c.transactionId != candidate.transactionId);
      await preferences.setString(
        preferencesKey,
        jsonEncode(
          [
            candidate,
            ...kept,
          ].take(maxCandidates).map((c) => c.toJson()).toList(),
        ),
      );
    } catch (e) {
      logger.w('sandbox 환불 후보 기록 실패(정산과 무관): $e');
    }
  }

  /// Newest first. Returns an empty list when storage is unavailable.
  Future<List<SandboxRefundCandidate>> load() async {
    try {
      final preferences = await _preferences();
      return _decode(preferences.getString(preferencesKey));
    } catch (e) {
      logger.w('sandbox 환불 후보 읽기 실패: $e');
      return const [];
    }
  }

  Future<void> remove(String transactionId) async {
    try {
      final preferences = await _preferences();
      final kept = _decode(preferences.getString(preferencesKey))
          .where((c) => c.transactionId != transactionId)
          .map((c) => c.toJson())
          .toList();
      await preferences.setString(preferencesKey, jsonEncode(kept));
    } catch (e) {
      logger.w('sandbox 환불 후보 삭제 실패: $e');
    }
  }

  static List<SandboxRefundCandidate> _decode(String? stored) {
    if (stored == null) return const [];
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return const [];
      return decoded
          .map(SandboxRefundCandidate.fromJson)
          .whereType<SandboxRefundCandidate>()
          .toList();
    } on FormatException {
      return const [];
    }
  }
}
