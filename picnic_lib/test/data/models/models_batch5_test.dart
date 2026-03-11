import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

void main() {
  group('ArtistModel computed properties', () {
    test('birthDate from birthDateRaw', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': '지민'},
        'birth_date': '1995-10-13T00:00:00Z',
      });
      expect(artist.birthDate, isNotNull);
      expect(artist.birthDate!.year, 1995);
      expect(artist.birthDate!.month, 10);
      expect(artist.birthDate!.day, 13);
    });

    test('birthDate from yy/mm/dd when birthDateRaw is null', () {
      final artist = ArtistModel.fromJson(const {
        'id': 2,
        'name': {'ko': '뷔'},
        'yy': 1995,
        'mm': 12,
        'dd': 30,
      });
      expect(artist.birthDate, isNotNull);
      expect(artist.birthDate!.year, 1995);
      expect(artist.birthDate!.month, 12);
      expect(artist.birthDate!.day, 30);
    });

    test('birthDate null when no date info', () {
      final artist = ArtistModel.fromJson(const {
        'id': 3,
        'name': {'ko': 'Test'},
      });
      expect(artist.birthDate, isNull);
    });

    test('formattedBirthDate', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': '지민'},
        'birth_date': '1995-10-13T00:00:00Z',
      });
      expect(artist.formattedBirthDate, '1995년 10월 13일');
    });

    test('formattedBirthDate null when no date', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': 'Test'},
      });
      expect(artist.formattedBirthDate, isNull);
    });

    test('formattedName returns ko', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
      });
      expect(artist.formattedName, '지민');
    });

    test('formattedName returns en when no ko', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'en': 'Jimin'},
      });
      expect(artist.formattedName, 'Jimin');
    });

    test('formattedName returns first value when no ko or en', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ja': 'ジミン'},
      });
      expect(artist.formattedName, 'ジミン');
    });

    test('formattedName null when name is empty', () {
      final artist = ArtistModel.fromJson(<String, dynamic>{
        'id': 1,
        'name': <String, dynamic>{},
      });
      expect(artist.formattedName, isNull);
    });

    test('isDeleted', () {
      final notDeleted = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': 'Test'},
      });
      expect(notDeleted.isDeleted, isFalse);

      final deleted = ArtistModel.fromJson(const {
        'id': 2,
        'name': {'ko': 'Test'},
        'deleted_at': '2024-01-01T00:00:00Z',
      });
      expect(deleted.isDeleted, isTrue);
    });
  });

  group('ArtistGroupModel', () {
    test('fromJson', () {
      final group = ArtistGroupModel.fromJson(const {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': 'https://example.com/bts.jpg',
      });
      expect(group.id, 1);
      expect(group.name['ko'], 'BTS');
      expect(group.image, 'https://example.com/bts.jpg');
    });

    test('fromJson with null image', () {
      final group = ArtistGroupModel.fromJson(const {
        'id': 2,
        'name': {'ko': 'BLACKPINK'},
        'image': null,
      });
      expect(group.image, isNull);
    });
  });

  group('ArtistModelWithHighlight', () {
    test('constructor', () {
      final artist = ArtistModel.fromJson(const {
        'id': 1,
        'name': {'ko': '지민'},
      });
      final highlighted = ArtistModelWithHighlight(
        artist: artist,
        highlightedName: '지민',
        highlightedGroupName: 'BTS',
      );
      expect(highlighted.artist.id, 1);
      expect(highlighted.highlightedName, '지민');
      expect(highlighted.highlightedGroupName, 'BTS');
    });
  });

  group('VoteModel.cardStatus', () {
    test('upcoming when startAt is in the future', () {
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': 'Test Vote'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'stop_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': true,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.cardStatus, VoteCardStatus.upcoming);
    });

    test('ended when stopAt is in the past', () {
      final vote = VoteModel.fromJson({
        'id': 2,
        'title': {'ko': 'Ended Vote'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'stop_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_ended': true,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.cardStatus, VoteCardStatus.ended);
    });

    test('ongoing when between start and stop', () {
      final vote = VoteModel.fromJson({
        'id': 3,
        'title': {'ko': 'Ongoing Vote'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.cardStatus, VoteCardStatus.ongoing);
    });

    test('ongoing when startAt and stopAt are null', () {
      final vote = VoteModel.fromJson({
        'id': 4,
        'title': {'ko': 'No dates'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': null,
        'stop_at': null,
        'is_ended': null,
        'is_upcoming': null,
        'is_partnership': null,
        'partner': null,
        'reward': null,
      });
      expect(vote.cardStatus, VoteCardStatus.ongoing);
    });
  });

  group('GoonghapStatus extension', () {
    test('toJson', () {
      expect(GoonghapStatus.pending.toJson(), 'pending');
      expect(GoonghapStatus.completed.toJson(), 'completed');
      expect(GoonghapStatus.error.toJson(), 'error');
      expect(GoonghapStatus.input.toJson(), 'input');
    });

    test('fromJson', () {
      expect(GoonghapStatusX.fromJson('pending'), GoonghapStatus.pending);
      expect(GoonghapStatusX.fromJson('completed'), GoonghapStatus.completed);
      expect(GoonghapStatusX.fromJson('error'), GoonghapStatus.error);
      expect(GoonghapStatusX.fromJson('PENDING'), GoonghapStatus.pending);
    });

    test('fromJson unknown throws', () {
      expect(() => GoonghapStatusX.fromJson('unknown'), throwsArgumentError);
    });
  });

  group('GoonghapModel computed properties', () {
    test('isPending', () {
      final model = GoonghapModel.fromJson({
        'id': '1',
        'user_id': 'user1',
        'user_birth_date': '1995-01-01T00:00:00Z',
        'status': 'pending',
        'artist': {
          'id': 1,
          'name': {'ko': 'Test'},
        },
      });
      expect(model.isPending, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.hasError, isFalse);
    });

    test('isCompleted', () {
      final model = GoonghapModel.fromJson({
        'id': '2',
        'user_id': 'user1',
        'user_birth_date': '1995-01-01T00:00:00Z',
        'status': 'completed',
        'artist': {
          'id': 1,
          'name': {'ko': 'Test'},
        },
      });
      expect(model.isCompleted, isTrue);
      expect(model.isPending, isFalse);
    });

    test('hasError', () {
      final model = GoonghapModel.fromJson({
        'id': '3',
        'user_id': 'user1',
        'user_birth_date': '1995-01-01T00:00:00Z',
        'status': 'error',
        'artist': {
          'id': 1,
          'name': {'ko': 'Test'},
        },
      });
      expect(model.hasError, isTrue);
    });

    test('getLocalizedResult', () {
      final model = GoonghapModel.fromJson({
        'id': '4',
        'user_id': 'user1',
        'user_birth_date': '1995-01-01T00:00:00Z',
        'status': 'completed',
        'artist': {
          'id': 1,
          'name': {'ko': 'Test'},
        },
        'i18n': {
          'ko': {
            'language': 'ko',
            'score': 85,
            'score_title': '좋음',
            'goonghap_summary': '궁합이 좋습니다',
          },
        },
      });
      expect(model.getLocalizedResult('ko'), isNotNull);
      expect(model.getLocalizedResult('ko')!.score, 85);
      expect(model.getLocalizedResult('en'), isNull);
    });
  });

  group('LocalizedGoonghap', () {
    test('fromJson', () {
      final localized = LocalizedGoonghap.fromJson(const {
        'language': 'ko',
        'score': 90,
        'score_title': '최고',
        'goonghap_summary': '완벽한 궁합',
        'tips': ['팁1', '팁2'],
      });
      expect(localized.language, 'ko');
      expect(localized.score, 90);
      expect(localized.scoreTitle, '최고');
      expect(localized.goonghapSummary, '완벽한 궁합');
      expect(localized.tips.length, 2);
    });

    test('fromJson with defaults', () {
      final localized = LocalizedGoonghap.fromJson(const {
        'language': 'en',
      });
      expect(localized.score, 0);
      expect(localized.scoreTitle, '');
      expect(localized.goonghapSummary, '');
      expect(localized.tips, isEmpty);
    });
  });

  group('StyleDetails', () {
    test('fromJson', () {
      final style = StyleDetails.fromJson(const {
        'idol_style': 'Cute',
        'user_style': 'Cool',
        'couple_style': 'Dynamic',
      });
      expect(style.idolStyle, 'Cute');
      expect(style.userStyle, 'Cool');
      expect(style.coupleStyle, 'Dynamic');
    });
  });

  group('ActivitiesDetails', () {
    test('fromJson', () {
      final activities = ActivitiesDetails.fromJson(const {
        'recommended': ['카페', '영화'],
        'description': '함께 즐기기 좋은 활동',
      });
      expect(activities.recommended.length, 2);
      expect(activities.description, '함께 즐기기 좋은 활동');
    });
  });

  group('Details', () {
    test('fromJson', () {
      final details = Details.fromJson(const {
        'style': {
          'idol_style': 'A',
          'user_style': 'B',
          'couple_style': 'C',
        },
        'activities': {
          'recommended': ['D', 'E'],
          'description': 'F',
        },
      });
      expect(details.style.idolStyle, 'A');
      expect(details.activities.recommended.length, 2);
    });
  });

  group('DescriptionConverter', () {
    test('fromJson with Map', () {
      const converter = DescriptionConverter();
      final result = converter.fromJson({'ko': 'test', 'en': 'test'});
      expect(result, isA<Map>());
    });

    test('fromJson with String', () {
      const converter = DescriptionConverter();
      final result = converter.fromJson('simple description');
      expect(result, 'simple description');
    });

    test('fromJson with unsupported type throws', () {
      const converter = DescriptionConverter();
      expect(() => converter.fromJson(123), throwsArgumentError);
    });

    test('toJson with Map', () {
      const converter = DescriptionConverter();
      final result = converter.toJson({'ko': 'test'});
      expect(result, isA<Map>());
    });

    test('toJson with String', () {
      const converter = DescriptionConverter();
      final result = converter.toJson('simple');
      expect(result, 'simple');
    });

    test('toJson with unsupported type throws', () {
      const converter = DescriptionConverter();
      expect(() => converter.toJson(123), throwsArgumentError);
    });
  });

  group('QnaCategory', () {
    test('constructor', () {
      final category = QnaCategory(
        code: 'general',
        label: '일반 문의',
        questionTemplate: '질문 템플릿',
        answerTemplate: '답변 템플릿',
      );
      expect(category.code, 'general');
      expect(category.label, '일반 문의');
      expect(category.questionTemplate, '질문 템플릿');
      expect(category.answerTemplate, '답변 템플릿');
    });

    test('optional fields default to null', () {
      final category = QnaCategory(
        code: 'test',
        label: 'Test',
      );
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });
  });

  group('GoonghapHistoryModel', () {
    test('fromJson', () {
      final history = GoonghapHistoryModel.fromJson({
        'items': [
          {
            'id': '1',
            'user_id': 'user1',
            'user_birth_date': '1995-01-01T00:00:00Z',
            'status': 'completed',
            'artist': {
              'id': 1,
              'name': {'ko': 'Test'},
            },
          },
        ],
        'has_more': true,
        'is_loading': false,
      });
      expect(history.items.length, 1);
      expect(history.hasMore, isTrue);
      expect(history.isLoading, isFalse);
    });
  });

  group('VoteItemModel', () {
    test('fromJson', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_total': 1000,
        'star_candy_total': 500,
        'star_candy_bonus_total': 50,
        'vote_id': 10,
        'artist': {
          'id': 1,
          'name': {'ko': '지민'},
        },
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS'},
          'image': null,
        },
      });
      expect(item.id, 1);
      expect(item.voteTotal, 1000);
      expect(item.starCandyTotal, 500);
      expect(item.voteId, 10);
      expect(item.artist, isNotNull);
      expect(item.artistGroup, isNotNull);
    });
  });
}
