import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

/// LateInitializationError/overflow는 실제 렌더 로직(빌드/헬퍼)에는 영향이 없으므로
/// vote_info_card_test.dart와 동일하게 억제한다.
Future<void> _ignoreRenderErrors(Future<void> Function() callback) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final exception = details.exception;
    if (exception is FlutterError &&
        exception.message.contains('overflowed')) {
      return;
    }
    if (exception.toString().contains('LateInitializationError')) {
      return;
    }
    original?.call(details);
  };
  try {
    await callback();
  } finally {
    FlutterError.onError = original;
  }
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
  });

  group('HomeFeaturedVoteCard widget rendering', () {
    testWidgets('renders title and rank-1 item only', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final rank1 = VoteItemFactory.create(
        id: 1,
        voteTotal: 12345,
        artist: ArtistFactory.create(
          id: 1,
          name: const {'ko': '지민', 'en': 'Jimin'},
        ),
      );
      final rank2 = VoteItemFactory.create(
        id: 2,
        voteTotal: 9999,
        artist: ArtistFactory.create(
          id: 2,
          name: const {'ko': '정국', 'en': 'Jungkook'},
        ),
      );
      final vote = VoteFactory.create(
        id: 1,
        title: const {'ko': '홈 투표 테스트', 'en': 'Home Vote Test'},
        voteItem: [rank1, rank2],
      );

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(HomeFeaturedVoteCard(vote: vote)),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(HomeFeaturedVoteCard), findsOneWidget);
        // 제목 렌더 확인
        expect(find.text('홈 투표 테스트'), findsOneWidget);
        // rank-1 항목 표수 렌더 확인
        expect(find.text('12345'), findsOneWidget);
        // rank-2는 렌더되지 않아야 함
        expect(find.text('9999'), findsNothing);
        expect(find.text('정국'), findsNothing);
      });
    });

    testWidgets('renders gracefully with empty vote items', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote = VoteFactory.create(
        id: 2,
        title: const {'ko': '빈 투표', 'en': 'Empty Vote'},
        voteItem: [],
      );

      await _ignoreRenderErrors(() async {
        await tester.pumpWidget(
          buildTestApp(HomeFeaturedVoteCard(vote: vote)),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(HomeFeaturedVoteCard), findsOneWidget);
        expect(find.text('빈 투표'), findsOneWidget);
      });
    });
  });
}
