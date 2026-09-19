import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
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

    testWidgets('card image requests one device-independent CDN variant', (
      WidgetTester tester,
    ) async {
      // 크기를 지정하지 않으면 레이아웃 폭×DPR 로 요청해 기기마다 CDN 캐시
      // 키가 갈린다 — 리워드 12 썸네일 하나에 변형 375개, 사용자마다 첫
      // 조회가 1.5~3.5초 콜드였다(2026-09-19 실측).
      const reward = RewardModel(
        id: 1,
        title: {'ko': '포토카드', 'en': 'Photocard'},
        thumbnail: '/reward/thumb.jpg',
      );
      final urls = <String>[];
      for (final mq in const [
        MediaQueryData(size: Size(393, 852), devicePixelRatio: 3),
        MediaQueryData(size: Size(360, 780), devicePixelRatio: 2),
        MediaQueryData(size: Size(1024, 1366), devicePixelRatio: 2),
      ]) {
        tester.view.physicalSize = mq.size * mq.devicePixelRatio;
        tester.view.devicePixelRatio = mq.devicePixelRatio;
        await pump(tester, const [reward]);
        final image = tester.widget<PicnicCachedNetworkImage>(
          find.byKey(const ValueKey('reward_1')),
        );
        urls.add(image.imageRequest?.url ?? '<layout-dependent>');
      }
      addTearDown(tester.view.reset);

      expect(urls.toSet(), hasLength(1), reason: urls.join('\n'));
      // 큰 태블릿 카드(~976 물리 px)도 확대 없이 덮어야 한다.
      expect(RewardListSection.imageRequestWidth, greaterThanOrEqualTo(976));
      expect(Uri.parse(urls.first).queryParameters, {
        'q': '80',
        'w': '${RewardListSection.imageRequestWidth.toInt()}',
      });
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
