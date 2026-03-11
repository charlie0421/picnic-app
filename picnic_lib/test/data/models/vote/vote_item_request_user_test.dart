import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';

void main() {
  group('VoteItemRequestUser', () {
    test('필수 필드로 생성', () {
      final user = VoteItemRequestUser(
        id: 'req-1',
        voteId: 100,
        userId: 'user-abc',
        artistId: 42,
        status: 'pending',
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );
      expect(user.id, equals('req-1'));
      expect(user.voteId, equals(100));
      expect(user.userId, equals('user-abc'));
      expect(user.artistId, equals(42));
      expect(user.status, equals('pending'));
      expect(user.artist, isNull);
    });

    test('아티스트 정보 없이 approved 상태', () {
      final user = VoteItemRequestUser(
        id: 'req-2',
        voteId: 200,
        userId: 'user-xyz',
        artistId: 99,
        status: 'approved',
        createdAt: DateTime(2025, 2, 1),
        updatedAt: DateTime(2025, 3, 10),
      );
      expect(user.status, equals('approved'));
      expect(user.updatedAt.isAfter(user.createdAt), isTrue);
    });
  });
}
