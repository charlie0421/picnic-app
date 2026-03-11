import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

void main() {
  group('ArtistModel 계산 속성', () {
    ArtistModel createArtist({
      int id = 1,
      Map<String, dynamic> name = const {'ko': '테스트'},
      int? yy,
      int? mm,
      int? dd,
      DateTime? birthDateRaw,
      DateTime? deletedAt,
    }) {
      return ArtistModel(
        id: id,
        name: name,
        yy: yy,
        mm: mm,
        dd: dd,
        birthDateRaw: birthDateRaw,
        deletedAt: deletedAt,
      );
    }

    group('birthDate', () {
      test('birthDateRaw가 있으면 우선 사용', () {
        final raw = DateTime(2000, 1, 15);
        final artist = createArtist(
          birthDateRaw: raw,
          yy: 1999,
          mm: 12,
          dd: 25,
        );
        expect(artist.birthDate, equals(raw));
      });

      test('birthDateRaw가 없으면 yy/mm/dd로 계산', () {
        final artist = createArtist(yy: 1995, mm: 3, dd: 20);
        expect(artist.birthDate, equals(DateTime(1995, 3, 20)));
      });

      test('yy/mm/dd 중 하나라도 없으면 null', () {
        expect(createArtist(yy: 1995, mm: 3).birthDate, isNull);
        expect(createArtist(yy: 1995, dd: 20).birthDate, isNull);
        expect(createArtist(mm: 3, dd: 20).birthDate, isNull);
      });

      test('모든 생년월일 정보 없으면 null', () {
        expect(createArtist().birthDate, isNull);
      });
    });

    group('formattedBirthDate', () {
      test('생년월일이 있으면 포맷된 문자열 반환', () {
        final artist = createArtist(
          birthDateRaw: DateTime(2000, 1, 15),
        );
        expect(artist.formattedBirthDate, equals('2000년 1월 15일'));
      });

      test('생년월일이 없으면 null', () {
        expect(createArtist().formattedBirthDate, isNull);
      });

      test('yy/mm/dd로 계산된 생년월일도 포맷', () {
        final artist = createArtist(yy: 1998, mm: 11, dd: 5);
        expect(artist.formattedBirthDate, equals('1998년 11월 5일'));
      });
    });

    group('formattedName', () {
      test('ko 키가 있으면 한국어 이름 반환', () {
        final artist = createArtist(
          name: {'ko': '방탄소년단', 'en': 'BTS'},
        );
        expect(artist.formattedName, equals('방탄소년단'));
      });

      test('ko 없고 en 있으면 영어 이름 반환', () {
        final artist = createArtist(
          name: {'en': 'BTS', 'ja': 'ボウダンショウネンダン'},
        );
        expect(artist.formattedName, equals('BTS'));
      });

      test('ko/en 둘 다 없으면 첫 번째 값 반환', () {
        final artist = createArtist(
          name: {'ja': '防弾少年団'},
        );
        expect(artist.formattedName, equals('防弾少年団'));
      });

      test('빈 맵이면 null', () {
        final artist = createArtist(name: {});
        expect(artist.formattedName, isNull);
      });
    });

    group('isDeleted', () {
      test('deletedAt이 있으면 true', () {
        final artist = createArtist(deletedAt: DateTime.now());
        expect(artist.isDeleted, isTrue);
      });

      test('deletedAt이 null이면 false', () {
        expect(createArtist().isDeleted, isFalse);
      });
    });
  });
}
