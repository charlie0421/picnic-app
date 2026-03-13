import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';

VoteItemModel _item({required int id, int voteTotal = 0}) {
  return VoteItemModel.fromJson({
    'id': id,
    'vote_id': 1,
    'vote_total': voteTotal,
    'artist': {
      'id': id,
      'name': {'ko': 'Artist$id'},
      'image': null,
      'artist_group': {'id': 1, 'name': {'ko': 'Group'}, 'image': null},
    },
    'artist_group': null,
  });
}

VoteItemModel _itemWithGroup({required int id}) {
  return VoteItemModel.fromJson({
    'id': id,
    'vote_id': 1,
    'vote_total': 0,
    'artist': {'id': 0, 'name': {'ko': ''}, 'image': null, 'artist_group': null},
    'artist_group': {'id': id, 'name': {'ko': 'Group$id'}, 'image': 'group_img.png'},
  });
}

void main() {
  group('VoteInfoCardHelper.prepareVoteItems', () {
    test('returns empty list when rawItems is null', () {
      final result = VoteInfoCardHelper.prepareVoteItems(null, VoteStatus.active);
      expect(result, isEmpty);
    });

    test('returns empty list when rawItems is empty', () {
      final result = VoteInfoCardHelper.prepareVoteItems([], VoteStatus.active);
      expect(result, isEmpty);
    });

    test('sorts items by voteTotal descending', () {
      final items = [
        _item(id: 1, voteTotal: 100),
        _item(id: 2, voteTotal: 500),
        _item(id: 3, voteTotal: 300),
      ];

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.active);
      expect(result.map((e) => e.voteTotal), [500, 300, 100]);
    });

    test('truncates to top 3 for active status', () {
      final items = List.generate(5, (i) => _item(id: i + 1, voteTotal: (5 - i) * 100));

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.active);
      expect(result.length, 3);
      expect(result.first.voteTotal, 500);
    });

    test('truncates to top 3 for end status', () {
      final items = List.generate(5, (i) => _item(id: i + 1, voteTotal: (5 - i) * 100));

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.end);
      expect(result.length, 3);
    });

    test('returns all items for upcoming status', () {
      final items = List.generate(5, (i) => _item(id: i + 1, voteTotal: (5 - i) * 100));

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.upcoming);
      expect(result.length, 5);
      // Still sorted
      expect(result.first.voteTotal, 500);
      expect(result.last.voteTotal, 100);
    });

    test('returns all items when 3 or fewer for active status', () {
      final items = [
        _item(id: 1, voteTotal: 100),
        _item(id: 2, voteTotal: 200),
      ];

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.active);
      expect(result.length, 2);
    });

    test('handles null voteTotal values', () {
      final items = [
        _item(id: 1, voteTotal: 0), // null maps to 0
        _item(id: 2, voteTotal: 500),
      ];

      final result = VoteInfoCardHelper.prepareVoteItems(items, VoteStatus.active);
      expect(result.first.voteTotal, 500);
    });
  });

  group('VoteInfoCardHelper.paginateItems', () {
    test('returns empty list for empty input', () {
      expect(VoteInfoCardHelper.paginateItems<int>([], 12), isEmpty);
    });

    test('returns single page when items fit', () {
      final result = VoteInfoCardHelper.paginateItems([1, 2, 3], 12);
      expect(result.length, 1);
      expect(result.first, [1, 2, 3]);
    });

    test('splits into multiple pages correctly', () {
      final items = List.generate(25, (i) => i);
      final result = VoteInfoCardHelper.paginateItems(items, 12);
      expect(result.length, 3);
      expect(result[0].length, 12);
      expect(result[1].length, 12);
      expect(result[2].length, 1);
    });

    test('handles exact page boundary', () {
      final items = List.generate(24, (i) => i);
      final result = VoteInfoCardHelper.paginateItems(items, 12);
      expect(result.length, 2);
      expect(result[0].length, 12);
      expect(result[1].length, 12);
    });
  });

  group('VoteInfoCardHelper.padWithNulls', () {
    test('pads short list with nulls', () {
      final result = VoteInfoCardHelper.padWithNulls([1, 2], 3);
      expect(result, [1, 2, null]);
    });

    test('does not pad when list is already target length', () {
      final result = VoteInfoCardHelper.padWithNulls([1, 2, 3], 3);
      expect(result, [1, 2, 3]);
    });

    test('truncates list longer than target', () {
      final result = VoteInfoCardHelper.padWithNulls([1, 2, 3, 4, 5], 3);
      expect(result, [1, 2, 3]);
    });

    test('all nulls for empty list', () {
      final result = VoteInfoCardHelper.padWithNulls<int>([], 3);
      expect(result, [null, null, null]);
    });
  });

  group('VoteInfoCardHelper.resolveVoteItemImageUrl', () {
    test('returns artist image when artist.id != 0', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 0,
        'artist': {
          'id': 10,
          'name': {'ko': 'Test'},
          'image': 'artist_img.png',
          'artist_group': null,
        },
        'artist_group': {'id': 1, 'name': {'ko': 'G'}, 'image': 'group_img.png'},
      });
      expect(VoteInfoCardHelper.resolveVoteItemImageUrl(item), 'artist_img.png');
    });

    test('returns group image when artist.id is 0', () {
      final item = _itemWithGroup(id: 5);
      expect(VoteInfoCardHelper.resolveVoteItemImageUrl(item), 'group_img.png');
    });

    test('returns empty string when both images are null', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 0,
        'artist': {
          'id': 0,
          'name': {'ko': ''},
          'image': null,
          'artist_group': null,
        },
        'artist_group': {'id': 1, 'name': {'ko': 'G'}, 'image': null},
      });
      expect(VoteInfoCardHelper.resolveVoteItemImageUrl(item), '');
    });
  });
}
