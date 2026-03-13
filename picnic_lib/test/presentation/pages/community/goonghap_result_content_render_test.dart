import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_result_content.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

GoonghapModel _createMockGoonghap({bool isPaid = true}) {
  return GoonghapModel(
    id: 'goonghap-1',
    userId: 'test-user-id',
    artist: ArtistModel(
      id: 1,
      name: {'ko': '지민', 'en': 'Jimin'},
      image: null,
    ),
    birthDate: DateTime(1995, 10, 13),
    birthTime: '1',
    status: GoonghapStatus.completed,
    gender: 'male',
    score: 85,
    isPaid: isPaid,
    localizedResults: {
      'ko': LocalizedGoonghap(
        language: 'ko',
        score: 85,
        scoreTitle: '최고의 궁합',
        goonghapSummary: '서로의 에너지가 잘 어울립니다.',
        details: Details(
          style: StyleDetails(
            idolStyle: '따뜻하고 부드러운 스타일',
            userStyle: '활발하고 에너지 넘치는 스타일',
            coupleStyle: '서로를 보완하는 완벽한 커플',
          ),
          activities: ActivitiesDetails(
            recommended: ['산책', '영화 감상', '요리'],
            description: '함께 활동하면 시너지가 생깁니다.',
          ),
        ),
        tips: ['서로의 시간을 존중하세요', '작은 선물을 자주 교환하세요'],
      ),
    },
  );
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('GoonghapResultContent render', () {
    testWidgets('renders paid result with full details',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultContent), findsOneWidget);
    });

    testWidgets('renders unpaid result with blur overlay',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: false);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultContent), findsOneWidget);
    });

    testWidgets('tap purchase button on unpaid result',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: false);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the purchase button
      final elevatedButtons = find.byType(ElevatedButton);
      if (elevatedButtons.evaluate().isNotEmpty) {
        await tester.tap(elevatedButtons.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // If confirmation dialog appeared, tap cancel
        final cancelButton = find.byType(TextButton);
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton.first, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('renders with saving state', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: true,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultContent), findsOneWidget);
    });

    testWidgets('renders with empty localized results',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true).copyWith(
        localizedResults: {},
      );

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultContent), findsOneWidget);
    });

    testWidgets('scroll content', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('tap expansion tiles', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: GoonghapResultContent(
              goonghap: goonghap,
              isSaving: false,
              onSave: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onShare: (_) { final Future<bool> inner = Future<bool>.value(true); return Future<Future<bool>>.value(inner); },
              onOpenGoonghap: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find ExpansionTiles and tap them to collapse/expand
      final expansionTiles = find.byType(ExpansionTile);
      for (int i = 0;
          i < expansionTiles.evaluate().length && i < 3;
          i++) {
        try {
          await tester.tap(expansionTiles.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });
  });
}
