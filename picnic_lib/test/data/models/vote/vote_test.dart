import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

void main() {
  group('VoteModel', () {
    test('creates from constructor', () {
      const model = VoteModel(
        id: 1,
        title: {'ko': '투표 제목'},
        voteCategory: 'normal',
        mainImage: null,
        waitImage: null,
        resultImage: null,
        voteContent: 'content',
        voteItem: null,
        createdAt: null,
        visibleAt: null,
        stopAt: null,
        startAt: null,
        isEnded: false,
        isUpcoming: false,
        isPartnership: false,
        partner: null,
        reward: null,
      );
      expect(model.id, 1);
      expect(model.title['ko'], '투표 제목');
      expect(model.voteCategory, 'normal');
    });

    group('cardStatus', () {
      test('returns upcoming when startAt is in the future', () {
        final model = VoteModel(
          id: 1,
          title: const {'ko': 'test'},
          voteCategory: null,
          mainImage: null,
          waitImage: null,
          resultImage: null,
          voteContent: null,
          voteItem: null,
          createdAt: null,
          visibleAt: null,
          stopAt: DateTime.now().add(const Duration(days: 30)),
          startAt: DateTime.now().add(const Duration(days: 1)),
          isEnded: false,
          isUpcoming: true,
          isPartnership: false,
          partner: null,
          reward: null,
        );
        expect(model.cardStatus, VoteCardStatus.upcoming);
      });

      test('returns ended when stopAt is in the past', () {
        final model = VoteModel(
          id: 1,
          title: const {'ko': 'test'},
          voteCategory: null,
          mainImage: null,
          waitImage: null,
          resultImage: null,
          voteContent: null,
          voteItem: null,
          createdAt: null,
          visibleAt: null,
          stopAt: DateTime.now().subtract(const Duration(days: 1)),
          startAt: DateTime.now().subtract(const Duration(days: 30)),
          isEnded: true,
          isUpcoming: false,
          isPartnership: false,
          partner: null,
          reward: null,
        );
        expect(model.cardStatus, VoteCardStatus.ended);
      });

      test('returns ongoing when between startAt and stopAt', () {
        final model = VoteModel(
          id: 1,
          title: const {'ko': 'test'},
          voteCategory: null,
          mainImage: null,
          waitImage: null,
          resultImage: null,
          voteContent: null,
          voteItem: null,
          createdAt: null,
          visibleAt: null,
          stopAt: DateTime.now().add(const Duration(days: 7)),
          startAt: DateTime.now().subtract(const Duration(days: 1)),
          isEnded: false,
          isUpcoming: false,
          isPartnership: false,
          partner: null,
          reward: null,
        );
        expect(model.cardStatus, VoteCardStatus.ongoing);
      });

      test('returns ongoing when startAt and stopAt are null', () {
        const model = VoteModel(
          id: 1,
          title: {'ko': 'test'},
          voteCategory: null,
          mainImage: null,
          waitImage: null,
          resultImage: null,
          voteContent: null,
          voteItem: null,
          createdAt: null,
          visibleAt: null,
          stopAt: null,
          startAt: null,
          isEnded: false,
          isUpcoming: false,
          isPartnership: false,
          partner: null,
          reward: null,
        );
        expect(model.cardStatus, VoteCardStatus.ongoing);
      });
    });

    test('copyWith updates fields', () {
      const model = VoteModel(
        id: 1,
        title: {'ko': '원래'},
        voteCategory: 'normal',
        mainImage: null,
        waitImage: null,
        resultImage: null,
        voteContent: null,
        voteItem: null,
        createdAt: null,
        visibleAt: null,
        stopAt: null,
        startAt: null,
        isEnded: false,
        isUpcoming: false,
        isPartnership: false,
        partner: null,
        reward: null,
      );
      final updated = model.copyWith(
        isPartnership: true,
        partner: 'Brand',
      );
      expect(updated.isPartnership, isTrue);
      expect(updated.partner, 'Brand');
      expect(updated.id, 1);
    });
  });

  group('VoteItemModel', () {
    test('creates from constructor', () {
      const model = VoteItemModel(
        id: 1,
        voteTotal: 1000,
        voteId: 10,
        artist: ArtistModel(
          id: 1,
          name: {'ko': 'BTS'},
          image: null,
        ),
        artistGroup: ArtistGroupModel(
          id: 1,
          name: {'ko': 'BTS'},
          image: null,
        ),
      );
      expect(model.id, 1);
      expect(model.voteTotal, 1000);
      expect(model.artist?.name['ko'], 'BTS');
    });

    test('has optional star candy totals', () {
      const model = VoteItemModel(
        id: 1,
        voteTotal: 500,
        starCandyTotal: 200,
        starCandyBonusTotal: 50,
        voteId: 10,
        artist: null,
        artistGroup: null,
      );
      expect(model.starCandyTotal, 200);
      expect(model.starCandyBonusTotal, 50);
    });
  });

  group('ArtistModelWithHighlight', () {
    test('creates with required fields', () {
      final model = ArtistModelWithHighlight(
        artist: const ArtistModel(
          id: 1,
          name: {'ko': 'BTS'},
          image: null,
        ),
        highlightedName: '<b>BTS</b>',
        highlightedGroupName: '<b>BTS Group</b>',
      );
      expect(model.artist.id, 1);
      expect(model.highlightedName, '<b>BTS</b>');
      expect(model.highlightedGroupName, '<b>BTS Group</b>');
    });
  });

  group('ArtistGroupModel', () {
    test('creates from constructor', () {
      const model = ArtistGroupModel(
        id: 1,
        name: {'ko': 'BTS', 'en': 'BTS'},
        image: 'group.jpg',
      );
      expect(model.id, 1);
      expect(model.name['ko'], 'BTS');
      expect(model.image, 'group.jpg');
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name': {'ko': 'BTS'},
        'image': null,
      };
      final model = ArtistGroupModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name['ko'], 'BTS');
      expect(model.image, isNull);
    });

    test('copyWith updates fields', () {
      const model = ArtistGroupModel(
        id: 1,
        name: {'ko': '원래'},
        image: null,
      );
      final updated = model.copyWith(image: 'new.jpg');
      expect(updated.image, 'new.jpg');
      expect(updated.id, 1);
    });
  });
}
