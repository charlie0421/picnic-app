import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';

void main() {
  group('ArtistVoteModel', () {
    test('creates from constructor', () {
      final now = DateTime.now();
      final model = ArtistVoteModel(
        id: 1,
        title: {'ko': '투표'},
        category: 'music',
        artistVoteItem: null,
        createdAt: now,
        updatedAt: now,
        visibleAt: now,
        stopAt: now.add(const Duration(days: 7)),
        startAt: now,
      );
      expect(model.id, 1);
      expect(model.title['ko'], '투표');
      expect(model.category, 'music');
      expect(model.artistVoteItem, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'title': {'ko': 'test'},
        'category': 'music',
        'artist_vote_item': null,
        'created_at': '2025-01-15T00:00:00.000Z',
        'updated_at': null,
        'visible_at': null,
        'stop_at': '2025-01-22T00:00:00.000Z',
        'start_at': '2025-01-15T00:00:00.000Z',
      };
      final model = ArtistVoteModel.fromJson(json);
      expect(model.id, 1);
      expect(model.category, 'music');
    });

    test('copyWith updates fields', () {
      final now = DateTime.now();
      final model = ArtistVoteModel(
        id: 1,
        title: {'ko': '원래'},
        category: 'music',
        artistVoteItem: null,
        createdAt: now,
        updatedAt: now,
        visibleAt: now,
        stopAt: now.add(const Duration(days: 7)),
        startAt: now,
      );
      final updated = model.copyWith(category: 'drama');
      expect(updated.category, 'drama');
      expect(updated.id, 1);
    });
  });

  group('ArtistVoteItemModel', () {
    test('creates from constructor', () {
      const model = ArtistVoteItemModel(
        id: 1,
        voteTotal: 1000,
        artistVoteId: 10,
        title: {'ko': '항목1'},
        description: {'ko': '설명'},
      );
      expect(model.id, 1);
      expect(model.voteTotal, 1000);
      expect(model.artistVoteId, 10);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'vote_total': 500,
        'artist_vote_id': 10,
        'title': {'ko': 'item'},
        'description': {'ko': 'desc'},
      };
      final model = ArtistVoteItemModel.fromJson(json);
      expect(model.id, 1);
      expect(model.voteTotal, 500);
    });
  });

  group('MyStarMemberModel', () {
    test('creates from constructor', () {
      const model = MyStarMemberModel(
        id: 1,
        nameKo: '아이유',
        nameEn: 'IU',
        gender: 'female',
        image: null,
      );
      expect(model.id, 1);
      expect(model.nameKo, '아이유');
      expect(model.nameEn, 'IU');
      expect(model.gender, 'female');
      expect(model.mystarGroup, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name_ko': '아이유',
        'name_en': 'IU',
        'gender': 'female',
        'image': 'img.jpg',
      };
      final model = MyStarMemberModel.fromJson(json);
      expect(model.id, 1);
      expect(model.image, 'img.jpg');
    });
  });

  group('MyStarGroupModel', () {
    test('creates from constructor', () {
      const model = MyStarGroupModel(
        id: 1,
        nameKo: 'BTS',
        nameEn: 'BTS',
      );
      expect(model.id, 1);
      expect(model.nameKo, 'BTS');
      expect(model.image, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name_ko': 'BTS',
        'name_en': 'BTS',
        'image': 'group.jpg',
      };
      final model = MyStarGroupModel.fromJson(json);
      expect(model.id, 1);
      expect(model.image, 'group.jpg');
    });
  });

  group('ArtistMemberModel (artist_vote)', () {
    test('creates from constructor', () {
      const model = ArtistMemberModel(
        id: 1,
        name: {'ko': '멤버', 'en': 'Member'},
        gender: 'male',
        image: null,
      );
      expect(model.id, 1);
      expect(model.name['ko'], '멤버');
      expect(model.artistGroup, isNull);
    });
  });
}
