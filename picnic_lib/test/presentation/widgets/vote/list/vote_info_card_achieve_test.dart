import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_achieve.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({int id = 1}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
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

VoteItemModel _voteItem({int voteTotal = 50000}) {
  return VoteItemModel.fromJson({
    'id': 1,
    'vote_id': 1,
    'vote_total': voteTotal,
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
  });
}

/// [nullThumbnail] 은 운영자가 보상 이미지를 비워둔 행을 재현한다.
/// `RewardModel.thumbnail` 은 순수 nullable DB 컬럼이다.
VoteAchieve _voteAchieve({int amount = 10000, bool nullThumbnail = false}) {
  return VoteAchieve.fromJson({
    'id': 1,
    'vote_id': 1,
    'reward_id': 1,
    'order': 1,
    'amount': amount,
    'reward': {
      'id': 1,
      'title': {'ko': '포토카드'},
      'thumbnail': nullThumbnail ? null : 'https://example.com/thumb.jpg',
    },
    'vote': _voteRow(),
  });
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

  Future<void> pump(WidgetTester tester, VoteAchieve rank) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        VoteCardColumnAchieve(
          voteItem: _voteItem(),
          rank: rank,
          opacityAnimation: const AlwaysStoppedAnimation<double>(1.0),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    drainExpectedImageErrors(tester);
  }

  group('VoteCardColumnAchieve', () {
    testWidgets('renders with thumbnail', (WidgetTester tester) async {
      await pump(tester, _voteAchieve());

      expect(find.byType(VoteCardColumnAchieve), findsOneWidget);
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });

    testWidgets('reward with null thumbnail renders instead of crashing', (
      WidgetTester tester,
    ) async {
      // `RewardModel.thumbnail` 은 순수 nullable DB 컬럼이다 — 운영자가
      // 이미지를 안 올리면 실제로 널이 온다. `rank.reward.thumbnail!` 로
      // 되돌리면 달성 카드 전체가 RenderErrorBox 가 되어 여기서 터진다.
      await pump(tester, _voteAchieve(nullThumbnail: true));

      expect(find.byType(VoteCardColumnAchieve), findsOneWidget);
      expect(
        find.byType(PicnicCachedNetworkImage),
        findsOneWidget,
        reason: '썸네일이 널이면 빈 URL 로 접히고 카드는 계속 그려져야 한다',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: '썸네일이 널이어도 달성 카드가 에러 박스가 되면 안 된다',
      );
    });
  });
}
