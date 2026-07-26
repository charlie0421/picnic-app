import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_skeleton.dart';
import 'package:shimmer/shimmer.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/pixel_probe.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 픽셀 검사가 스켈레톤만 정확히 잡도록 테스트가 직접 심는 캡처 경계.
///
/// 명시적으로 두지 않으면 캡처 범위가 위로 올라가며 처음 만나는 repaint
/// boundary 로 정해져, 호스트 위젯을 바꾸는 순간 조용히 달라진다.
const Key _boundary = ValueKey('vote_detail_skeleton_capture');

/// 카드 흰 배경과 구분되는 테스트 전용 페이지 배경.
///
/// 프로덕션 배경은 흰색(`vote_detail_page.dart` 의 `Container(color:
/// AppColors.grey00)`)이라 그대로 두면 "블록 사이로 카드 배경이 비친다" 와
/// "카드 프레임이 아예 없다" 가 똑같은 흰 픽셀로 나온다. 프레임을 통째로
/// 지워 버리는 수정이 초록으로 통과하지 못하도록 여기서만 다른 색을 깐다.
const Color _pageBackdrop = Color(0xFF2244AA);

const _devices = <String, Size>{
  'small Android (360x640)': Size(360, 640),
  'iPhone 17 Pro (402x874)': Size(402, 874),
};

void _useDevice(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
}

/// 여러 블록이 함께 이루는 사각형.
Rect _unionRect(WidgetTester tester, List<Key> keys) => keys
    .map((key) => tester.getRect(find.byKey(key)))
    .reduce((a, b) => a.expandToInclude(b));

/// 프로덕션과 동일한 ScreenUtil 기준으로 띄운다.
///
/// 하네스 기본값([kLegacyTestDesignSize])은 실제 앱(393x892 + splitScreenMode)과
/// 달라 `.w` / `.r` 환산이 어긋난다. 이 스켈레톤의 여백·라운드는 전부 `.r` /
/// `.w` 로 잡혀 있어 기준이 다르면 앱에 존재하지 않는 기하를 재게 된다.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    buildTestApp(
      RepaintBoundary(
        key: _boundary,
        child: ColoredBox(color: _pageBackdrop, child: child),
      ),
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
    ),
  );
  // 시간을 진행시키지 않는다. Shimmer 는 initState 에서 forward() 를 걸므로 이
  // 프레임은 애니메이션 0 지점 — 그라디언트 창이 자식 왼쪽 바깥에 있어 마스크가
  // 자식 전체를 baseColor 하나로 칠한다. 픽셀 단언이 위상에 흔들리지 않는다.
  await tester.pump();
}

