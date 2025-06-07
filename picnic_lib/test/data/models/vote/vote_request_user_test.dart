import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_request_user.dart';

void main() {
  group('VoteRequestUser 모델 테스트', () {
    late VoteRequestUser testVoteRequestUser;
    late Map<String, dynamic> testJson;

    setUp(() {
      testVoteRequestUser = VoteRequestUser(
        id: 'user-id-123',
        voteRequestId: 'request-id-456',
        userId: 'user-uuid-789',
        status: 'pending',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      testJson = {
        'id': 'user-id-123',
        'vote_request_id': 'request-id-456',
        'user_id': 'user-uuid-789',
        'status': 'pending',
        'created_at': '2025-06-07T01:00:00.000Z',
        'updated_at': '2025-06-07T01:30:00.000Z',
      };
    });

    test('VoteRequestUser 객체 생성 테스트', () {
      expect(testVoteRequestUser.id, equals('user-id-123'));
      expect(testVoteRequestUser.voteRequestId, equals('request-id-456'));
      expect(testVoteRequestUser.userId, equals('user-uuid-789'));
      expect(testVoteRequestUser.status, equals('pending'));
      expect(testVoteRequestUser.createdAt, equals(DateTime.parse('2025-06-07T01:00:00.000Z')));
      expect(testVoteRequestUser.updatedAt, equals(DateTime.parse('2025-06-07T01:30:00.000Z')));
    });

    test('JSON에서 VoteRequestUser 객체로 변환 테스트 (fromJson)', () {
      final voteRequestUser = VoteRequestUser.fromJson(testJson);

      expect(voteRequestUser.id, equals('user-id-123'));
      expect(voteRequestUser.voteRequestId, equals('request-id-456'));
      expect(voteRequestUser.userId, equals('user-uuid-789'));
      expect(voteRequestUser.status, equals('pending'));
      expect(voteRequestUser.createdAt, equals(DateTime.parse('2025-06-07T01:00:00.000Z')));
      expect(voteRequestUser.updatedAt, equals(DateTime.parse('2025-06-07T01:30:00.000Z')));
    });

    test('VoteRequestUser 객체에서 JSON으로 변환 테스트 (toJson)', () {
      final json = testVoteRequestUser.toJson();

      expect(json['id'], equals('user-id-123'));
      expect(json['vote_request_id'], equals('request-id-456'));
      expect(json['user_id'], equals('user-uuid-789'));
      expect(json['status'], equals('pending'));
      expect(json['created_at'], equals('2025-06-07T01:00:00.000Z'));
      expect(json['updated_at'], equals('2025-06-07T01:30:00.000Z'));
    });

    test('JSON 직렬화/역직렬화 라운드트립 테스트', () {
      final json = testVoteRequestUser.toJson();
      final reconstructed = VoteRequestUser.fromJson(json);

      expect(reconstructed, equals(testVoteRequestUser));
    });

    test('copyWith 메서드 테스트', () {
      final updatedVoteRequestUser = testVoteRequestUser.copyWith(
        status: 'approved',
        updatedAt: DateTime.parse('2025-06-07T02:00:00.000Z'),
      );

      expect(updatedVoteRequestUser.id, equals(testVoteRequestUser.id));
      expect(updatedVoteRequestUser.voteRequestId, equals(testVoteRequestUser.voteRequestId));
      expect(updatedVoteRequestUser.userId, equals(testVoteRequestUser.userId));
      expect(updatedVoteRequestUser.status, equals('approved'));
      expect(updatedVoteRequestUser.createdAt, equals(testVoteRequestUser.createdAt));
      expect(updatedVoteRequestUser.updatedAt, equals(DateTime.parse('2025-06-07T02:00:00.000Z')));
    });

    test('동등성 비교 테스트', () {
      final sameVoteRequestUser = VoteRequestUser(
        id: 'user-id-123',
        voteRequestId: 'request-id-456',
        userId: 'user-uuid-789',
        status: 'pending',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      final differentVoteRequestUser = VoteRequestUser(
        id: 'different-id',
        voteRequestId: 'request-id-456',
        userId: 'user-uuid-789',
        status: 'pending',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      expect(testVoteRequestUser, equals(sameVoteRequestUser));
      expect(testVoteRequestUser, isNot(equals(differentVoteRequestUser)));
    });

    test('hashCode 테스트', () {
      final sameVoteRequestUser = VoteRequestUser(
        id: 'user-id-123',
        voteRequestId: 'request-id-456',
        userId: 'user-uuid-789',
        status: 'pending',
        createdAt: DateTime.parse('2025-06-07T01:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-07T01:30:00.000Z'),
      );

      expect(testVoteRequestUser.hashCode, equals(sameVoteRequestUser.hashCode));
    });

    test('toString 메서드 테스트', () {
      final stringRepresentation = testVoteRequestUser.toString();
      
      expect(stringRepresentation, contains('VoteRequestUser'));
      expect(stringRepresentation, contains('user-id-123'));
      expect(stringRepresentation, contains('request-id-456'));
      expect(stringRepresentation, contains('pending'));
    });

    group('상태 값 테스트', () {
      test('다양한 상태 값으로 객체 생성', () {
        final statuses = ['pending', 'approved', 'rejected', 'in-progress', 'cancelled'];
        
        for (final status in statuses) {
          final voteRequestUser = testVoteRequestUser.copyWith(status: status);
          expect(voteRequestUser.status, equals(status));
        }
      });
    });

    group('잘못된 JSON 데이터 처리 테스트', () {
      test('필수 필드 누락 시 예외 발생', () {
        final incompleteJson = {
          'id': 'user-id-123',
          // vote_request_id 누락
          'user_id': 'user-uuid-789',
          'status': 'pending',
          'created_at': '2025-06-07T01:00:00.000Z',
          'updated_at': '2025-06-07T01:30:00.000Z',
        };

        expect(() => VoteRequestUser.fromJson(incompleteJson), throwsA(isA<Exception>()));
      });

      test('잘못된 날짜 형식 처리', () {
        final invalidDateJson = {
          'id': 'user-id-123',
          'vote_request_id': 'request-id-456',
          'user_id': 'user-uuid-789',
          'status': 'pending',
          'created_at': 'invalid-date',
          'updated_at': '2025-06-07T01:30:00.000Z',
        };

        expect(() => VoteRequestUser.fromJson(invalidDateJson), throwsA(isA<Exception>()));
      });
    });
  });
} 