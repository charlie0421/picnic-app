import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_card.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  ArtistModel makeArtist({
    int id = 1,
    String nameKo = '지민',
    String nameEn = 'Jimin',
    String? gender = 'male',
    String? image,
    DateTime? birthDate,
  }) {
    return ArtistModel.fromJson({
      'id': id,
      'name': {'ko': nameKo, 'en': nameEn},
      'yy': 1995,
      'mm': 10,
      'dd': 13,
      'birth_date': birthDate?.toIso8601String() ?? '1995-10-13T00:00:00Z',
      'gender': gender,
      'image': image,
      'artist_group': null,
    });
  }

  group('GoonghapCard rendering', () {
    testWidgets('renders with minimal data (no birthDate, no goonghap)',
        (tester) async {
      final artist = makeArtist();

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(artist: artist),
        ),
      );
      await tester.pumpAndSettle();

      // Should render artist name
      expect(find.text('지민'), findsOneWidget);
    });

    testWidgets('renders with birthDate', (tester) async {
      final artist = makeArtist();

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            birthDate: DateTime(1998, 5, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render with user birth date section
      expect(find.text('지민'), findsOneWidget);
      // formatDateTimeYYYYMMDD renders the date
      expect(find.text('1998.05.20'), findsOneWidget);
    });

    testWidgets('renders with gender male', (tester) async {
      final artist = makeArtist(gender: 'male');

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            gender: 'male',
            birthDate: DateTime(2000, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Male emoji should appear
      expect(find.textContaining('\u{1F9D1}'), findsWidgets); // man emoji
    });

    testWidgets('renders with gender female', (tester) async {
      final artist = makeArtist(gender: 'female');

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            gender: 'female',
            birthDate: DateTime(2000, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Female emoji should appear
      expect(find.textContaining('\u{1F469}'), findsWidgets); // woman emoji
    });

    testWidgets('renders with birthTime', (tester) async {
      final artist = makeArtist();

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            birthDate: DateTime(2000, 1, 1),
            birthTime: '1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // convertKoreanTraditionalTime('1') = rat emoji
      expect(find.textContaining('\u{1F400}'), findsOneWidget);
    });

    testWidgets('renders without image (placeholder)', (tester) async {
      final artist = makeArtist(image: null);

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(artist: artist),
        ),
      );
      await tester.pumpAndSettle();

      // Should show person icon as placeholder
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with empty image string (placeholder)',
        (tester) async {
      final artist = makeArtist(image: '');

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(artist: artist),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with whitespace-only image string (placeholder)',
        (tester) async {
      final artist = makeArtist(image: '   ');

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(artist: artist),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders artist birth date from model', (tester) async {
      final artist = makeArtist(
        birthDate: DateTime(1995, 10, 13),
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(artist: artist),
        ),
      );
      await tester.pumpAndSettle();

      // Artist birth date should be formatted
      expect(find.text('1995.10.13'), findsOneWidget);
    });

    testWidgets('renders with all optional fields', (tester) async {
      final artist = makeArtist(gender: 'female');

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            birthDate: DateTime(1998, 3, 15),
            birthTime: '7',
            gender: 'female',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('지민'), findsOneWidget);
      // Horse emoji for birthTime '7'
      expect(find.textContaining('\u{1F40E}'), findsOneWidget);
    });

    testWidgets('renders with birthDate and nickname section',
        (tester) async {
      final artist = makeArtist();

      await tester.pumpWidget(
        buildTestApp(
          GoonghapCard(
            artist: artist,
            birthDate: DateTime(2000, 6, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When birthDate is provided, the user section is shown
      // The user's birthDate should be formatted
      expect(find.text('2000.06.15'), findsOneWidget);
      // Artist name should still be visible
      expect(find.text('지민'), findsOneWidget);
    });
  });
}
