import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/reward_list_section.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 고정된 리워드 목록을 돌려주는 프로바이더 대역.
class _FixedRewardList extends AsyncRewardList {
  _FixedRewardList(this._rewards);

  final List<RewardModel> _rewards;

  @override
  Future<List<RewardModel>> build() async => _rewards;
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

  Future<void> pump(WidgetTester tester, List<RewardModel> rewards) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        const SingleChildScrollView(child: RewardListSection()),
        extraOverrides: [
          asyncRewardListProvider.overrideWith(() => _FixedRewardList(rewards)),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    drainExpectedImageErrors(tester);
  }

  group('RewardListSection', () {
    testWidgets('renders reward cards', (WidgetTester tester) async {
      await pump(tester, const [
        RewardModel(
          id: 1,
          title: {'ko': '포토카드', 'en': 'Photocard'},
          thumbnail: 'https://example.com/thumb.jpg',
        ),
      ]);

      expect(find.byType(RewardListSection), findsOneWidget);
      expect(find.byKey(const ValueKey('reward_1')), findsOneWidget);
      expect(find.text('포토카드'), findsOneWidget);
    });

    testWidgets('reward with null title renders instead of crashing', (
      WidgetTester tester,
    ) async {
      // `RewardModel.title` 은 순수 nullable DB 컬럼이다 — 운영자가 제목을
      // 비워두면 실제로 널이 온다. `reward.title!` 로 되돌리면 그리드 카드가
      // RenderErrorBox 가 되어 여기서 널 단언이 터진다.
      await pump(tester, const [
        RewardModel(id: 1, title: null, thumbnail: null),
      ]);

      expect(find.byType(RewardListSection), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reward_1')),
        findsOneWidget,
        reason: '제목이 널이어도 카드는 계속 그려져야 한다',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: '제목이 널이면 빈 문자열로 접히고 카드는 계속 그려져야 한다',
      );
    });
  });
}
