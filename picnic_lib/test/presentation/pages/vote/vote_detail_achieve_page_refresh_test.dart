import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// #92 는 이 페이지의 'pull to refresh' 테스트를 삭제했다 — 당시엔
/// RefreshIndicator 자체가 없어서 몸통이 한 번도 실행되지 않는 죽은
/// 테스트였기 때문이다. 이 파일은 기능이 실제로 생긴 뒤의 진짜 버전이다.
Map<String, dynamic> _voteRow() {
  final now = DateTime.now().toUtc();
  return {
    'id': 1,
    'title': {'ko': '달성 투표', 'en': 'Achievement Vote'},
    'vote_category': 'achieve',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow() => {
      'id': 1,
      'vote_id': 1,
      'vote_total': 5000,
      'artist': {
        'id': 10,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': null,
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': null,
        },
      },
      'artist_group': null,
    };

Map<String, dynamic> _voteAchieveRow() => {
      'id': 1,
      'vote_id': 1,
      'reward_id': 1,
      'order': 1,
      'amount': 10000,
      'reward': {
        'id': 1,
        'title': {'ko': '포토카드'},
        'thumbnail': null,
      },
      'vote': _voteRow(),
    };

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [_voteRow()],
      'vote_item': [_voteItemRow()],
      'vote_achieve': [_voteAchieveRow()],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpUntilContent(WidgetTester tester) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 언마운트 후 배너 광고의 취소 불가 재시도(최대 25초)와 1초 폴링 타이머를
  /// 흘려보낸다 (vote_detail_achieve_page_loading_order_test.dart 와 동일).
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  group('VoteDetailAchievePage pull to refresh', () {
    testWidgets('drag down triggers a refetch of detail and item list', (
      tester,
    ) async {
      await pumpUntilContent(tester);
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // 초기 로드 요청은 제외하고 당김이 유발한 요청만 센다.
      capturedMockRequests.clear();

      // 사다리 스크롤 영역을 아래로 당긴다. 300ms 단위 pump 는 1초 폴링
      // 타이머에 닿지 않으면서 인디케이터 트리거+onRefresh 완료를 흘려보낸다.
      await tester.fling(
        find.byType(SingleChildScrollView).last,
        const Offset(0, 300),
        1000,
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        drainExpectedImageErrors(tester);
      }

      final refetched = capturedMockRequests.map((u) => u.path).toList();
      expect(
        refetched.any((p) => p.endsWith('/vote')),
        isTrue,
        reason: '당겨서-새로고침은 투표 상세를 다시 가져와야 한다: $refetched',
      );
      expect(
        refetched.any((p) => p.endsWith('/vote_item')),
        isTrue,
        reason: '당겨서-새로고침은 아이템 목록을 다시 가져와야 한다: $refetched',
      );

      await settle(tester);
    });

    testWidgets('ladder shorter than the viewport can still be pulled', (
      tester,
    ) async {
      // AlwaysScrollableScrollPhysics 가 없으면 내용이 짧을 때 오버스크롤
      // 자체가 불가능해 위 테스트만으로는 physics 누락을 못 잡는다.
      await pumpUntilContent(tester);

      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).last,
      );
      expect(
        scrollable.physics,
        isA<AlwaysScrollableScrollPhysics>(),
        reason: '사다리가 뷰포트보다 짧으면 기본 physics 로는 당길 수 없다',
      );

      await settle(tester);
    });
  });
}
