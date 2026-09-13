import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _PageRequest {
  const _PageRequest({
    required this.page,
    required this.limit,
    required this.sort,
    required this.order,
    required this.area,
    required this.status,
    required this.category,
    required this.portal,
  });

  final int page;
  final int limit;
  final String sort;
  final String order;
  final String area;
  final VoteStatus status;
  final VoteCategory category;
  final VotePortal portal;
}

typedef _PageLoader = Future<List<VoteModel>> Function(_PageRequest request);

class _ScriptedVoteList extends AsyncVoteList {
  _ScriptedVoteList(this.loader);

  final _PageLoader loader;

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
  }) {
    return loader(
      _PageRequest(
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        area: area,
        status: status,
        category: category,
        portal: votePortal,
      ),
    );
  }
}

List<VoteModel> _votes(int firstId, int count, {String category = 'birthday'}) {
  return List.generate(
    count,
    (index) => VoteFactory.create(
      id: firstId + index,
      title: {'ko': '투표 ${firstId + index}'},
      voteCategory: category,
      voteItem: const [],
    ),
  );
}

Widget _testApp(
  _PageLoader loader, {
  VoteStatus status = VoteStatus.active,
  VoteCategory category = VoteCategory.all,
  String area = 'all',
  VotePortal portal = VotePortal.vote,
}) {
  return buildTestApp(
    VoteList(status, category, area, portal: portal),
    retry: (_, _) => null,
    extraOverrides: [
      asyncVoteListProvider.overrideWith(() => _ScriptedVoteList(loader)),
    ],
  );
}

Future<void> _pumpInitialPage(WidgetTester tester) async {
  await pumpAndIgnoreErrors(tester);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  expect(find.byType(PageView), findsOneWidget);
}

Future<void> _jumpToPage(WidgetTester tester, int index) async {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  pageView.controller!.jumpToPage(index);
  await tester.pump();
}

int _renderedItemCount(WidgetTester tester) {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  return pageView.childrenDelegate.estimatedChildCount!;
}

double _currentPage(WidgetTester tester) {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  return pageView.controller!.page!;
}

final _retryButton = find.byKey(const ValueKey('vote-list-retry'));

