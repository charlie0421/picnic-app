import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

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

void main() {
  setUp(initTestColors);

  testWidgets('loads page 2 at index 7 and coalesces later boundary events', (
    tester,
  ) async {
    final calls = <_PageRequest>[];
    final page2 = Completer<List<VoteModel>>();

    await tester.pumpWidget(
      _testApp((request) {
        calls.add(request);
        if (request.page == 1) return Future.value(_votes(1, 10));
        if (request.page == 2) return page2.future;
        return Future.value(const []);
      }),
    );
    await _pumpInitialPage(tester);

    await _jumpToPage(tester, 7);
    final page2Calls = calls.where((call) => call.page == 2).toList();
    expect(page2Calls, hasLength(1));
    expect(page2Calls.single.limit, 10);
    expect(page2Calls.single.sort, 'id');
    expect(page2Calls.single.order, 'DESC');
    expect(page2Calls.single.area, 'all');
    expect(page2Calls.single.status, VoteStatus.active);
    expect(page2Calls.single.category, VoteCategory.all);
    expect(page2Calls.single.portal, VotePortal.vote);

    await _jumpToPage(tester, 8);
    await _jumpToPage(tester, 9);
    expect(calls.where((call) => call.page == 2), hasLength(1));

    page2.complete(_votes(11, 10));
    await tester.pump();
    await tester.pump();
  });

  testWidgets('refresh rejects an older pending page and its state flags', (
    tester,
  ) async {
    final calls = <_PageRequest>[];
    final stalePage2 = Completer<List<VoteModel>>();
    final refreshedPage1 = Completer<List<VoteModel>>();
    var page1Calls = 0;

    await tester.pumpWidget(
      _testApp((request) {
        calls.add(request);
        if (request.page == 1) {
          page1Calls++;
          if (page1Calls == 1) return Future.value(_votes(1, 10));
          return refreshedPage1.future;
        }
        if (request.page == 2) return stalePage2.future;
        return Future.value(const []);
      }),
    );
    await _pumpInitialPage(tester);
    await _jumpToPage(tester, 7);
    expect(calls.where((call) => call.page == 2), hasLength(1));

    final refresh = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(refresh.show());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(page1Calls, 2);

    stalePage2.complete(_votes(900, 1));
    await tester.pump();
    await tester.pump();

    expect(find.byType(VoteCardSkeleton), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    refreshedPage1.complete(_votes(101, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(_renderedItemCount(tester), 10);
    expect(_currentPage(tester), 0);
    expect(calls.where((call) => call.page == 2), hasLength(1));
  });

  testWidgets('input change invalidates an older pending page response', (
    tester,
  ) async {
    final calls = <_PageRequest>[];
    final stalePage2 = Completer<List<VoteModel>>();
    late StateSetter updateHost;
    var area = 'all';

    Future<List<VoteModel>> loader(_PageRequest request) {
      calls.add(request);
      if (request.area == 'all' && request.page == 1) {
        return Future.value(_votes(1, 10));
      }
      if (request.area == 'all' && request.page == 2) {
        return stalePage2.future;
      }
      if (request.area == 'jpop' && request.page == 1) {
        return Future.value(_votes(101, 10));
      }
      return Future.value(const []);
    }

    await tester.pumpWidget(
      buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return VoteList(VoteStatus.active, VoteCategory.all, area);
          },
        ),
        extraOverrides: [
          asyncVoteListProvider.overrideWith(() => _ScriptedVoteList(loader)),
        ],
      ),
    );
    await _pumpInitialPage(tester);
    await _jumpToPage(tester, 7);
    expect(
      calls.where((call) => call.area == 'all' && call.page == 2),
      hasLength(1),
    );

    updateHost(() => area = 'jpop');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      calls.where((call) => call.area == 'jpop' && call.page == 1),
      hasLength(1),
    );
    expect(_renderedItemCount(tester), 10);
    expect(_currentPage(tester), 0);

    stalePage2.complete(_votes(900, 1));
    await tester.pump();
    await tester.pump();

    expect(_renderedItemCount(tester), 10);
    expect(_currentPage(tester), 0);
  });

  testWidgets('empty-page skip advances from the consumed page exactly once', (
    tester,
  ) async {
    final calls = <_PageRequest>[];

    await tester.pumpWidget(
      _testApp((request) {
        calls.add(request);
        return switch (request.page) {
          1 => Future.value(_votes(1, 10)),
          2 => Future.value(const []),
          3 => Future.value(_votes(30, 1)),
          4 => Future.value(_votes(40, 1)),
          _ => Future.value(const []),
        };
      }),
    );
    await _pumpInitialPage(tester);

    await _jumpToPage(tester, 7);
    await tester.pump();
    await tester.pump();
    expect(calls.map((call) => call.page), [1, 2, 3]);

    await _jumpToPage(tester, 8);
    await tester.pump();
    await tester.pump();

    expect(calls.map((call) => call.page), [1, 2, 3, 4]);
  });

  testWidgets('no-more result prevents any subsequent boundary fetch', (
    tester,
  ) async {
    final calls = <_PageRequest>[];

    await tester.pumpWidget(
      _testApp((request) {
        calls.add(request);
        if (request.page == 1) return Future.value(_votes(1, 10));
        return Future.value(const []);
      }),
    );
    await _pumpInitialPage(tester);

    await _jumpToPage(tester, 7);
    await tester.pump();
    await tester.pump();
    expect(calls.map((call) => call.page), [1, 2, 3, 4, 5]);

    await _jumpToPage(tester, 8);
    await _jumpToPage(tester, 9);
    expect(calls.map((call) => call.page), [1, 2, 3, 4, 5]);
  });

  testWidgets('a small initial page checks the boundary only once', (
    tester,
  ) async {
    final calls = <_PageRequest>[];

    await tester.pumpWidget(
      _testApp((request) {
        calls.add(request);
        if (request.page == 1) return Future.value(_votes(1, 1));
        if (request.page == 2) return Future.value(_votes(2, 1));
        return Future.value(_votes(request.page * 10, 1));
      }),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(calls.map((call) => call.page), [1, 2]);
    expect(_renderedItemCount(tester), 2);
  });
}
