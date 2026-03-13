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

  // ── calculateVoteCountDiff ──────────────────────────────────────────
  group('calculateVoteCountDiff', () {
    test('returns positive diff when current > previous', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(150, 100), 50);
    });

    test('returns 0 when equal', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(100, 100), 0);
    });

    test('returns negative diff when current < previous', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(50, 100), -50);
    });

    test('returns 0 when current is null', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(null, 100), 0);
    });

    test('returns 0 when previous is null', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(100, null), 0);
    });

    test('returns 0 when both are null', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(null, null), 0);
    });

    test('handles large values', () {
      expect(VoteDetailHelper.calculateVoteCountDiff(1000000, 999000), 1000);
    });
  });

  // ── detectRankChange ────────────────────────────────────────────────
  group('detectRankChange', () {
    test('no change when ranks are equal', () {
      final result = VoteDetailHelper.detectRankChange(1, 1);
      expect(result.changed, false);
      expect(result.rankUp, false);
    });

    test('rank up when previous > current (lower is better)', () {
      final result = VoteDetailHelper.detectRankChange(1, 3);
      expect(result.changed, true);
      expect(result.rankUp, true);
    });

    test('rank down when previous < current', () {
      final result = VoteDetailHelper.detectRankChange(3, 1);
      expect(result.changed, true);
      expect(result.rankUp, false);
    });

    test('large rank change', () {
      final result = VoteDetailHelper.detectRankChange(1, 100);
      expect(result.changed, true);
      expect(result.rankUp, true);
    });
  });

  // ── RankChangeResult ────────────────────────────────────────────────
  group('RankChangeResult', () {
    test('stores values correctly', () {
      const result = RankChangeResult(changed: true, rankUp: true);
      expect(result.changed, true);
      expect(result.rankUp, true);
    });

    test('unchanged rank', () {
      const result = RankChangeResult(changed: false, rankUp: false);
      expect(result.changed, false);
      expect(result.rankUp, false);
    });
  });

  // ── getVoteItemImageUrl ─────────────────────────────────────────────
  group('getVoteItemImageUrl', () {
    test('returns artist image when artist has id', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 1, image: 'artist.png'),
      );
      expect(VoteDetailHelper.getVoteItemImageUrl(item), 'artist.png');
    });

    test('returns empty when artist has id but no image', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 1, image: null),
      );
      expect(VoteDetailHelper.getVoteItemImageUrl(item), '');
    });

    test('returns group image when artist id is 0', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 0),
        artistGroup: _group(id: 1, image: 'group.png'),
      );
      expect(VoteDetailHelper.getVoteItemImageUrl(item), 'group.png');
    });

    test('returns group image when artist is null', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: null,
        artistGroup: _group(id: 1, image: 'group.png'),
      );
      expect(VoteDetailHelper.getVoteItemImageUrl(item), 'group.png');
    });

    test('returns empty when no artist and no group', () {
      final item = _item(id: 1, voteTotal: 10, artist: null, artistGroup: null);
      expect(VoteDetailHelper.getVoteItemImageUrl(item), '');
    });
  });

  // ── getVoteItemNameMap ──────────────────────────────────────────────
  group('getVoteItemNameMap', () {
    test('returns artist name when artist has id', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 1, name: {'ko': '아이유', 'en': 'IU'}),
      );
      final nameMap = VoteDetailHelper.getVoteItemNameMap(item);
      expect(nameMap['ko'], '아이유');
      expect(nameMap['en'], 'IU');
    });

    test('returns group name when artist is null', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: null,
        artistGroup: _group(name: {'ko': 'BTS', 'en': 'BTS'}),
      );
      final nameMap = VoteDetailHelper.getVoteItemNameMap(item);
      expect(nameMap['ko'], 'BTS');
    });

    test('returns empty map when no artist and no group', () {
      final item = _item(id: 1, voteTotal: 10, artist: null, artistGroup: null);
      expect(VoteDetailHelper.getVoteItemNameMap(item), isEmpty);
    });

    test('returns empty map when artist id is 0 and no group', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 0),
        artistGroup: null,
      );
      expect(VoteDetailHelper.getVoteItemNameMap(item), isEmpty);
    });
  });

  // ── getVoteItemGroupNameMap ─────────────────────────────────────────
  group('getVoteItemGroupNameMap', () {
    test('returns group name when artist has group', () {
      final group = _group(name: {'ko': '에스엠', 'en': 'SM'});
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 1, artistGroup: group),
      );
      final nameMap = VoteDetailHelper.getVoteItemGroupNameMap(item);
      expect(nameMap, isNotNull);
      expect(nameMap!['ko'], '에스엠');
    });

    test('returns null when artist has no group', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 1, artistGroup: null),
      );
      expect(VoteDetailHelper.getVoteItemGroupNameMap(item), isNull);
    });

    test('returns null when artist is null', () {
      final item = _item(id: 1, voteTotal: 10, artist: null);
      expect(VoteDetailHelper.getVoteItemGroupNameMap(item), isNull);
    });

    test('returns null when artist id is 0', () {
      final item = _item(
        id: 1,
        voteTotal: 10,
        artist: _artist(id: 0, artistGroup: _group()),
      );
      expect(VoteDetailHelper.getVoteItemGroupNameMap(item), isNull);
    });
  });
}
