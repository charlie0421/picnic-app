import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/sandbox_refund_candidate_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

Map<String, dynamic> _purchaseResult() => {
  'contract_version': 'wallet.v1',
  'operation_id': '00000000-0000-4000-8000-000000000001',
  'replayed': false,
  'base_star_amount': '100',
  'base_bonus_amount': '20',
  'promotion': {
    'resolution_id': '00000000-0000-4000-8000-000000000002',
    'state': 'INELIGIBLE',
    'campaign_version_id': null,
    'promo_bonus_amount': '0',
    'domain_code': null,
  },
  'wallet': {
    'contract_version': 'wallet.v1',
    'star': '100',
    'bonus': '20',
    'cotton': '5',
    'cotton_expiring_amount': '5',
    'cotton_next_expires_at': null,
    'snapshot_at': '2026-07-21T00:00:00.000Z',
  },
};

String _sandboxJws() {
  final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'transactionId': '2000000123456789',
        'productId': 'STAR100',
        'purchaseDate': 1761700000000,
        'environment': 'Sandbox',
        'signedDate': 1761700000500,
      }),
    ),
  );
  return '$header.$payload.signature';
}

/// Records every receipt the service hands over, without touching storage.
class _RecordingCandidateStore extends SandboxRefundCandidateStore {
  final receipts = <String>[];

  @override
  Future<void> recordVerifiedReceipt(String receipt) async {
    receipts.add(receipt);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('hands a settled iOS receipt to the sandbox refund tool', () async {
    setupMockSupabase({
      'functions:verify-receipt-v2': _purchaseResult(),
    }, userId: 'test-user-id');
    final candidates = _RecordingCandidateStore();
    final service = ReceiptVerificationService()
      ..isIOSPlatform = true
      ..sandboxRefundCandidates = candidates;
    final receipt = _sandboxJws();

    await service.verifyReceipt(receipt, 'STAR100', 'test-user-id', 'sandbox');

    expect(candidates.receipts, [receipt]);
  });

  test('does not record Android settlements', () async {
    setupMockSupabase({
      'functions:verify-receipt-v2': _purchaseResult(),
    }, userId: 'test-user-id');
    final candidates = _RecordingCandidateStore();
    final service = ReceiptVerificationService()
      ..isIOSPlatform = false
      ..sandboxRefundCandidates = candidates;

    await service.verifyReceipt(
      'android-purchase-token',
      'STAR100',
      'test-user-id',
      'production',
    );

    expect(candidates.receipts, isEmpty);
  });

  test('does not record a receipt the server did not settle', () async {
    setupMockSupabase({
      'functions:verify-receipt-v2': _purchaseResult()..['promotion'] = null,
    }, userId: 'test-user-id');
    final candidates = _RecordingCandidateStore();
    final service = ReceiptVerificationService()
      ..isIOSPlatform = true
      ..sandboxRefundCandidates = candidates;

    await expectLater(
      service.verifyReceipt(
        _sandboxJws(),
        'STAR100',
        'test-user-id',
        'sandbox',
      ),
      throwsA(isA<ReceiptResponseContractException>()),
    );
    expect(candidates.receipts, isEmpty);
  });
}
