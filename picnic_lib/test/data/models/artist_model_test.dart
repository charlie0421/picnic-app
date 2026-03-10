import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';

void main() {
  group('ArtistModel', () {
    late Map<String, dynamic> testJson;
    late ArtistModel testArtist;

    setUp(() {
      testJson = {
        'id': 1,
        'name': {'ko': '홍길동', 'en': 'Hong Gildong'},
        'yy': 2000,
        'mm': 5,
        'dd': 15,
        'birth_date': null,
        'gender': 'male',
        'artist_group': {
          'id': 10,
          'name': {'ko': '테스트 그룹', 'en': 'Test Group'},
          'image': 'https://example.com/group.jpg',
        },
        'image': 'https://example.com/artist.jpg',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-15T00:00:00.000Z',
        'deleted_at': null,
        'isBookmarked': false,
      };

      testArtist = ArtistModel(
        id: 1,
        name: {'ko': '홍길동', 'en': 'Hong Gildong'},
        yy: 2000,
        mm: 5,
        dd: 15,
        gender: 'male',
        image: 'https://example.com/artist.jpg',
        artistGroup: ArtistGroupModel(
          id: 10,
          name: {'ko': '테스트 그룹', 'en': 'Test Group'},
          image: 'https://example.com/group.jpg',
        ),
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2025-01-15T00:00:00.000Z'),
      );
    });

    group('fromJson', () {
      test('유효한 JSON에서 ArtistModel을 생성할 수 있다', () {
        final artist = ArtistModel.fromJson(testJson);

        expect(artist.id, equals(1));
        expect(artist.name, equals({'ko': '홍길동', 'en': 'Hong Gildong'}));
        expect(artist.yy, equals(2000));
        expect(artist.mm, equals(5));
        expect(artist.dd, equals(15));
        expect(artist.gender, equals('male'));
        expect(artist.image, equals('https://example.com/artist.jpg'));
        expect(artist.artistGroup, isNotNull);
        expect(artist.artistGroup!.id, equals(10));
        expect(artist.deletedAt, isNull);
      });

      test('최소한의 필드로 ArtistModel을 생성할 수 있다', () {
        final minimalJson = {
          'id': 2,
          'name': {'ko': '미니멀'},
        };

        final artist = ArtistModel.fromJson(minimalJson);
        expect(artist.id, equals(2));
        expect(artist.yy, isNull);
        expect(artist.mm, isNull);
        expect(artist.dd, isNull);
        expect(artist.gender, isNull);
        expect(artist.artistGroup, isNull);
        expect(artist.image, isNull);
      });
    });

    group('toJson', () {
      test('ArtistModel을 JSON으로 변환할 수 있다', () {
        final json = testArtist.toJson();

        expect(json['id'], equals(1));
        expect(json['name'], equals({'ko': '홍길동', 'en': 'Hong Gildong'}));
        expect(json['yy'], equals(2000));
        expect(json['mm'], equals(5));
        expect(json['dd'], equals(15));
        expect(json['gender'], equals('male'));
        expect(json['image'], equals('https://example.com/artist.jpg'));
        expect(json['artist_group'], isNotNull);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경하여 새 인스턴스를 생성할 수 있다', () {
        final modified = testArtist.copyWith(
          id: 99,
          gender: 'female',
        );

        expect(modified.id, equals(99));
        expect(modified.gender, equals('female'));
        // 변경하지 않은 필드는 유지
        expect(modified.name, equals(testArtist.name));
        expect(modified.yy, equals(testArtist.yy));
      });

      test('image를 변경할 수 있다', () {
        final modified = testArtist.copyWith(
          image: 'https://example.com/new.jpg',
        );
        expect(modified.image, equals('https://example.com/new.jpg'));
      });
    });

    group('동등성', () {
      test('동일한 값을 가진 두 ArtistModel은 같다', () {
        final artist1 = ArtistModel.fromJson(testJson);
        final artist2 = ArtistModel.fromJson(testJson);
        expect(artist1, equals(artist2));
      });

      test('다른 id를 가진 두 ArtistModel은 다르다', () {
        final json2 = Map<String, dynamic>.from(testJson);
        json2['id'] = 999;
        final artist1 = ArtistModel.fromJson(testJson);
        final artist2 = ArtistModel.fromJson(json2);
        expect(artist1, isNot(equals(artist2)));
      });
    });

    group('formattedName (computed property)', () {
      test('ko 키가 있으면 한국어 이름을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '홍길동', 'en': 'Hong Gildong'},
        );
        expect(artist.formattedName, equals('홍길동'));
      });

      test('ko 키가 없고 en 키가 있으면 영어 이름을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'en': 'Hong Gildong'},
        );
        expect(artist.formattedName, equals('Hong Gildong'));
      });

      test('ko, en 키가 없으면 첫 번째 값을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ja': 'ホンギルドン'},
        );
        expect(artist.formattedName, equals('ホンギルドン'));
      });

      test('name이 비어있으면 null을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {},
        );
        expect(artist.formattedName, isNull);
      });
    });

    group('isDeleted (computed property)', () {
      test('deletedAt이 null이면 isDeleted는 false이다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          deletedAt: null,
        );
        expect(artist.isDeleted, isFalse);
      });

      test('deletedAt이 설정되면 isDeleted는 true이다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          deletedAt: DateTime.now(),
        );
        expect(artist.isDeleted, isTrue);
      });
    });

    group('birthDate (computed property)', () {
      test('birthDateRaw가 있으면 birthDateRaw를 반환한다', () {
        final rawDate = DateTime(1999, 3, 20);
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          birthDateRaw: rawDate,
          yy: 2000,
          mm: 5,
          dd: 15,
        );
        // birthDateRaw가 우선
        expect(artist.birthDate, equals(rawDate));
      });

      test('birthDateRaw가 없고 yy/mm/dd가 있으면 계산된 날짜를 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          yy: 2000,
          mm: 5,
          dd: 15,
        );
        expect(artist.birthDate, equals(DateTime(2000, 5, 15)));
      });

      test('birthDateRaw와 yy/mm/dd 모두 없으면 null을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
        );
        expect(artist.birthDate, isNull);
      });

      test('yy만 있고 mm/dd가 없으면 null을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          yy: 2000,
        );
        expect(artist.birthDate, isNull);
      });
    });

    group('formattedBirthDate (computed property)', () {
      test('birthDate가 있으면 포맷된 문자열을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
          yy: 2000,
          mm: 5,
          dd: 15,
        );
        expect(artist.formattedBirthDate, equals('2000년 5월 15일'));
      });

      test('birthDate가 없으면 null을 반환한다', () {
        final artist = ArtistModel(
          id: 1,
          name: {'ko': '테스트'},
        );
        expect(artist.formattedBirthDate, isNull);
      });
    });
  });

  group('ArtistGroupModel', () {
    test('fromJson으로 ArtistGroupModel을 생성할 수 있다', () {
      final json = {
        'id': 10,
        'name': {'ko': '테스트 그룹', 'en': 'Test Group'},
        'image': 'https://example.com/group.jpg',
      };

      final group = ArtistGroupModel.fromJson(json);
      expect(group.id, equals(10));
      expect(group.name, equals({'ko': '테스트 그룹', 'en': 'Test Group'}));
      expect(group.image, equals('https://example.com/group.jpg'));
    });

    test('image가 null인 ArtistGroupModel을 생성할 수 있다', () {
      final json = {
        'id': 10,
        'name': {'ko': '그룹'},
        'image': null,
      };

      final group = ArtistGroupModel.fromJson(json);
      expect(group.image, isNull);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final group = ArtistGroupModel(
        id: 10,
        name: {'ko': '테스트 그룹'},
        image: 'https://example.com/group.jpg',
      );

      final json = group.toJson();
      expect(json['id'], equals(10));
      expect(json['name'], equals({'ko': '테스트 그룹'}));
      expect(json['image'], equals('https://example.com/group.jpg'));
    });

    test('동일한 값을 가진 두 ArtistGroupModel은 같다', () {
      final group1 = ArtistGroupModel(
        id: 10,
        name: {'ko': '테스트'},
        image: null,
      );
      final group2 = ArtistGroupModel(
        id: 10,
        name: {'ko': '테스트'},
        image: null,
      );
      expect(group1, equals(group2));
    });

    test('copyWith으로 특정 필드를 변경할 수 있다', () {
      final group = ArtistGroupModel(
        id: 10,
        name: {'ko': '원래 그룹'},
        image: null,
      );
      final modified = group.copyWith(
        name: {'ko': '수정된 그룹'},
      );
      expect(modified.name, equals({'ko': '수정된 그룹'}));
      expect(modified.id, equals(10));
    });
  });
}
