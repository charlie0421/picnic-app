import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

const _title = '다가오는 생일 축하 투표에 참여할 아티스트를 선택하세요';

class _LayoutVotes extends AsyncVoteList {
  static int requestCount = 0;
  _LayoutVotes(this.itemCount, this.voteCount);
  final int itemCount;
  final int voteCount;

  @override
  Future<List<VoteModel>> build(
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  }) async {
    requestCount++;
    final upcoming = status == VoteStatus.upcoming;
    return [
      for (var voteIndex = 0; voteIndex < voteCount; voteIndex++)
        VoteFactory.create(
          id: voteIndex + 1,
          title: {'ko': voteIndex == 0 ? _title : '다음 예정 투표'},
          isUpcoming: upcoming,
          startAt: DateTime.now().add(Duration(days: upcoming ? 1 : -1)),
          voteItem: List.generate(
            upcoming ? itemCount : 3,
            (i) => VoteItemModel.fromJson({
              'id': i + 1,
              'vote_id': 1,
              'vote_total': 0,
              'artist': {
                'id': i + 1,
                'name': {'ko': '아티스트${i + 1}'},
                'image': null,
              },
              'artist_group': null,
            }),
          ),
        ),
    ];
  }
}

Future<void> _showList(
  WidgetTester tester, {
  required Size screen,
  int itemCount = 13,
  int voteCount = 1,
  double textScale = 1,
  bool upcoming = true,
  VoteStatus? targetStatus,
  bool realShell = false,
  double safeBottom = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = screen;
  tester.view.viewPadding = FakeViewPadding(bottom: safeBottom);
  addTearDown(tester.view.reset);
  await pumpWidgetAndIgnoreErrors(
    tester,
    buildTestApp(
      // Reserve the app header and bottom navigation instead of incorrectly
      // giving a card the entire screen height.
      Padding(
        padding: EdgeInsets.only(top: 110, bottom: realShell ? 0 : 90),
        child: realShell
            ? const VoteHomeScreen()
            : const VoteListContent(isAdmin: false),
      ),
      navigation: realShell
          ? Navigation(
              portalType: PortalType.vote,
              showBottomNavigation: true,
              voteNavigationStack: NavigationStack()
                ..push(const VoteListContent(isAdmin: false)),
            )
          : null,
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      mediaQueryData: MediaQueryData(size: screen),
      textScaler: TextScaler.linear(textScale),
      extraOverrides: [
        asyncVoteListProvider.overrideWith(
          () => _LayoutVotes(itemCount, voteCount),
        ),
      ],
    ),
  );
  await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
  final selectedStatus =
      targetStatus ?? (upcoming ? VoteStatus.upcoming : VoteStatus.active);
  if (selectedStatus != VoteStatus.active) {
    final dropdown = find.byType(DropdownButton<VoteStatus>);
    await tester.tap(dropdown);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    await tester.tap(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is DropdownMenuItem<VoteStatus> &&
                widget.value == selectedStatus,
          )
          .last,
    );
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
  }
}

