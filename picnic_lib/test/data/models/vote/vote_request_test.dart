import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_request.dart';

void main() {
  group('VoteRequest 모델 테스트', () {
    late VoteRequest testVoteRequest;
    late Map<String, dynamic> testJson;

    setUp(() {
      testVoteRequest = VoteRequest(
        id: 'test-id-123',
        voteId: 'vote-id-456',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      testJson = {
        'id': 'test-id-123',
        'vote_id': 'vote-id-456',
        'created_at': '2025-06-07T01:00:00.000Z',
        'updated_at': '2025-06-07T01:30:00.000Z',
      };
    });

    test('VoteRequest 객체 생성 테스트', () {
      expect(testVoteRequest.id, equals('test-id-123'));
      expect(testVoteRequest.voteId, equals('vote-id-456'));
      expect(testVoteRequest.createdAt,
          equals(DateTime.parse('2025-06-07T01:00:00.000Z')));
      expect(testVoteRequest.updatedAt,
          equals(DateTime.parse('2025-06-07T01:30:00.000Z')));
    });

    test('JSON에서 VoteRequest 객체로 변환 테스트 (fromJson)', () {
      final voteRequest = VoteRequest.fromJson(testJson);

      expect(voteRequest.id, equals('test-id-123'));
      expect(voteRequest.voteId, equals('vote-id-456'));
      expect(voteRequest.createdAt,
          equals(DateTime.parse('2025-06-07T01:00:00.000Z')));
      expect(voteRequest.updatedAt,
          equals(DateTime.parse('2025-06-07T01:30:00.000Z')));
    });

    test('VoteRequest 객체에서 JSON으로 변환 테스트 (toJson)', () {
      final json = testVoteRequest.toJson();

      expect(json['id'], equals('test-id-123'));
      expect(json['vote_id'], equals('vote-id-456'));
      expect(json['created_at'], equals('2025-06-07T01:00:00.000Z'));
      expect(json['updated_at'], equals('2025-06-07T01:30:00.000Z'));
    });

    test('JSON 직렬화/역직렬화 라운드트립 테스트', () {
      final json = testVoteRequest.toJson();
      final reconstructed = VoteRequest.fromJson(json);

      expect(reconstructed, equals(testVoteRequest));
    });

    test('copyWith 메서드 테스트', () {
      final updatedVoteRequest = testVoteRequest.copyWith();

      expect(updatedVoteRequest.id, equals(testVoteRequest.id));
      expect(updatedVoteRequest.voteId, equals(testVoteRequest.voteId));
      expect(updatedVoteRequest.createdAt, equals(testVoteRequest.createdAt));
      expect(updatedVoteRequest.updatedAt, equals(testVoteRequest.updatedAt));
    });

    test('동등성 비교 테스트', () {
      final sameVoteRequest = VoteRequest(
        id: 'test-id-123',
        voteId: 'vote-id-456',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      final differentVoteRequest = VoteRequest(
        id: 'different-id',
        voteId: 'vote-id-456',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      expect(testVoteRequest, equals(sameVoteRequest));
      expect(testVoteRequest, isNot(equals(differentVoteRequest)));
    });

    test('hashCode 테스트', () {
      final sameVoteRequest = VoteRequest(
        id: 'test-id-123',
        voteId: 'vote-id-456',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      expect(testVoteRequest.hashCode, equals(sameVoteRequest.hashCode));
    });

    test('toString 메서드 테스트', () {
      final stringRepresentation = testVoteRequest.toString();

      expect(stringRepresentation, contains('VoteRequest'));
      expect(stringRepresentation, contains('test-id-123'));
      expect(stringRepresentation, contains('vote-id-456'));
      expect(stringRepresentation, contains('테스트 투표 요청'));
    });

    group('잘못된 JSON 데이터 처리 테스트', () {
      test('필수 필드 누락 시 예외 발생', () {
        final incompleteJson = {
          'id': 'test-id-123',
          // vote_id 누락
          'created_at': '2025-06-07T01:00:00.000Z',
          'updated_at': '2025-06-07T01:30:00.000Z',
        };

        expect(() => VoteRequest.fromJson(incompleteJson),
            throwsA(isA<Exception>()));
      });

      test('잘못된 날짜 형식 처리', () {
        final invalidDateJson = {
          'id': 'test-id-123',
          'vote_id': 'vote-id-456',
          'title': '테스트 투표 요청',
          'description': '테스트용 투표 요청 설명입니다.',
          'created_at': 'invalid-date',
          'updated_at': '2025-06-07T01:30:00.000Z',
        };

        expect(() => VoteRequest.fromJson(invalidDateJson),
            throwsA(isA<Exception>()));
      });
    });
  });
}