Future<void> _settleResponse(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  setUp(initTestColors);

  testWidgets('first-page failure offers retry instead of no votes', (
    tester,
  ) async {
    var calls = 0;
    final retry = Completer<List<VoteModel>>();
    await tester.pumpWidget(
      _testApp((request) {
        calls++;
        if (calls == 1) {
          return Future.error(Exception('private upstream detail'));
        }
        return retry.future;
      }),
    );
    await _settleResponse(tester);

    expect(find.byType(VoteNoItem), findsNothing);
    expect(_retryButton, findsOneWidget);
    expect(find.textContaining('private upstream detail'), findsNothing);
    await tester.tap(_retryButton);
    await tester.tap(_retryButton);
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(VoteCardSkeleton), findsOneWidget);

    retry.complete(_votes(1, 10));
    await _pumpInitialPage(tester);
    expect(_renderedItemCount(tester), 10);
    expect(_retryButton, findsNothing);
  });

  testWidgets('a successful empty response still shows no votes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp((_) async => []));
    await _settleResponse(tester);
    expect(find.byType(VoteNoItem), findsOneWidget);
    expect(_retryButton, findsNothing);
  });

  testWidgets('a failed retry stays retryable and can later succeed', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _testApp((_) async {
        calls++;
        if (calls < 3) throw Exception('offline');
        return _votes(1, 10);
      }),
    );
    await _settleResponse(tester);
    await tester.tap(_retryButton);
    await _settleResponse(tester);
    expect(_retryButton, findsOneWidget);
    expect(find.byType(VoteNoItem), findsNothing);
    await tester.tap(_retryButton);
    await _pumpInitialPage(tester);
    expect(calls, 3);
    expect(_renderedItemCount(tester), 10);
  });

  testWidgets(
    'page failure keeps cards and position and retries only that page',
    (tester) async {
      final calls = <int>[];
      final retry = Completer<List<VoteModel>>();
      var page2Calls = 0;
      await tester.pumpWidget(
        _testApp((request) {
          calls.add(request.page);
          if (request.page == 1) return Future.value(_votes(1, 10));
          if (request.page == 2) {
            page2Calls++;
            if (page2Calls == 1) return Future.error(Exception('offline'));
            return retry.future;
          }
          return Future.value([]);
        }),
      );
      await _pumpInitialPage(tester);
      await _jumpToPage(tester, 7);
      await _settleResponse(tester);
      expect(_retryButton, findsOneWidget);
      expect(_renderedItemCount(tester), 10);
      expect(_currentPage(tester), 7);
      // Moving inside the already-loaded list must not repeatedly retry an error.
      await _jumpToPage(tester, 8);
      expect(calls, [1, 2]);
      await tester.tap(_retryButton);
      await tester.tap(_retryButton);
      await tester.pump();
      expect(calls, [1, 2, 2]);
      retry.complete(_votes(11, 10));
      await _settleResponse(tester);
      expect(_renderedItemCount(tester), 20);
      expect(_currentPage(tester), 8);
      expect(_retryButton, findsNothing);
    },
  );

  testWidgets(
    'PIC lookahead failure retries the failed page instead of ending',
    (tester) async {
      final calls = <int>[];
      var page3Calls = 0;
      await tester.pumpWidget(
        _testApp((request) async {
          calls.add(request.page);
          if (request.page == 1) return _votes(1, 10, category: 'weekly');
          if (request.page == 2) return _votes(11, 10, category: 'birthday');
          if (request.page == 3) {
            page3Calls++;
            if (page3Calls == 1) throw Exception('lookahead offline');
            return _votes(21, 10, category: 'image');
          }
          return [];
        }, portal: VotePortal.pic),
      );
      await _pumpInitialPage(tester);
      await _jumpToPage(tester, 7);
      await _settleResponse(tester);
      expect(_retryButton, findsOneWidget);
      expect(_renderedItemCount(tester), 10);
      await tester.tap(_retryButton);
      await _settleResponse(tester);
      expect(calls, [1, 2, 3, 3]);
      expect(_renderedItemCount(tester), 20);
    },
  );

  testWidgets('a late error from the old filter cannot replace the new list', (
    tester,
  ) async {
    final stale = Completer<List<VoteModel>>();
    late StateSetter updateHost;
    var area = 'all';
    await tester.pumpWidget(
      buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return VoteList(VoteStatus.active, VoteCategory.all, area);
          },
        ),
        retry: (_, _) => null,
        extraOverrides: [
          asyncVoteListProvider.overrideWith(
            () => _ScriptedVoteList(
              (request) => request.area == 'all'
                  ? stale.future
                  : Future.value(_votes(101, 10)),
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    updateHost(() => area = 'jpop');
    await _pumpInitialPage(tester);
    stale.completeError(Exception('old filter offline'));
    await _settleResponse(tester);
    expect(_renderedItemCount(tester), 10);
    expect(_retryButton, findsNothing);
    expect(find.byType(VoteNoItem), findsNothing);
  });

  testWidgets('refresh does not reuse an old pending later-page response', (
    tester,
  ) async {
    final stale = Completer<List<VoteModel>>();
    var page1Calls = 0;
    var page2Calls = 0;
    await tester.pumpWidget(
      _testApp((request) {
        if (request.page == 1) {
          page1Calls++;
          return Future.value(_votes(page1Calls == 1 ? 1 : 101, 10));
        }
        if (request.page == 2) {
          page2Calls++;
          return page2Calls == 1 ? stale.future : Future.value(_votes(111, 10));
        }
        return Future.value([]);
      }),
    );
    await _pumpInitialPage(tester);
    await _jumpToPage(tester, 7);
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await _pumpInitialPage(tester);
    await _jumpToPage(tester, 0);
    await _jumpToPage(tester, 7);
    await _settleResponse(tester);
    stale.complete(_votes(900, 1));
    await _settleResponse(tester);
    expect(page2Calls, 2);
    expect(_renderedItemCount(tester), 20);
  });
}
