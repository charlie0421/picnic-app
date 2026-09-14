import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';

import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(loadTestFonts);

  setUp(() {
    initTestColors();
  });

  testWidgets('production period keeps its timezone at 320px and 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    addTearDown(tester.view.reset);
    const period = '2026.09.14 12:00 ~ 2026.12.31 23:59 KST';
    await tester.pumpWidget(
      buildTestApp(
        Center(
          child: Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 57.w),
              child: const VotePeriodLabel(period: period),
            ),
          ),
        ),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();
    final paragraph = tester.renderObject<RenderParagraph>(find.text(period));
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'The full deadline and timezone must remain visible.',
    );
    expect(tester.takeException(), isNull);
  });

  group('VoteCommonTitle', () {
    testWidgets('maxLines caps a long title instead of growing the header', (
      tester,
    ) async {
      // 좁은 폭 + 200% 확대에서 긴 제목이 화면을 다 차지하지 않도록 호출자가
      // 줄 수를 제한할 수 있다 (소멸 예정 캔디 안내 다이얼로그가 2줄로 제한).
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      addTearDown(tester.view.reset);
      const title = 'মেয়াদ শেষ হতে যাওয়া ক্যান্ডি নির্দেশিকা';
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 64),
              child: VoteCommonTitle(title: title, maxLines: 2),
            ),
          ),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(title).first,
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      final lineHeight = paragraph.getFullHeightForCaret(
        const TextPosition(offset: 0),
      );
      expect(paragraph.size.height, lessThanOrEqualTo(lineHeight * 2 + 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const VoteCommonTitle(title: 'Best Artist Award')),
      );
      await tester.pump();

      expect(find.byType(VoteCommonTitle), findsOneWidget);
      expect(find.text('Best Artist Award'), findsNWidgets(2)); // stroke + fill
    });

    testWidgets('renders with different title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const VoteCommonTitle(title: 'K-POP Vote')),
      );
      await tester.pump();

      expect(find.text('K-POP Vote'), findsNWidgets(2));
    });

    testWidgets('renders with long title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCommonTitle(
            title: 'This is a very long title that should overflow',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCommonTitle), findsOneWidget);
    });

    testWidgets('long title and period surfaces reflow at 320px and 200%', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      addTearDown(tester.view.reset);
      const titleKey = ValueKey('adaptive-vote-title');
      const periodKey = ValueKey('adaptive-vote-period');

      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              key: const ValueKey('adaptive-vote-host'),
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  VoteCommonTitle(
                    key: titleKey,
                    title: '아주 긴 아티스트 응원 투표 제목입니다',
                  ),
                  SizedBox(height: 12),
                  VotePeriodLabel(
                    key: periodKey,
                    period: '2026.09.14 12:00 - 2026.12.31 23:59',
                  ),
                ],
              ),
            ),
          ),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(titleKey)).height, greaterThan(48));
      expect(tester.getSize(find.byKey(periodKey)).height, greaterThan(34));
      for (final element in find.text('아주 긴 아티스트 응원 투표 제목입니다').evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: 'The complete vote title must remain readable at 200%.',
        );
        final titleRect = tester.getRect(find.byKey(titleKey));
        final textRect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
        expect(textRect.bottom, lessThanOrEqualTo(titleRect.bottom));
      }

      final hostRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-vote-host')),
      );
      for (final key in [titleKey, periodKey]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(hostRect.left));
        expect(rect.right, lessThanOrEqualTo(hostRect.right));
      }
    });
  });
}
