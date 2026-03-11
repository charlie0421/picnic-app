import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';

void main() {
  group('ArtistModel', () {
    test('creates from constructor with minimal fields', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '아이유', 'en': 'IU'},
        image: null,
      );
      expect(model.id, 1);
      expect(model.name['ko'], '아이유');
      expect(model.image, isNull);
      expect(model.artistGroup, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name': {'ko': '아이유', 'en': 'IU'},
        'image': 'https://example.com/img.jpg',
        'gender': 'female',
      };
      final model = ArtistModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name['ko'], '아이유');
      expect(model.image, 'https://example.com/img.jpg');
      expect(model.gender, 'female');
    });

    test('toJson serializes correctly', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '아이유'},
        image: null,
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['name'], {'ko': '아이유'});
    });

    group('birthDate', () {
      test('returns birthDateRaw when available', () {
        final date = DateTime(1993, 5, 16);
        final model = ArtistModel(
          id: 1,
          name: const {'ko': '아이유'},
          image: null,
          birthDateRaw: date,
        );
        expect(model.birthDate, date);
      });

      test('computes from yy/mm/dd when no birthDateRaw', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': '아이유'},
          image: null,
          yy: 1993,
          mm: 5,
          dd: 16,
        );
        expect(model.birthDate, DateTime(1993, 5, 16));
      });

      test('returns null when no date info', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': '아이유'},
          image: null,
        );
        expect(model.birthDate, isNull);
      });

      test('prefers birthDateRaw over yy/mm/dd', () {
        final raw = DateTime(2000, 1, 1);
        final model = ArtistModel(
          id: 1,
          name: const {'ko': 'Test'},
          image: null,
          birthDateRaw: raw,
          yy: 1993,
          mm: 5,
          dd: 16,
        );
        expect(model.birthDate, raw);
      });

      test('returns null when partial yy/mm/dd', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': 'Test'},
          image: null,
          yy: 1993,
          mm: 5,
        );
        expect(model.birthDate, isNull);
      });
    });

    group('formattedBirthDate', () {
      test('formats correctly', () {
        final model = ArtistModel(
          id: 1,
          name: const {'ko': '아이유'},
          image: null,
          birthDateRaw: DateTime(1993, 5, 16),
        );
        expect(model.formattedBirthDate, '1993년 5월 16일');
      });

      test('returns null when no birth date', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': '아이유'},
          image: null,
        );
        expect(model.formattedBirthDate, isNull);
      });
    });

    group('formattedName', () {
      test('returns Korean name when available', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': '아이유', 'en': 'IU'},
          image: null,
        );
        expect(model.formattedName, '아이유');
      });

      test('returns English name when no Korean', () {
        const model = ArtistModel(
          id: 1,
          name: {'en': 'IU'},
          image: null,
        );
        expect(model.formattedName, 'IU');
      });

      test('returns first value when no ko or en', () {
        const model = ArtistModel(
          id: 1,
          name: {'ja': 'アイユー'},
          image: null,
        );
        expect(model.formattedName, 'アイユー');
      });

      test('returns null for empty name', () {
        const model = ArtistModel(
          id: 1,
          name: {},
          image: null,
        );
        expect(model.formattedName, isNull);
      });
    });

    group('isDeleted', () {
      test('returns false when deletedAt is null', () {
        const model = ArtistModel(
          id: 1,
          name: {'ko': '아이유'},
          image: null,
        );
        expect(model.isDeleted, isFalse);
      });

      test('returns true when deletedAt is set', () {
        final model = ArtistModel(
          id: 1,
          name: const {'ko': '아이유'},
          image: null,
          deletedAt: DateTime(2025, 1, 1),
        );
        expect(model.isDeleted, isTrue);
      });
    });

    test('copyWith updates fields', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': '원래'},
        image: null,
      );
      final updated = model.copyWith(
        image: 'new_image.jpg',
        isBookmarked: true,
      );
      expect(updated.image, 'new_image.jpg');
      expect(updated.isBookmarked, isTrue);
      expect(updated.id, 1);
    });

    test('creates with artist group', () {
      const model = ArtistModel(
        id: 1,
        name: {'ko': 'BTS 진'},
        image: null,
        artistGroup: ArtistGroupModel(
          id: 10,
          name: {'ko': 'BTS'},
          image: null,
        ),
      );
      expect(model.artistGroup?.name['ko'], 'BTS');
    });
  });
}