/// `vote_detail_page.dart` 의 아이템 로딩 브랜치와 같은 사용법: 카드만 단독으로,
/// 감싸 주는 Shimmer 없이 놓는다.
///
/// [VoteDetailSkeleton.buildVoteListOnly] 는 `.w` / `.r` 을 즉시 계산하므로
/// ScreenUtilInit 아래에서 호출해야 한다 — [Builder] 가 그 자리를 만든다.
Future<void> _pumpVoteList(WidgetTester tester) => _pump(
      tester,
      SingleChildScrollView(
        child: Builder(builder: (_) => VoteDetailSkeleton.buildVoteListOnly()),
      ),
    );

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(tearDownMockSupabase);

  group('VoteDetailSkeleton vote list card', () {
    // Shimmer 는 자식을 BlendMode.srcIn ShaderMask 로 덮는다. 카드의 불투명한
    // 흰 배경이 Shimmer 안에 있으면 그 위의 검색바와 5개 아이템 행이 배경과
    // 함께 한 덩어리로 칠해져, 라운드 회색 사각형 하나만 남는다(수정 전 상태).
    testWidgets('frame sits outside the shimmer', (tester) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpVoteList(tester);

      final shimmer = find.byType(Shimmer);
      final frame = find.byKey(VoteDetailSkeletonKeys.voteListFrame);
      expect(
        shimmer,
        findsOneWidget,
        reason: '카드는 호출부에 기대지 말고 자기 Shimmer 를 직접 들고 있어야 한다 '
            '— vote_detail_page 의 아이템 로딩 브랜치는 Shimmer 로 감싸 주지 않는다',
      );
      expect(frame, findsOneWidget);
      expect(find.ancestor(of: shimmer, matching: frame), findsOneWidget);
      expect(
        find.descendant(of: shimmer, matching: frame),
        findsNothing,
        reason: '불투명한 카드 프레임은 Shimmer 밖에 있어야 한다',
      );
    });

    testWidgets('every block shimmers and stays inside the frame', (
      tester,
    ) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpVoteList(tester);

      final shimmer = find.byType(Shimmer);
      final frameRect = tester.getRect(
        find.byKey(VoteDetailSkeletonKeys.voteListFrame),
      );
      final rows = VoteDetailSkeletonKeys.listRowsTopToBottom;

      var previousBottom = frameRect.top;
      for (final row in rows) {
        for (final key in row) {
          final block = find.byKey(key);
          expect(block, findsOneWidget, reason: '$key 블록이 없다');
          expect(
            find.descendant(of: shimmer, matching: block),
            findsOneWidget,
            reason: '$key 는 Shimmer 안에서 반짝여야 한다',
          );
          final rect = tester.getRect(block);
          expect(
            frameRect.inflate(0.01).contains(rect.topLeft),
            isTrue,
            reason: '$key 가 카드 프레임 밖으로 나갔다',
          );
          expect(
            frameRect.inflate(0.01).contains(rect.bottomRight),
            isTrue,
            reason: '$key 가 카드 프레임 밖으로 나갔다',
          );
        }
        final rowRect = _unionRect(tester, row);
        expect(
          rowRect.top,
          greaterThanOrEqualTo(previousBottom - 0.01),
          reason: '$row 가 위 행과 겹친다 — 순서가 어긋났다',
        );
        previousBottom = rowRect.bottom;
      }

      // 아이템 행 안쪽은 순위 / 썸네일 / 이름·점수 / 액션 순으로 왼쪽에서
      // 오른쪽으로 놓인다. 열이 겹치면 실제 아이템 행처럼 읽히지 않는다.
      for (var i = 0; i < VoteDetailSkeletonKeys.itemCount; i++) {
        var previousRight = double.negativeInfinity;
        for (final column in VoteDetailSkeletonKeys.itemColumnsLeftToRight(i)) {
          final rect = _unionRect(tester, column);
          expect(
            rect.left,
            greaterThanOrEqualTo(previousRight - 0.01),
            reason: '아이템 $i 의 $column 열이 왼쪽 열과 겹친다',
          );
          previousRight = rect.right;
        }
      }

      expect(tester.takeException(), isNull);
    });

    // 이 테스트가 이 스위트의 핵심이다. 위젯 종류로 "불투명 배경 금지" 를 잡으려
    // 하면 Material(color: ...) 로도, 1px 안쪽으로 들여놓은 ColoredBox 로도,
    // 블록을 2x2 로 줄여도 전부 초록이 뜬다. 실제로 칠해진 픽셀을 본다.
    for (final entry in _devices.entries) {
      testWidgets('paints grey blocks on a white card on ${entry.key}', (
        tester,
      ) async {
        _useDevice(tester, entry.value);
        await _pumpVoteList(tester);

        final probe = await capturePixels(tester, find.byKey(_boundary));
        final frameRect = tester.getRect(
          find.byKey(VoteDetailSkeletonKeys.voteListFrame),
        );
        final rows = VoteDetailSkeletonKeys.listRowsTopToBottom;

        // 0. 캡처가 실제로 카드 바깥까지 담고 있는지부터 확인한다. 이게 없으면
        //    아래 "여백은 흰색" 단언이 프레임을 통째로 지운 뒤에도 통과할 수 있다
        //    (프로덕션 페이지 배경도 흰색이라 구분이 안 된다).
        expect(
          probe.at(Offset(frameRect.center.dx, frameRect.top - 8)),
          colorHex(_pageBackdrop),
          reason: '카드 위쪽 margin 에는 페이지 배경이 보여야 한다',
        );

        // 1. 블록은 실제로 회색으로 칠해져야 한다. 바 자체는 흰색이고, Shimmer 의
        //    srcIn 마스크가 색을 baseColor 로 갈아끼운 결과만 흰 카드 배경과
        //    구분된다. 마스크가 걷히거나 블록이 사라지면 흰색이 온다.
        for (final row in rows) {
          for (final key in row) {
            expect(
              probe.at(tester.getRect(find.byKey(key)).center),
              colorHex(VoteDetailSkeleton.shimmerBaseColor),
              reason: '$key 중앙이 셔머 베이스 색으로 칠해져 있어야 한다 '
                  '— 흰색이면 카드 배경과 구분되지 않아 사용자에겐 없는 것과 같다',
            );
          }
        }

        // 2. 행 사이 여백에는 카드 흰 배경이 그대로 보여야 한다. Shimmer 안에
        //    불투명한 무언가가 있으면 — 위젯 종류가 무엇이든, 1px 안쪽으로
        //    들여놨든 — srcIn 이 여백까지 회색으로 칠해 여기서 깨진다.
        for (var i = 1; i < rows.length; i++) {
          final above = _unionRect(tester, rows[i - 1]);
          final below = _unionRect(tester, rows[i]);
          expect(
            below.top - above.bottom,
            greaterThan(1),
            reason: '${rows[i - 1]} 와 ${rows[i]} 사이에 여백이 없다',
          );
          expect(
            probe.at(
              Offset(frameRect.center.dx, (above.bottom + below.top) / 2),
            ),
            colorHex(VoteDetailSkeleton.cardColor),
            reason: '${rows[i - 1]} 와 ${rows[i]} 사이에서 카드 배경이 보여야 한다 '
                '— 회색이면 Shimmer 안의 불투명 배경이 골격을 통째로 삼킨 것이다',
          );
        }
        // 카드 좌우 안쪽 여백도 마찬가지.
        for (final dx in [frameRect.left + 6, frameRect.right - 6]) {
          expect(
            probe.at(Offset(dx, frameRect.center.dy)),
            colorHex(VoteDetailSkeleton.cardColor),
            reason: '카드 좌우 여백에서 카드 배경이 보여야 한다',
          );
        }

        // 3. 골격이 카드를 실제로 채워야 한다. 블록을 점처럼 줄여 놓고 "블록이
        //    존재한다 + 중앙이 회색이다" 만 만족시키는 회귀를 여기서 잡는다.
        //    반대로 1.0 에 가까우면 여백이 사라져 다시 단색 덩어리라는 뜻이다.
        //    현재 실측 0.35~0.36 (블록 면적 합 / 카드 면적).
        final painted = probe.fractionNot(
          VoteDetailSkeleton.cardColor,
          frameRect.deflate(6),
        );
        expect(
          painted,
          inInclusiveRange(0.28, 0.45),
          reason: '카드 면적의 1/4 이상이 골격으로 덮여야 목록처럼 읽힌다 '
              '(너무 꽉 차면 여백이 사라져 단색 덩어리가 된다). 실측 $painted',
        );
      });
    }
  });

  group('VoteDetailSkeleton full page', () {
    testWidgets('keeps the list frame out of every shimmer', (tester) async {
      _useDevice(tester, const Size(402, 874));
      await _pump(tester, const VoteDetailSkeleton());

      final frame = find.byKey(VoteDetailSkeletonKeys.voteListFrame);
      expect(frame, findsOneWidget);
      expect(
        find.byType(Shimmer),
        findsNWidgets(2),
        reason: '상단 영역과 목록 카드가 각각 자기 Shimmer 를 든다',
      );
      expect(
        find.descendant(of: find.byType(Shimmer), matching: frame),
        findsNothing,
        reason: '페이지 최상위를 Shimmer 로 감싸면 카드 배경이 srcIn 에 먹혀 '
            '목록 전체가 구조 없는 회색 덩어리가 된다 — 이게 원래 버그였다',
      );
      for (final key in VoteDetailSkeletonKeys.listRowsTopToBottom.expand(
        (row) => row,
      )) {
        expect(
          find.descendant(of: frame, matching: find.byKey(key)),
          findsOneWidget,
          reason: '$key 가 카드 안에 있어야 한다',
        );
      }
      expect(tester.takeException(), isNull);
    });

    // 상단 영역은 카드 없이 페이지 배경 위에 바로 놓인다. 여기에 불투명 배경이
    // 끼어들면 같은 방식으로 헤더/제목/날짜/버튼이 한 덩어리가 된다.
    testWidgets('paints the top blocks straight on the page background', (
      tester,
    ) async {
      _useDevice(tester, const Size(402, 874));
      await _pump(tester, const VoteDetailSkeleton());

      final probe = await capturePixels(tester, find.byKey(_boundary));
      final rows = VoteDetailSkeletonKeys.topRowsTopToBottom;

      for (final row in rows) {
        for (final key in row) {
          expect(
            probe.at(tester.getRect(find.byKey(key)).center),
            colorHex(VoteDetailSkeleton.shimmerBaseColor),
            reason: '$key 중앙이 셔머 베이스 색으로 칠해져 있어야 한다',
          );
        }
      }

      final centerX = tester.getRect(find.byKey(_boundary)).center.dx;
      for (var i = 1; i < rows.length; i++) {
        final above = _unionRect(tester, rows[i - 1]);
        final below = _unionRect(tester, rows[i]);
        expect(below.top - above.bottom, greaterThan(1));
        expect(
          probe.at(Offset(centerX, (above.bottom + below.top) / 2)),
          colorHex(_pageBackdrop),
          reason: '${rows[i - 1]} 와 ${rows[i]} 사이에서 페이지 배경이 보여야 한다 '
              '— 회색이면 상단 Shimmer 안에 불투명 배경이 들어간 것이다',
        );
      }

      expect(tester.takeException(), isNull);
    });
  });
}
