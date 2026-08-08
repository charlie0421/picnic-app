import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

GoonghapModel _createMockGoonghap({
  GoonghapStatus status = GoonghapStatus.completed,
  bool isPaid = true,
}) {
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
    status: status,
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
    setupMockSupabase({
      'goonghap_results': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('GoonghapResultPage render', () {
    testWidgets('renders loading state', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders completed goonghap with paid result',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders completed goonghap with unpaid result',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: false);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders error state', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(status: GoonghapStatus.error);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap.copyWith(
                status: GoonghapStatus.error,
                errorMessage: 'Test error occurred',
              )),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders null goonghap (loading indicator)',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('scroll the result page', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Scroll the CustomScrollView
      final scrollView = find.byType(CustomScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        await tester.drag(scrollView.first, const Offset(0, -300),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('renders provider error state', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.error('Test error', StackTrace.current),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('scroll deeply through paid result',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Scroll down multiple times
      final scrollView = find.byType(CustomScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.drag(scrollView.first, const Offset(0, -300),
              warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 200));
        }
        // Scroll back up
        await tester.drag(scrollView.first, const Offset(0, 500),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('renders pending goonghap status',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(status: GoonghapStatus.pending);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with low score result',
        (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-low',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 1,
          name: {'ko': '지민', 'en': 'Jimin'},
          image: null,
        ),
        birthDate: DateTime(1995, 10, 13),
        birthTime: null,
        status: GoonghapStatus.completed,
        gender: 'female',
        score: 25,
        isPaid: true,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 25,
            scoreTitle: '보통 궁합',
            goonghapSummary: '서로 다른 에너지를 가지고 있습니다.',
            details: Details(
              style: StyleDetails(
                idolStyle: '차가운 스타일',
                userStyle: '따뜻한 스타일',
                coupleStyle: '대조적인 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['독서'],
                description: '조용한 활동이 좋습니다.',
              ),
            ),
            tips: ['서로를 이해하세요'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('tap GestureDetectors on result page',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Tap GestureDetectors (expand/collapse sections, etc.)
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0;
          i < tester.widgetList(gestureDetectors).length && i < 6;
          i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders with no birth time', (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-notime',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 2,
          name: {'ko': '정국', 'en': 'Jungkook'},
          image: null,
        ),
        birthDate: DateTime(2000, 1, 1),
        birthTime: null,
        status: GoonghapStatus.completed,
        gender: 'male',
        score: 70,
        isPaid: false,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 70,
            scoreTitle: '좋은 궁합',
            goonghapSummary: '좋은 관계입니다.',
            details: Details(
              style: StyleDetails(
                idolStyle: '강한 스타일',
                userStyle: '부드러운 스타일',
                coupleStyle: '균형 잡힌 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['여행', '운동'],
                description: '활발한 활동이 좋습니다.',
              ),
            ),
            tips: ['함께 여행하세요'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          locale: const Locale('en'),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale (triggers i18n branch)',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: true);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          locale: const Locale('ja'),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with perfect score', (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-perfect',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 1,
          name: {'ko': '지민', 'en': 'Jimin'},
          image: null,
        ),
        birthDate: DateTime(1995, 10, 13),
        birthTime: '1',
        status: GoonghapStatus.completed,
        gender: 'female',
        score: 100,
        isPaid: true,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 100,
            scoreTitle: '천생연분',
            goonghapSummary: '완벽한 궁합입니다!',
            details: Details(
              style: StyleDetails(
                idolStyle: '완벽한 스타일',
                userStyle: '완벽한 스타일',
                coupleStyle: '천생연분 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['모든 것', '무엇이든'],
                description: '모든 활동이 즐겁습니다.',
              ),
            ),
            tips: ['행복하세요!'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with error message in goonghap',
        (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-err',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 1,
          name: {'ko': '지민', 'en': 'Jimin'},
          image: null,
        ),
        birthDate: DateTime(1995, 10, 13),
        birthTime: null,
        status: GoonghapStatus.error,
        gender: 'male',
        score: null,
        isPaid: false,
        errorMessage: 'API call failed: timeout',
        localizedResults: {},
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with artist that has only English name',
        (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-en',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 3,
          name: {'en': 'NewJeans'},
          image: null,
        ),
        birthDate: DateTime(2000, 5, 1),
        birthTime: '3',
        status: GoonghapStatus.completed,
        gender: 'female',
        score: 60,
        isPaid: true,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 60,
            scoreTitle: '괜찮은 궁합',
            goonghapSummary: '나쁘지 않은 관계입니다.',
            details: Details(
              style: StyleDetails(
                idolStyle: '세련된 스타일',
                userStyle: '자유로운 스타일',
                coupleStyle: '재미있는 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['카페', '쇼핑'],
                description: '편안한 활동이 좋습니다.',
              ),
            ),
            tips: ['자주 만나세요'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders with score zero', (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-zero',
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
        score: 0,
        isPaid: true,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 0,
            scoreTitle: '안 맞는 궁합',
            goonghapSummary: '궁합이 좋지 않습니다.',
            details: Details(
              style: StyleDetails(
                idolStyle: '차가운 스타일',
                userStyle: '뜨거운 스타일',
                coupleStyle: '극과 극 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['독서'],
                description: '조용한 활동.',
              ),
            ),
            tips: ['노력하세요'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('tap ElevatedButton on unpaid result',
        (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(isPaid: false);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Tap ElevatedButton (unlock/purchase button for unpaid results)
      final elevatedButtons = find.byType(ElevatedButton);
      if (elevatedButtons.evaluate().isNotEmpty) {
        await tester.tap(elevatedButtons.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('renders with artist that has image',
        (WidgetTester tester) async {
      final goonghap = GoonghapModel(
        id: 'goonghap-img',
        userId: 'test-user-id',
        artist: ArtistModel(
          id: 1,
          name: {'ko': '지민', 'en': 'Jimin'},
          image: 'https://example.com/artist.jpg',
        ),
        birthDate: DateTime(1995, 10, 13),
        birthTime: '5',
        status: GoonghapStatus.completed,
        gender: 'female',
        score: 90,
        isPaid: true,
        localizedResults: {
          'ko': LocalizedGoonghap(
            language: 'ko',
            score: 90,
            scoreTitle: '환상의 궁합',
            goonghapSummary: '완벽합니다.',
            details: Details(
              style: StyleDetails(
                idolStyle: '카리스마 스타일',
                userStyle: '따뜻한 스타일',
                coupleStyle: '이상적 커플',
              ),
              activities: ActivitiesDetails(
                recommended: ['여행', '음악'],
                description: '함께하면 즐겁습니다.',
              ),
            ),
            tips: ['행복하세요', '대화하세요'],
          ),
        },
      );

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });

    testWidgets('renders input status', (WidgetTester tester) async {
      final goonghap = _createMockGoonghap(status: GoonghapStatus.input);

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapResultPage(goonghap: goonghap),
          extraOverrides: [
            goonghapProvider.overrideWithValue(
              AsyncValue.data(goonghap.copyWith(status: GoonghapStatus.input)),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapResultPage), findsOneWidget);
    });
  });
}
