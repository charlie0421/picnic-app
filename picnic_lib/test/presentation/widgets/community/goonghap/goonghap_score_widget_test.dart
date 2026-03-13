import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_score_widget.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '정국', 'en': 'Jungkook'},
    gender: 'male',
  );

  setUp(() {
    initTestColors();
  });

  group('GoonghapScoreWidget', () {
    testWidgets('renders empty when goonghap is null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapScoreWidget(goonghap: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders paid result with AnimatedGoonghapBar', (tester) async {
      final goonghap = GoonghapModel(
        id: 'g1',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
        localizedResults: {
          'ko': const LocalizedGoonghap(
            language: 'ko',
            score: 85,
            scoreTitle: '최고의 궁합',
            goonghapSummary: '환상적인 케미!',
          ),
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('최고의 궁합'), findsOneWidget);
    });

    testWidgets('renders unpaid result with purchase message', (tester) async {
      final goonghap = GoonghapModel(
        id: 'g2',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: false,
        localizedResults: {
          'ko': const LocalizedGoonghap(
            language: 'ko',
            score: 75,
            scoreTitle: '좋은 궁합',
          ),
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
        ),
      );
      await tester.pumpAndSettle();

      // Should not show AnimatedGoonghapBar for unpaid
      expect(find.byType(AnimatedGoonghapBar), findsNothing);
      // Should show the gradient container with purchase message
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('renders with no localizedResults (goonghap non-null)',
        (tester) async {
      final goonghap = GoonghapModel(
        id: 'g3',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.pending,
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
        ),
      );
      await tester.pumpAndSettle();

      // Should render gradient container (not AnimatedGoonghapBar)
      expect(find.byType(AnimatedGoonghapBar), findsNothing);
      expect(find.byType(GoonghapScoreWidget), findsOneWidget);
    });

    testWidgets('falls back to en locale when ko not available',
        (tester) async {
      final goonghap = GoonghapModel(
        id: 'g4',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
        localizedResults: {
          'en': const LocalizedGoonghap(
            language: 'en',
            score: 92,
            scoreTitle: 'Perfect Match',
          ),
        },
      );

      // Use ja locale so it falls back to en
      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
          locale: const Locale('ja'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
    });

    testWidgets('falls back to first available language', (tester) async {
      final goonghap = GoonghapModel(
        id: 'g5',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
        localizedResults: {
          'ja': const LocalizedGoonghap(
            language: 'ja',
            score: 60,
            scoreTitle: 'まあまあ',
          ),
        },
      );

      // Use vi locale (not available), should fall back to ja (first available)
      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
          locale: const Locale('vi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('renders with score 0', (tester) async {
      final goonghap = GoonghapModel(
        id: 'g6',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
        localizedResults: {
          'ko': const LocalizedGoonghap(
            language: 'ko',
            score: 0,
            scoreTitle: '궁합이 맞지 않아요',
          ),
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders with score 100', (tester) async {
      final goonghap = GoonghapModel(
        id: 'g7',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
        localizedResults: {
          'ko': const LocalizedGoonghap(
            language: 'ko',
            score: 100,
            scoreTitle: '운명의 상대!',
          ),
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          GoonghapScoreWidget(goonghap: goonghap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