void main() {
  setUp(() {
    _LayoutVotes.requestCount = 0;
    initTestColors();
    setupMockSupabase({});
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });
  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
  });

  testWidgets(
    'filter is close to the vote title without a separate blank row',
    (tester) async {
      await _showList(tester, screen: const Size(390, 844), upcoming: false);
      final gap =
          tester.getTopLeft(find.text(_title)).dy -
          tester.getBottomLeft(find.byType(DropdownButton<VoteStatus>)).dy;
      expect(gap, lessThanOrEqualTo(40), reason: 'Filter-to-title gap: $gap');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final screen in [
    const Size(320, 700),
    const Size(360, 800),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      testWidgets(
        'upcoming card stays inside ${screen.width}x${screen.height} at $scale text',
        (tester) async {
          await _showList(tester, screen: screen, textScale: scale);
          final verticalPager = find.byWidgetPredicate(
            (widget) =>
                widget is PageView && widget.scrollDirection == Axis.vertical,
          );
          final pageBounds = tester.getRect(verticalPager);
          final share = find.byType(ShareSection);
          final card = find.byType(VoteInfoCard);
          expect(card, findsOneWidget);
          final gridBounds = tester.getRect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is PageView &&
                  widget.scrollDirection == Axis.horizontal,
            ),
          );
          for (final name
              in find
                  .descendant(of: card, matching: find.textContaining('아티스트'))
                  .evaluate()) {
            final bounds = tester.getRect(find.byWidget(name.widget));
            expect(
              bounds.bottom,
              lessThanOrEqualTo(gridBounds.bottom + 0.5),
              reason:
                  'Candidate names must fit inside the visible grid: '
                  '${(name.widget as Text).data}, $bounds vs $gridBounds; '
                  'header=${tester.getSize(find.byType(VoteCardInfoHeader))}, '
                  'share=${tester.getSize(share)}',
            );
          }
          if (find
              .byKey(const ValueKey('vote-card-overflow-scroll'))
              .evaluate()
              .isNotEmpty) {
            await tester.ensureVisible(share);
            await tester.pump();
          }
          final shareBounds = tester.getRect(share);
          expect(
            shareBounds.bottom,
            lessThanOrEqualTo(pageBounds.bottom + 0.5),
          );
          expect(shareBounds.top, greaterThanOrEqualTo(pageBounds.top));
          expect(find.text('저장').hitTestable(), findsOneWidget);
          expect(find.text('공유').hitTestable(), findsOneWidget);
          drainExpectedImageErrors(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }

  for (final status in [VoteStatus.active, VoteStatus.end]) {
    testWidgets('$status keeps ranks and actions reachable on a short page', (
      tester,
    ) async {
      await _showList(
        tester,
        screen: const Size(320, 700),
        textScale: 1.5,
        targetStatus: status,
      );
      final header = tester.getRect(find.byType(VoteCardInfoHeader));
      final share = find.byType(ShareSection);
      expect(tester.getRect(share).top - header.bottom, closeTo(284, 0.5));
      await tester.ensureVisible(share);
      await tester.pump();
      final page = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PageView && widget.scrollDirection == Axis.vertical,
        ),
      );
      expect(
        tester.getRect(share).bottom,
        lessThanOrEqualTo(page.bottom + 0.5),
      );
      expect(find.text('저장').hitTestable(), findsOneWidget);
      expect(find.text('공유').hitTestable(), findsOneWidget);
      drainExpectedImageErrors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  for (final count in [0, 1, 12, 25]) {
    testWidgets(
      'upcoming pagination exposes all $count candidates without clipping',
      (tester) async {
        await _showList(tester, screen: const Size(360, 800), itemCount: count);
        final horizontalPager = find.byWidgetPredicate(
          (widget) =>
              widget is PageView && widget.scrollDirection == Axis.horizontal,
        );
        final seen = <String>{};
        if (count > 0) {
          final pageCount = tester
              .widget<PageView>(horizontalPager)
              .childrenDelegate
              .estimatedChildCount!;
          for (var page = 0; page < pageCount; page++) {
            final viewport = tester.getRect(horizontalPager);
            for (final element
                in find.textContaining(RegExp(r'^아티스트\d+$')).evaluate()) {
              final bounds = tester.getRect(find.byWidget(element.widget));
              if (bounds.center.dx < viewport.left ||
                  bounds.center.dx > viewport.right) {
                continue;
              }
              expect(bounds.top, greaterThanOrEqualTo(viewport.top - 0.5));
              expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
              seen.add((element.widget as Text).data!);
            }
            if (page < pageCount - 1) {
              await tester.tap(find.byIcon(Icons.chevron_right));
              await pumpAndIgnoreErrors(tester);
              await pumpAndIgnoreErrors(
                tester,
                const Duration(milliseconds: 350),
              );
              expect(
                tester.widget<PageView>(horizontalPager).controller!.page,
                closeTo(page + 1, 0.01),
              );
            }
          }
        }
        expect(seen, {for (var i = 1; i <= count; i++) '아티스트$i'});
        expect(find.byType(ShareSection), findsOneWidget);
        drainExpectedImageErrors(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  for (final safeBottom in [0.0, 34.0, 48.0]) {
    testWidgets(
      'real vote shell keeps actions above navigation with $safeBottom bottom inset',
      (tester) async {
        await _showList(
          tester,
          screen: const Size(390, 844),
          realShell: true,
          safeBottom: safeBottom,
        );
        final actions = tester.getRect(find.byType(ShareSection));
        final navigation = tester.getRect(
          find.byType(CommonBottomNavigationBar),
        );
        expect(
          actions.bottom,
          lessThanOrEqualTo(navigation.top),
          reason: 'Floating navigation must not cover save/share actions',
        );
        expect(find.text('저장').hitTestable(), findsOneWidget);
        expect(find.text('공유').hitTestable(), findsOneWidget);
        drainExpectedImageErrors(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets('candidate swipes and vote swipes use their respective axes', (
    tester,
  ) async {
    await _showList(
      tester,
      screen: const Size(390, 844),
      itemCount: 25,
      voteCount: 2,
    );
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is PageView && widget.scrollDirection == Axis.horizontal,
    );
    final vertical = find.byWidgetPredicate(
      (widget) => widget is PageView && widget.scrollDirection == Axis.vertical,
    );
    await tester.drag(horizontal, const Offset(-320, 0));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
    expect(
      tester.widget<PageView>(horizontal).controller!.page,
      closeTo(1, 0.01),
    );
    expect(
      tester.widget<PageView>(vertical).controller!.page,
      closeTo(0, 0.01),
    );
    await tester.drag(horizontal, const Offset(0, -450));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
    expect(
      tester.widget<PageView>(vertical).controller!.page,
      closeTo(1, 0.01),
    );
    expect(find.text('다음 예정 투표'), findsOneWidget);
    drainExpectedImageErrors(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'a short card can scroll to its actions then advance to the next vote',
    (tester) async {
      await _showList(
        tester,
        screen: const Size(320, 700),
        textScale: 2,
        itemCount: 25,
        voteCount: 2,
      );
      final overflowScroll = find.byKey(
        const ValueKey('vote-card-overflow-scroll'),
      );
      expect(overflowScroll, findsOneWidget);
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is PageView && widget.scrollDirection == Axis.vertical,
      );
      await tester.drag(overflowScroll, const Offset(0, -450));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
      expect(
        tester.widget<PageView>(vertical).controller!.page,
        closeTo(0, 0.01),
        reason:
            'The first swipe must reveal the actions without skipping the vote',
      );
      expect(find.text('저장').hitTestable(), findsOneWidget);
      await tester.drag(overflowScroll, const Offset(0, -450));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
      expect(
        tester.widget<PageView>(vertical).controller!.page,
        closeTo(1, 0.01),
      );
      expect(find.text('다음 예정 투표'), findsOneWidget);
      final requestsBeforePrevious = _LayoutVotes.requestCount;
      await tester.drag(overflowScroll, const Offset(0, 450));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
      expect(
        tester.widget<PageView>(vertical).controller!.page,
        closeTo(0, 0.01),
      );
      expect(find.text(_title), findsOneWidget);
      expect(
        _LayoutVotes.requestCount,
        requestsBeforePrevious,
        reason: 'Moving to the previous vote must not also refresh the list',
      );
      drainExpectedImageErrors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('a short first card still supports pull to refresh', (
    tester,
  ) async {
    await _showList(
      tester,
      screen: const Size(320, 700),
      textScale: 2,
      itemCount: 25,
    );
    final beforeRefresh = _LayoutVotes.requestCount;
    final scroll = find.byKey(const ValueKey('vote-card-overflow-scroll'));
    await tester.drag(scroll, const Offset(0, 500));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 800));
    expect(_LayoutVotes.requestCount, greaterThan(beforeRefresh));
    drainExpectedImageErrors(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'resizing on the last candidate page keeps a valid visible page',
    (tester) async {
      await _showList(tester, screen: const Size(320, 700), itemCount: 25);
      final horizontal = find.byWidgetPredicate(
        (widget) =>
            widget is PageView && widget.scrollDirection == Axis.horizontal,
      );
      var pager = tester.widget<PageView>(horizontal);
      final originalCount = pager.childrenDelegate.estimatedChildCount!;
      pager.controller!.jumpToPage(originalCount - 1);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      tester.view.physicalSize = const Size(390, 844);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      pager = tester.widget<PageView>(horizontal);
      expect(
        pager.controller!.page,
        lessThan(pager.childrenDelegate.estimatedChildCount!),
      );
      expect(pager.controller!.page, greaterThanOrEqualTo(0));
      final viewport = tester.getRect(horizontal);
      final visible = find
          .textContaining(RegExp(r'^아티스트\d+$'))
          .evaluate()
          .where(
            (element) => viewport.contains(
              tester.getCenter(find.byWidget(element.widget)),
            ),
          );
      expect(
        visible,
        isNotEmpty,
        reason:
            'Resizing must not leave an empty page after the last candidate',
      );
      final share = tester.getRect(find.byType(ShareSection));
      expect(
        share.bottom,
        lessThanOrEqualTo(
          tester
                  .getRect(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is PageView &&
                          widget.scrollDirection == Axis.vertical,
                    ),
                  )
                  .bottom +
              0.5,
        ),
      );
      drainExpectedImageErrors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
