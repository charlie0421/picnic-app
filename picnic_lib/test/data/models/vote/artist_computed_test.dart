import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

void main() {
  group('ArtistModel computed properties', () {
    test('birthDate from birthDateRaw', () {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민'},
        'yy': null,
        'mm': null,
        'dd': null,
        'birth_date': '1995-10-13T00:00:00.000Z',
        'gender': 'M',
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.birthDate, isNotNull);
      expect(artist.birthDate!.year, equals(1995));
      expect(artist.birthDate!.month, equals(10));
      expect(artist.birthDate!.day, equals(13));
    });

    test('birthDate from yy/mm/dd when birthDateRaw is null', () {
      final artist = ArtistModel.fromJson({
        'id': 2,
        'name': {'ko': '뷔'},
        'yy': 1995,
        'mm': 12,
        'dd': 30,
        'birth_date': null,
        'gender': 'M',
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.birthDate, isNotNull);
      expect(artist.birthDate!.year, equals(1995));
      expect(artist.birthDate!.month, equals(12));
      expect(artist.birthDate!.day, equals(30));
    });

    test('birthDate null when all date fields null', () {
      final artist = ArtistModel.fromJson({
        'id': 3,
        'name': {'ko': '테스트'},
        'yy': null,
        'mm': null,
        'dd': null,
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.birthDate, isNull);
    });

    test('birthDate null when partial yy/mm/dd', () {
      final artist = ArtistModel.fromJson({
        'id': 4,
        'name': {'ko': '테스트'},
        'yy': 1995,
        'mm': null,
        'dd': null,
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.birthDate, isNull);
    });

    test('formattedBirthDate 포맷 확인', () {
      final artist = ArtistModel.fromJson({
        'id': 5,
        'name': {'ko': '지민'},
        'yy': 1995,
        'mm': 10,
        'dd': 13,
        'birth_date': null,
        'gender': 'M',
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedBirthDate, equals('1995년 10월 13일'));
    });

    test('formattedBirthDate null when no birthDate', () {
      final artist = ArtistModel.fromJson({
        'id': 6,
        'name': {'ko': '테스트'},
        'yy': null,
        'mm': null,
        'dd': null,
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedBirthDate, isNull);
    });

    test('formattedName ko 우선', () {
      final artist = ArtistModel.fromJson({
        'id': 7,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedName, equals('지민'));
    });

    test('formattedName en fallback', () {
      final artist = ArtistModel.fromJson({
        'id': 8,
        'name': {'en': 'Jimin'},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedName, equals('Jimin'));
    });

    test('formattedName first value fallback', () {
      final artist = ArtistModel.fromJson({
        'id': 9,
        'name': {'ja': 'ジミン'},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedName, equals('ジミン'));
    });

    test('formattedName null when name empty', () {
      final artist = ArtistModel.fromJson({
        'id': 10,
        'name': <String, dynamic>{},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.formattedName, isNull);
    });

    test('isDeleted true when deletedAt is set', () {
      final artist = ArtistModel.fromJson({
        'id': 11,
        'name': {'ko': '삭제됨'},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': '2025-01-01T00:00:00.000Z',
        'isBookmarked': null,
      });
      expect(artist.isDeleted, isTrue);
    });

    test('isDeleted false when deletedAt is null', () {
      final artist = ArtistModel.fromJson({
        'id': 12,
        'name': {'ko': '활성'},
        'birth_date': null,
        'gender': null,
        'image': null,
        'created_at': null,
        'updated_at': null,
        'deleted_at': null,
        'isBookmarked': null,
      });
      expect(artist.isDeleted, isFalse);
    });
  });
}
