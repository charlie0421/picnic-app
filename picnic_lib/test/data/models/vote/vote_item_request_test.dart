import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request.dart';

void main() {
  group('VoteItemRequest 모델 테스트', () {
    late VoteItemRequest testVoteItemRequest;
    late Map<String, dynamic> testJson;

    setUp(() {
      testVoteItemRequest = VoteItemRequest(
        id: 'test-id-123',
        voteId: 456,
        status: 'pending',
        createdAt: DateTime.parse('2025-06-08T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-08T01:30:00.000Z'),
      );

      testJson = {
        'id': 'test-id-123',
        'vote_id': 456,
        'status': 'pending',
        'created_at': '2025-06-08T01:00:00.000Z',
        'updated_at': '2025-06-08T01:30:00.000Z',
      };
    });

    test('VoteItemRequest 객체 생성 테스트', () {
      expect(testVoteItemRequest.id, equals('test-id-123'));
      expect(testVoteItemRequest.voteId, equals(456));
      expect(testVoteItemRequest.status, equals('pending'));
      expect(testVoteItemRequest.createdAt,
          equals(DateTime.parse('2025-06-08T01:00:00.000Z')));
      expect(testVoteItemRequest.updatedAt,
          equals(DateTime.parse('2025-06-08T01:30:00.000Z')));
    });

    test('JSON에서 VoteItemRequest 객체로 변환 테스트 (fromJson)', () {
      final voteItemRequest = VoteItemRequest.fromJson(testJson);

      expect(voteItemRequest.id, equals('test-id-123'));
      expect(voteItemRequest.voteId, equals(456));
      expect(voteItemRequest.status, equals('pending'));
      expect(voteItemRequest.createdAt,
          equals(DateTime.parse('2025-06-08T01:00:00.000Z')));
      expect(voteItemRequest.updatedAt,
          equals(DateTime.parse('2025-06-08T01:30:00.000Z')));
    });

    test('VoteItemRequest 객체에서 JSON으로 변환 테스트 (toJson)', () {
      final json = testVoteItemRequest.toJson();

      expect(json['id'], equals('test-id-123'));
      expect(json['vote_id'], equals(456));
      expect(json['status'], equals('pending'));
      expect(json['created_at'], equals('2025-06-08T01:00:00.000Z'));
      expect(json['updated_at'], equals('2025-06-08T01:30:00.000Z'));
    });

    test('VoteItemRequest 객체 동등성 테스트', () {
      final sameVoteItemRequest = VoteItemRequest(
        id: 'test-id-123',
        voteId: 456,
        status: 'pending',
        createdAt: DateTime.parse('2025-06-08T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-08T01:30:00.000Z'),
      );

      final differentVoteItemRequest = VoteItemRequest(
        id: 'different-id',
        voteId: 456,
        status: 'pending',
        createdAt: DateTime.parse('2025-06-08T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-08T01:30:00.000Z'),
      );

      expect(testVoteItemRequest, equals(sameVoteItemRequest));
      expect(testVoteItemRequest, isNot(equals(differentVoteItemRequest)));
    });

    test('VoteItemRequest copyWith 테스트', () {
      final copiedVoteItemRequest = testVoteItemRequest.copyWith(
        status: 'approved',
      );

      expect(copiedVoteItemRequest.id, equals(testVoteItemRequest.id));
      expect(copiedVoteItemRequest.voteId, equals(testVoteItemRequest.voteId));
      expect(copiedVoteItemRequest.status, equals('approved'));
      expect(copiedVoteItemRequest.createdAt,
          equals(testVoteItemRequest.createdAt));
      expect(copiedVoteItemRequest.updatedAt,
          equals(testVoteItemRequest.updatedAt));
    });

    test('VoteItemRequest toString 테스트', () {
      final stringRepresentation = testVoteItemRequest.toString();
      expect(stringRepresentation, contains('VoteItemRequest'));
      expect(stringRepresentation, contains('test-id-123'));
      expect(stringRepresentation, contains('456'));
      expect(stringRepresentation, contains('pending'));
    });
  });
}
