import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';

void main() {
  // ── Helper factories ──────────────────────────────────────────────────

  ArtistGroupModel _group({
    int id = 1,
    Map<String, dynamic>? name,
    String? image,
  }) =>
      ArtistGroupModel(
        id: id,
        name: name ?? {'ko': '그룹', 'en': 'Group'},
        image: image,
      );

  ArtistModel _artist({
    int id = 1,
    Map<String, dynamic>? name,
    ArtistGroupModel? artistGroup,
    String? image,
  }) =>
      ArtistModel(
        id: id,
        name: name ?? {'ko': '아티스트', 'en': 'Artist'},
        artistGroup: artistGroup,
        image: image,
      );

  VoteItemModel _item({
    required int id,
    int? voteTotal,
    ArtistModel? artist,
    ArtistGroupModel? artistGroup,
  }) =>
      VoteItemModel(
        id: id,
        voteTotal: voteTotal,
        voteId: 1,
        artist: artist,
        artistGroup: artistGroup,
      );

  // ── computeRanks ─────────────────────────────────────────────────────

  group('computeRanks', () {
    test('returns empty map for empty list', () {
      expect(VoteDetailHelper.computeRanks([]), isEmpty);
    });

    test('returns empty map for list of only nulls', () {
      expect(VoteDetailHelper.computeRanks([null, null]), isEmpty);
    });

    test('ranks single item as 1', () {
      final items = [_item(id: 10, voteTotal: 100)];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks, {10: 1});
    });

    test('ranks items in descending vote order', () {
      final items = [
        _item(id: 1, voteTotal: 10),
        _item(id: 2, voteTotal: 30),
        _item(id: 3, voteTotal: 20),
      ];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks[2], 1); // 30 votes
      expect(ranks[3], 2); // 20 votes
      expect(ranks[1], 3); // 10 votes
    });

    test('assigns same rank for tied items', () {
      final items = [
        _item(id: 1, voteTotal: 50),
        _item(id: 2, voteTotal: 50),
        _item(id: 3, voteTotal: 10),
      ];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 3); // skips rank 2
    });

    test('handles null voteTotals as 0', () {
      final items = [
        _item(id: 1, voteTotal: null),
        _item(id: 2, voteTotal: 5),
      ];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks[2], 1);
      expect(ranks[1], 2);
    });

    test('handles all items with same voteTotal', () {
      final items = [
        _item(id: 1, voteTotal: 10),
        _item(id: 2, voteTotal: 10),
        _item(id: 3, voteTotal: 10),
      ];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 1);
    });

    test('skips null items in the list', () {
      final items = [
        _item(id: 1, voteTotal: 20),
        null,
        _item(id: 3, voteTotal: 10),
      ];
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks.length, 2);
      expect(ranks[1], 1);
      expect(ranks[3], 2);
    });

    test('handles large list correctly', () {
      final items = List.generate(
        100,
        (i) => _item(id: i, voteTotal: 100 - i),
      );
      final ranks = VoteDetailHelper.computeRanks(items);
      expect(ranks[0], 1);
      expect(ranks[99], 100);
    });
  });

  // ── areDataListsEqual ─────────────────────────────────────────────────

  group('areDataListsEqual', () {
    test('returns true for two empty lists', () {
      expect(VoteDetailHelper.areDataListsEqual([], []), isTrue);
    });

    test('returns false for different lengths', () {
      expect(
        VoteDetailHelper.areDataListsEqual(
          [_item(id: 1, voteTotal: 5)],
          [],
        ),
        isFalse,
      );
    });

    test('returns true when both have null at same position', () {
      expect(
        VoteDetailHelper.areDataListsEqual([null], [null]),
        isTrue,
      );
    });

    test('returns false when one is null and other is not', () {
      expect(
        VoteDetailHelper.areDataListsEqual(
          [null],
          [_item(id: 1, voteTotal: 0)],
        ),
        isFalse,
      );
    });

    test('returns true for identical items', () {
      final a = _item(id: 1, voteTotal: 10);
      final b = _item(id: 1, voteTotal: 10);
      expect(VoteDetailHelper.areDataListsEqual([a], [b]), isTrue);
    });

    test('returns false when ids differ', () {
      final a = _item(id: 1, voteTotal: 10);
      final b = _item(id: 2, voteTotal: 10);
      expect(VoteDetailHelper.areDataListsEqual([a], [b]), isFalse);
    });

    test('returns false when voteTotals differ', () {
      final a = _item(id: 1, voteTotal: 10);
      final b = _item(id: 1, voteTotal: 20);
      expect(VoteDetailHelper.areDataListsEqual([a], [b]), isFalse);
    });

    test('returns true for multiple matching items', () {
      final list1 = [
        _item(id: 1, voteTotal: 10),
        null,
        _item(id: 3, voteTotal: 30),
      ];
      final list2 = [
        _item(id: 1, voteTotal: 10),
        null,
        _item(id: 3, voteTotal: 30),
      ];
      expect(VoteDetailHelper.areDataListsEqual(list1, list2), isTrue);
    });
  });

  // ── getMatchingText ───────────────────────────────────────────────────

  group('getMatchingText', () {
    test('returns Korean text when query matches Korean', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, '방탄'),
        '방탄소년단',
      );
    });

    test('returns English text when query matches English', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(VoteDetailHelper.getMatchingText(nameMap, 'bts'), 'BTS');
    });

    test('is case insensitive for English', () {
      final nameMap = {'ko': '아이유', 'en': 'IU'};
      expect(VoteDetailHelper.getMatchingText(nameMap, 'iu'), 'IU');
    });

    test('returns fallback when neither matches', () {
      final nameMap = {'ko': '트와이스', 'en': 'TWICE'};
      expect(
        VoteDetailHelper.getMatchingText(
          nameMap,
          'xyz',
          fallbackText: 'default',
        ),
        'default',
      );
    });

    test('returns empty string fallback by default', () {
      final nameMap = {'ko': '트와이스', 'en': 'TWICE'};
      expect(VoteDetailHelper.getMatchingText(nameMap, 'xyz'), '');
    });

    test('handles empty nameMap', () {
      expect(VoteDetailHelper.getMatchingText({}, 'test'), '');
    });

    test('handles missing ko key', () {
      final nameMap = {'en': 'Artist'};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, 'art'),
        'Artist',
      );
    });

    test('handles missing en key', () {
      final nameMap = {'ko': '아티스트'};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, '아티'),
        '아티스트',
      );
    });

    test('prefers Korean match over English', () {
      // Both would match, but Korean is checked first
      final nameMap = {'ko': 'test', 'en': 'test'};
      expect(VoteDetailHelper.getMatchingText(nameMap, 'test'), 'test');
    });
  });

  // ── makeFullImageUrl ──────────────────────────────────────────────────

  group('makeFullImageUrl', () {
    const cdnUrl = 'https://cdn.example.com';

    test('returns empty string for empty imageUrl', () {
      expect(VoteDetailHelper.makeFullImageUrl('', cdnUrl), '');
    });

    test('returns unchanged for http:// URL', () {
      const url = 'http://example.com/image.png';
      expect(VoteDetailHelper.makeFullImageUrl(url, cdnUrl), url);
    });

    test('returns unchanged for https:// URL', () {
      const url = 'https://example.com/image.png';
      expect(VoteDetailHelper.makeFullImageUrl(url, cdnUrl), url);
    });

    test('prepends CDN URL to relative path', () {
      expect(
        VoteDetailHelper.makeFullImageUrl('images/photo.png', cdnUrl),
        'https://cdn.example.com/images/photo.png',
      );
    });

    test('handles relative path with leading slash', () {
      expect(
        VoteDetailHelper.makeFullImageUrl('/images/photo.png', cdnUrl),
        'https://cdn.example.com/images/photo.png',
      );
    });

    test('handles CDN URL with trailing slash', () {
      expect(
        VoteDetailHelper.makeFullImageUrl(
          'images/photo.png',
          'https://cdn.example.com/',
        ),
        'https://cdn.example.com/images/photo.png',
      );
    });

    test('handles both leading slash on path and trailing slash on CDN', () {
      expect(
        VoteDetailHelper.makeFullImageUrl(
          '/images/photo.png',
          'https://cdn.example.com/',
        ),
        'https://cdn.example.com/images/photo.png',
      );
    });

    test('handles plain filename without directory', () {
      expect(
        VoteDetailHelper.makeFullImageUrl('photo.png', cdnUrl),
        'https://cdn.example.com/photo.png',
      );
    });
  });

  // ── getFilteredIndices ────────────────────────────────────────────────

  group('getFilteredIndices', () {
    test('returns all indices for empty query', () {
      final data = [
        _item(id: 1, voteTotal: 10),
        _item(id: 2, voteTotal: 20),
        _item(id: 3, voteTotal: 30),
      ];
      expect(
        VoteDetailHelper.getFilteredIndices(data, ''),
        [0, 1, 2],
      );
    });

    test('returns empty list when no items match', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(name: {'ko': '방탄소년단', 'en': 'BTS'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'xyz'), isEmpty);
    });

    test('matches artist Korean name', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(name: {'ko': '방탄소년단', 'en': 'BTS'}),
        ),
        _item(
          id: 2,
          voteTotal: 20,
          artist: _artist(id: 2, name: {'ko': '트와이스', 'en': 'TWICE'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, '방탄'), [0]);
    });

    test('matches artist English name (case insensitive)', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(name: {'ko': '방탄소년단', 'en': 'BTS'}),
        ),
        _item(
          id: 2,
          voteTotal: 20,
          artist: _artist(id: 2, name: {'ko': '트와이스', 'en': 'TWICE'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'twice'), [1]);
    });

    test('matches artist group name', () {
      final group = _group(name: {'ko': '에스엠', 'en': 'SM'});
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(
            name: {'ko': '보아', 'en': 'BoA'},
            artistGroup: group,
          ),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, '에스엠'), [0]);
    });

    test('matches direct artistGroup (no artist)', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: null,
          artistGroup: _group(name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'black'), [0]);
    });

    test('skips null items gracefully', () {
      final data = <VoteItemModel?>[
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(name: {'ko': '아이유', 'en': 'IU'}),
        ),
        null,
      ];
      // null item should not crash; only index 0 should match
      expect(VoteDetailHelper.getFilteredIndices(data, 'IU'), [0]);
    });

    test('returns all indices for empty query with nulls', () {
      final data = <VoteItemModel?>[
        _item(id: 1, voteTotal: 10),
        null,
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, ''), [0, 1]);
    });

    test('does not match artist with id 0', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(id: 0, name: {'ko': '테스트', 'en': 'Test'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'Test'), isEmpty);
    });

    test('does not match direct group with id 0', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artistGroup: _group(id: 0, name: {'ko': '테스트', 'en': 'Test'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'Test'), isEmpty);
    });

    test('matches multiple items', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(name: {'ko': '아이유', 'en': 'IU'}),
        ),
        _item(
          id: 2,
          voteTotal: 20,
          artist: _artist(id: 2, name: {'ko': '아이돌', 'en': 'Idol'}),
        ),
        _item(
          id: 3,
          voteTotal: 30,
          artist: _artist(id: 3, name: {'ko': '태연', 'en': 'Taeyeon'}),
        ),
      ];
      // '아이' matches both items 0 and 1
      expect(VoteDetailHelper.getFilteredIndices(data, '아이'), [0, 1]);
    });

    test('handles empty data list', () {
      expect(VoteDetailHelper.getFilteredIndices([], 'test'), isEmpty);
    });

    test('handles empty data list with empty query', () {
      expect(VoteDetailHelper.getFilteredIndices([], ''), isEmpty);
    });

    test('matches artist group English name', () {
      final group = _group(name: {'ko': '에스엠', 'en': 'SM Entertainment'});
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(
            name: {'ko': '보아', 'en': 'BoA'},
            artistGroup: group,
          ),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'entertainment'), [0]);
    });

    test('matches direct artistGroup Korean name', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: null,
          artistGroup: _group(name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, '블랙'), [0]);
    });

    test('does not match item with null artist and null artistGroup', () {
      final data = [
        _item(id: 1, voteTotal: 10, artist: null, artistGroup: null),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'test'), isEmpty);
    });

    test('artist with null name map keys', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(id: 1, name: {}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'test'), isEmpty);
    });

    test('artist with empty ko and en names does not match', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(id: 1, name: {'ko': '', 'en': ''}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'test'), isEmpty);
    });

    test('matches artist with null artistGroup', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(
            id: 1,
            name: {'ko': '태연', 'en': 'Taeyeon'},
            artistGroup: null,
          ),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'Taeyeon'), [0]);
    });

    test('direct group with empty name does not match', () {
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artistGroup: _group(id: 1, name: {}),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'test'), isEmpty);
    });

    test('artist group English name match in getFilteredIndices', () {
      final group =
          _group(name: {'ko': '소녀시대', 'en': "Girls' Generation"});
      final data = [
        _item(
          id: 1,
          voteTotal: 10,
          artist: _artist(
            name: {'ko': '태연', 'en': 'Taeyeon'},
            artistGroup: group,
          ),
        ),
      ];
      expect(VoteDetailHelper.getFilteredIndices(data, 'girls'), [0]);
    });
  });

  // ── diffChangedItemIds ───────────────────────────────────────────────

  group('diffChangedItemIds', () {
    test('returns empty set when no totals provided', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      expect(VoteDetailHelper.diffChangedItemIds(current, <int, int>{}), isEmpty);
    });

    test('returns empty set when totals match current', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 11: 50});
      expect(result, isEmpty);
    });

    test('returns ids whose voteTotal changed', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 11: 75});
      expect(result, {11});
    });

    test('returns multiple changed ids', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 120, 11: 75});
      expect(result, {10, 11});
    });

    test('treats null current voteTotal as 0 for comparison', () {
      final current = [_item(id: 10, voteTotal: null)];
      // newTotal 0 == treated-as-0 current -> no change
      expect(VoteDetailHelper.diffChangedItemIds(current, {10: 0}), isEmpty);
      // newTotal 5 != 0 -> changed
      expect(VoteDetailHelper.diffChangedItemIds(current, {10: 5}), {10});
    });

    test('ignores null items in current list', () {
      final current = <VoteItemModel?>[null, _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {11: 99});
      expect(result, {11});
    });

    test('ids present in newTotals but absent from current are included (newly present)', () {
      final current = [_item(id: 10, voteTotal: 100)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 99: 7});
      expect(result, {99});
    });

    test('ids in current but absent from newTotals are not included', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      // 11 missing from totals -> no signal, not a change
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100});
      expect(result, isEmpty);
    });
  });

  // ── areDataListsEqual additional branches ─────────────────────────────
  group('areDataListsEqual - additional', () {
    test('first is null second is not null', () {
      expect(
        VoteDetailHelper.areDataListsEqual(
          [_item(id: 1, voteTotal: 10)],
          [null],
        ),
        isFalse,
      );
    });

    test('items with same id but one null voteTotal', () {
      final a = _item(id: 1, voteTotal: 10);
      final b = _item(id: 1, voteTotal: null);
      expect(VoteDetailHelper.areDataListsEqual([a], [b]), isFalse);
    });
  });

  // ── getMatchingText additional branches ────────────────────────────────
  group('getMatchingText - additional', () {
    test('ko is null value', () {
      final nameMap = {'ko': null, 'en': 'Artist'};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, 'art'),
        'Artist',
      );
    });

    test('en is null value falls back', () {
      final nameMap = {'ko': '아티스트', 'en': null};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, 'xyz', fallbackText: 'fb'),
        'fb',
      );
    });

    test('ko matches but en also would - returns ko first', () {
      final nameMap = {'ko': '테스트한글', 'en': '테스트한글'};
      expect(
        VoteDetailHelper.getMatchingText(nameMap, '테스트'),
        '테스트한글',
      );
    });
  });

  // ── makeFullImageUrl additional branches ─────────────────────────────
  group('makeFullImageUrl - additional', () {
    test('cdnUrl without trailing slash and imageUrl without leading slash', () {
      expect(
        VoteDetailHelper.makeFullImageUrl(
          'photo.png',
          'https://cdn.example.com',
        ),
        'https://cdn.example.com/photo.png',
      );
    });

    test('deep nested path', () {
      expect(
        VoteDetailHelper.makeFullImageUrl(
          'a/b/c/d/photo.png',
          'https://cdn.example.com',
        ),
        'https://cdn.example.com/a/b/c/d/photo.png',
      );
    });
  });
}
