import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_vs.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/pixel_probe.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 픽셀 검사가 스켈레톤만 정확히 잡도록 테스트가 직접 심는 캡처 경계.
const Key _boundary = ValueKey('vote_card_skeleton_vs_capture');

/// 카드 흰 배경과 구분되는 테스트 전용 페이지 배경.
/// (자세한 이유는 vote_card_skeleton_active_and_end_test.dart 참고.)
const Color _pageBackdrop = Color(0xFF2244AA);

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(tearDownMockSupabase);

  /// 프로덕션과 동일한 ScreenUtil 기준(393x892)으로 띄운다. 시간을 진행시키지
  /// 않으므로 Shimmer 애니메이션 0 지점 — 픽셀 단언이 위상에 흔들리지 않는다.
  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 892) * 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildTestApp(
        const RepaintBoundary(
          key: _boundary,
          child: ColoredBox(
            color: _pageBackdrop,
            child: VoteCardSkeletonVS(),
          ),
        ),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    await tester.pump();
  }

  const blockKeys = [
    VoteCardSkeletonVSKeys.title,
    VoteCardSkeletonVSKeys.timer,
    VoteCardSkeletonVSKeys.leftAvatar,
    VoteCardSkeletonVSKeys.leftLabel,
    VoteCardSkeletonVSKeys.vsBadge,
    VoteCardSkeletonVSKeys.rightAvatar,
    VoteCardSkeletonVSKeys.rightLabel,
  ];

  group('VoteCardSkeletonVS', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCardSkeletonVS(),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonVS), findsOneWidget);
    });

    // Shimmer 는 자식을 BlendMode.srcIn ShaderMask 로 덮는다. 불투명한 흰 카드
    // 프레임이 Shimmer 안에 있으면 그 위의 블록들이 배경과 한 덩어리로 칠해져
    // 라운드 회색 사각형 하나만 남는다(수정 전 상태).
    testWidgets('frames sit outside the shimmer, blocks inside', (
      tester,
    ) async {
      await pump(tester);

      final shimmer = find.byType(Shimmer);
      expect(
        shimmer,
        findsNWidgets(2),
        reason: '헤더 카드와 VS 아이템 카드가 각자 자기 Shimmer 를 든다',
      );

      for (final frameKey in [
        VoteCardSkeletonVSKeys.headerFrame,
        VoteCardSkeletonVSKeys.itemFrame,
      ]) {
        final frame = find.byKey(frameKey);
        expect(frame, findsOneWidget);
        expect(
          find.descendant(of: shimmer, matching: frame),
          findsNothing,
          reason: '불투명한 카드 프레임($frameKey)은 Shimmer 밖에 있어야 한다',
        );
        expect(
          find.descendant(of: frame, matching: shimmer),
          findsOneWidget,
          reason: '$frameKey 는 자기 Shimmer 를 직접 들고 있어야 한다',
        );
      }

      for (final key in blockKeys) {
        expect(
          find.descendant(of: shimmer, matching: find.byKey(key)),
          findsOneWidget,
          reason: '$key 블록은 Shimmer 안에서 반짝여야 한다',
        );
      }
      expect(tester.takeException(), isNull);
    });

    // 위젯 트리 단언은 우회로 무력화될 수 있으므로 실제로 칠해진 픽셀을 본다.
    testWidgets('paints grey blocks on white cards', (tester) async {
      await pump(tester);

      final probe = await capturePixels(tester, find.byKey(_boundary));
      final headerRect = tester.getRect(
        find.byKey(VoteCardSkeletonVSKeys.headerFrame),
      );
      final itemRect = tester.getRect(
        find.byKey(VoteCardSkeletonVSKeys.itemFrame),
      );

      // 0. 캡처가 카드 바깥(위쪽 margin)까지 담는지부터 확인한다.
      expect(
        probe.at(Offset(headerRect.center.dx, headerRect.top - 2)),
        colorHex(_pageBackdrop),
        reason: '카드 위쪽 margin 에는 페이지 배경이 보여야 한다',
      );

      // 1. 블록은 셔머 베이스 색으로 칠해져야 한다.
      for (final key in blockKeys) {
        expect(
          probe.at(tester.getRect(find.byKey(key)).center),
          colorHex(AppColors.grey300),
          reason: '$key 중앙이 셔머 베이스 색이어야 한다',
        );
      }

      // 2. 프레임 안 여백에는 카드 흰 배경이 그대로 보여야 한다. 프레임이
      //    Shimmer 안에 있으면 srcIn 이 여백까지 회색으로 칠해 여기서 깨진다.
      final titleRect = tester.getRect(
        find.byKey(VoteCardSkeletonVSKeys.title),
      );
      final timerRect = tester.getRect(
        find.byKey(VoteCardSkeletonVSKeys.timer),
      );
      expect(timerRect.top - titleRect.bottom, greaterThan(1));
      expect(
        probe.at(
          Offset(titleRect.center.dx, (titleRect.bottom + timerRect.top) / 2),
        ),
        colorHex(VoteCardSkeletonVS.cardColor),
        reason: '제목과 타이머 블록 사이에서 카드 배경이 보여야 한다',
      );
      // VS 아이템 카드: 왼쪽 아바타와 VS 뱃지 사이 여백.
      final leftAvatarRect = tester.getRect(
        find.byKey(VoteCardSkeletonVSKeys.leftAvatar),
      );
      final vsRect = tester.getRect(find.byKey(VoteCardSkeletonVSKeys.vsBadge));
      expect(vsRect.left - leftAvatarRect.right, greaterThan(1));
      expect(
        probe.at(
          Offset((leftAvatarRect.right + vsRect.left) / 2, vsRect.center.dy),
        ),
        colorHex(VoteCardSkeletonVS.cardColor),
        reason: '아바타와 VS 뱃지 사이에서 카드 배경이 보여야 한다',
      );

      // 3. 두 카드 사이 간격에는 페이지 배경이 보여야 한다.
      expect(itemRect.top - headerRect.bottom, greaterThan(1));
      expect(
        probe.at(
          Offset(headerRect.center.dx, (headerRect.bottom + itemRect.top) / 2),
        ),
        colorHex(_pageBackdrop),
        reason: '두 카드 사이에는 페이지 배경이 보여야 한다',
      );

      expect(tester.takeException(), isNull);
    });
  });
}
