import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/sandbox_refund_candidate_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _purchaseDateMs = 1761700000000;

Map<String, Object?> _payload({
  String transactionId = '2000000123456789',
  String? productId = 'STAR100',
  Object? purchaseDate = _purchaseDateMs,
  String? environment = 'Sandbox',
}) => {
  'transactionId': transactionId,
  'productId': ?productId,
  'purchaseDate': ?purchaseDate,
  'environment': ?environment,
};

String _jws(Map<String, Object?> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.signature';
}

void main() {
  group('SandboxRefundCandidate.fromVerifiedJws', () {
    test(
      'reads a StoreKit 2 transaction that Apple signed for the sandbox',
      () {
        final candidate = SandboxRefundCandidate.fromVerifiedJws(
          _jws(_payload()),
        );

        expect(candidate, isNotNull);
        expect(candidate!.transactionId, '2000000123456789');
        expect(candidate.productId, 'STAR100');
        expect(
          candidate.purchasedAt,
          DateTime.fromMillisecondsSinceEpoch(_purchaseDateMs, isUtc: true),
        );
      },
    );

    test('ignores production, Xcode and unlabelled transactions', () {
      for (final environment in ['Production', 'Xcode', 'sandbox', null]) {
        expect(
          SandboxRefundCandidate.fromVerifiedJws(
            _jws(_payload(environment: environment)),
          ),
          isNull,
          reason: 'environment=$environment 는 sandbox 환불 대상이 아니다',
        );
      }
    });

    test('ignores malformed receipts and identifiers', () {
      final rejected = <String>[
        '',
        'not-a-jws',
        'only.two',
        'a.%%%.c',
        _jws(_payload(transactionId: 'abc123456789')),
        _jws(_payload(transactionId: '12345')),
        _jws(_payload(transactionId: '123456789012345678901')),
        _jws(_payload(productId: null)),
        _jws(_payload(productId: '')),
        _jws(_payload(purchaseDate: null)),
        _jws(_payload(purchaseDate: '2026-10-29')),
      ];
      for (final receipt in rejected) {
        expect(
          SandboxRefundCandidate.fromVerifiedJws(receipt),
          isNull,
          reason: receipt,
        );
      }
    });
  });

  group('SandboxRefundCandidateStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('records sandbox purchases newest first without duplicates', () async {
      final store = SandboxRefundCandidateStore();

      await store.recordVerifiedReceipt(
        _jws(_payload(transactionId: '2000000000000001')),
      );
      await store.recordVerifiedReceipt(
        _jws(_payload(transactionId: '2000000000000002')),
      );
      await store.recordVerifiedReceipt(
        _jws(_payload(transactionId: '2000000000000001')),
      );

      final ids = (await store.load()).map((c) => c.transactionId).toList();
      expect(ids, ['2000000000000001', '2000000000000002']);
    });

    test('keeps only the newest purchases', () async {
      final store = SandboxRefundCandidateStore();
      final total = SandboxRefundCandidateStore.maxCandidates + 3;

      for (var i = 0; i < total; i++) {
        await store.recordVerifiedReceipt(
          _jws(_payload(transactionId: '${2000000000000000 + i}')),
        );
      }

      final ids = (await store.load()).map((c) => c.transactionId).toList();
      expect(ids.length, SandboxRefundCandidateStore.maxCandidates);
      expect(ids.first, '${2000000000000000 + total - 1}');
      expect(ids.contains('2000000000000000'), isFalse);
    });

    test('writes nothing for a production purchase', () async {
      final store = SandboxRefundCandidateStore();

      await store.recordVerifiedReceipt(
        _jws(_payload(environment: 'Production')),
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isEmpty);
    });

    test('swallows storage failures so settlement is unaffected', () async {
      final store = SandboxRefundCandidateStore(
        preferences: () async => throw StateError('storage unavailable'),
      );

      await expectLater(
        store.recordVerifiedReceipt(_jws(_payload())),
        completes,
      );
      expect(await store.load(), isEmpty);
    });

    test(
      'treats corrupt stored data as empty and skips invalid entries',
      () async {
        SharedPreferences.setMockInitialValues({
          SandboxRefundCandidateStore.preferencesKey: 'not json',
        });
        expect(await SandboxRefundCandidateStore().load(), isEmpty);

        SharedPreferences.setMockInitialValues({
          SandboxRefundCandidateStore.preferencesKey: jsonEncode([
            {'transactionId': 'abc', 'productId': 'STAR100'},
            {
              'transactionId': '2000000000000009',
              'productId': 'STAR100',
              'purchasedAt': '2026-10-29T00:00:00.000Z',
            },
          ]),
        });
        final ids = (await SandboxRefundCandidateStore().load())
            .map((c) => c.transactionId)
            .toList();
        expect(ids, ['2000000000000009']);
      },
    );

    test('removes a purchase after its refund request was submitted', () async {
      final store = SandboxRefundCandidateStore();
      await store.recordVerifiedReceipt(
        _jws(_payload(transactionId: '2000000000000001')),
      );
      await store.recordVerifiedReceipt(
        _jws(_payload(transactionId: '2000000000000002')),
      );

      await store.remove('2000000000000002');

      final ids = (await store.load()).map((c) => c.transactionId).toList();
      expect(ids, ['2000000000000001']);
    });
  });
}
