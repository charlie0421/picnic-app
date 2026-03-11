import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

void main() {
  VoteModel createVote({DateTime? startAt, DateTime? stopAt}) {
    return VoteModel.fromJson({
      'id': 1,
      'title': {'ko': '테스트'},
      'vote_category': null,
      'main_image': null,
      'wait_image': null,
      'result_image': null,
      'vote_content': null,
      'vote_item': null,
      'created_at': null,
      'visible_at': null,
      'start_at': startAt?.toIso8601String(),
      'stop_at': stopAt?.toIso8601String(),
      'is_ended': false,
      'is_upcoming': false,
      'is_partnership': false,
      'partner': null,
      'reward': null,
    });
  }

  group('VoteModel cardStatus', () {
    test('upcoming when startAt is in the future', () {
      final vote = createVote(
        startAt: DateTime.now().add(const Duration(days: 7)),
        stopAt: DateTime.now().add(const Duration(days: 14)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.upcoming));
    });

    test('ended when stopAt is in the past', () {
      final vote = createVote(
        startAt: DateTime.now().subtract(const Duration(days: 14)),
        stopAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.ended));
    });

    test('ongoing when now is between startAt and stopAt', () {
      final vote = createVote(
        startAt: DateTime.now().subtract(const Duration(days: 1)),
        stopAt: DateTime.now().add(const Duration(days: 7)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
    });

    test('ongoing when startAt and stopAt are null', () {
      final vote = createVote(startAt: null, stopAt: null);
      expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
    });
  });

  group('VoteItemModel fromJson', () {
    test('기본 생성', () {
      final json = {
        'id': 10,
        'vote_total': 500,
        'star_candy_total': 100,
        'star_candy_bonus_total': 50,
        'vote_id': 1,
        'artist': null,
        'artist_group': null,
      };
      final item = VoteItemModel.fromJson(json);
      expect(item.id, equals(10));
      expect(item.voteTotal, equals(500));
      expect(item.starCandyTotal, equals(100));
      expect(item.starCandyBonusTotal, equals(50));
    });

    test('null vote_total', () {
      final json = {
        'id': 11,
        'vote_total': null,
        'vote_id': 1,
        'artist': null,
        'artist_group': null,
      };
      final item = VoteItemModel.fromJson(json);
      expect(item.voteTotal, isNull);
    });
  });

  group('ArtistModelWithHighlight', () {
    test('생성 및 필드 접근', () {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'birth_date': null,
        'gender': 'M',
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      final highlighted = ArtistModelWithHighlight(
        artist: artist,
        highlightedName: '<b>지민</b>',
        highlightedGroupName: 'BTS',
      );
      expect(highlighted.artist.id, equals(1));
      expect(highlighted.highlightedName, equals('<b>지민</b>'));
      expect(highlighted.highlightedGroupName, equals('BTS'));
    });
  });
}
