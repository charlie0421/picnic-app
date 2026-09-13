import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _TestSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final _testSearchQueryProvider =
    NotifierProvider<_TestSearchQueryNotifier, String>(
      _TestSearchQueryNotifier.new,
    );

Map<String, dynamic> _artistRow(int id, String name) => {
  'id': id,
  'name': {'ko': name, 'en': name},
  'image': null,
  'birth_date': null,
  'gender': null,
  'is_kpop': true,
  'artist_group': null,
};

class _ArtistHttpHarness {
  final Map<String, List<Future<List<Map<String, dynamic>>>>> _plans = {};
  final Map<String, int> calls = {};

  void install() {
    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: MockClient(_handle),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  void enqueue(
    String query,
    Future<List<Map<String, dynamic>>> response, {
    ArtistSearchScope scope = ArtistSearchScope.kpopOnly,
  }) {
    final key = _key(query, scope);
    _plans.putIfAbsent(key, () => []).add(response);
  }

  int callCount(
    String query, {
    ArtistSearchScope scope = ArtistSearchScope.kpopOnly,
  }) => calls[_key(query, scope)] ?? 0;

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    if (path.contains('/auth/')) {
      return _json({'error': 'not authenticated'}, request, statusCode: 401);
    }
    if (!path.contains('/rest/v1/')) {
      return _json(<String, dynamic>{}, request);
    }

    final table = path.split('/rest/v1/').last.split('?').first;
    if (table == 'artist_user_bookmark') {
      return _json(<dynamic>[], request);
    }
    if (table != 'artist') {
      return _json(<dynamic>[], request);
    }

    final decodedUrl = Uri.decodeFull(request.url.toString());
    final query = _knownQuery(decodedUrl);
    final scope = decodedUrl.contains('is_musical.eq.true')
        ? ArtistSearchScope.musicalOnly
        : ArtistSearchScope.kpopOnly;
    final key = _key(query, scope);
    calls[key] = (calls[key] ?? 0) + 1;

    final queue = _plans[key];
    if (queue == null || queue.isEmpty) {
      return _json(<dynamic>[], request);
    }
    final rows = await queue.removeAt(0);
    return _json(rows, request);
  }

  String _knownQuery(String decodedUrl) {
    for (final query in const ['Alpha', 'Beta']) {
      if (decodedUrl.contains(query)) return query;
    }
    return '';
  }

  String _key(String query, ArtistSearchScope scope) => '$query|${scope.name}';

  http.Response _json(
    Object body,
    http.Request request, {
    int statusCode = 200,
  }) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      request: request,
      headers: const {
        'content-type': 'application/json',
        'content-range': '0-19/*',
      },
    );
  }
}

void main() {
  late void Function() restoreImageErrors;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SearchService.clearAllCache();
    restoreImageErrors = suppressImageErrors();
  });

  tearDown(() {
    restoreImageErrors();
    SearchService.clearAllCache();
    testSupabaseClient = null;
  });

  Widget list({
    ArtistSelectConfig config = const ArtistSelectConfig(),
    Key key = const ValueKey('artist-list'),
  }) {
    return ArtistSelectListView(
      key: key,
      searchQueryProvider: _testSearchQueryProvider,
      config: config,
    );
  }

  Future<void> pumpList(
    WidgetTester tester,
    _ArtistHttpHarness harness, {
    ArtistSelectConfig config = const ArtistSelectConfig(),
  }) async {
    harness.install();
    await pumpWidgetAndIgnoreErrors(tester, buildTestApp(list(config: config)));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      drainExpectedImageErrors(tester);
    }
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();
  }

  Future<void> disposeList(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Finder resultText(String value) => find.text(value, findRichText: true);

  testWidgets('A then B keeps B when stale A succeeds last', (tester) async {
    final harness = _ArtistHttpHarness();
    final alpha = Completer<List<Map<String, dynamic>>>();
    final beta = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', alpha.future);
    harness.enqueue('Beta', beta.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await search(tester, 'Beta');

    beta.complete([_artistRow(2, 'Beta result')]);
    await tester.pump();
    alpha.complete([_artistRow(1, 'Alpha result')]);
    await tester.pump();

    expect(harness.callCount('Beta'), 1);
    expect(resultText('Beta result'), findsOneWidget);
    expect(resultText('Alpha result'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('stale A error cannot replace successful B', (tester) async {
    final harness = _ArtistHttpHarness();
    final alpha = Completer<List<Map<String, dynamic>>>();
    final beta = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', alpha.future);
    harness.enqueue('Beta', beta.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await search(tester, 'Beta');

    beta.complete([_artistRow(2, 'Beta result')]);
    await tester.pump();
    alpha.completeError(StateError('stale Alpha failure'));
    await tester.pump();

    expect(harness.callCount('Beta'), 1);
    expect(resultText('Beta result'), findsOneWidget);
    expect(resultText('Alpha result'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('old pagination cannot append into a new query', (tester) async {
    final harness = _ArtistHttpHarness();
    final alphaPage = List.generate(
      20,
      (index) => _artistRow(100 + index, 'Alpha $index'),
    );
    final oldPage = Completer<List<Map<String, dynamic>>>();
    final beta = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', Future.value(alphaPage));
    harness.enqueue('Alpha', oldPage.future);
    harness.enqueue('Beta', beta.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await search(tester, 'Beta');

    beta.complete([_artistRow(2, 'Beta result')]);
    await tester.pump();
    oldPage.complete([_artistRow(999, 'Alpha stale page')]);
    await tester.pump();

    expect(harness.callCount('Alpha'), 2);
    expect(harness.callCount('Beta'), 1);
    expect(resultText('Beta result'), findsOneWidget);
    expect(resultText('Alpha stale page'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('repeated end-of-list notifications start one page request', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    final alphaPage = List.generate(
      20,
      (index) => _artistRow(100 + index, 'Alpha $index'),
    );
    final nextPage = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', Future.value(alphaPage));
    harness.enqueue('Alpha', nextPage.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    expect(
      harness.callCount('Alpha'),
      2,
      reason: 'one page-0 request plus one pending page-1 request',
    );

    nextPage.complete(<Map<String, dynamic>>[]);
    await tester.pump();
    await disposeList(tester);
  });

  testWidgets('refresh invalidates an in-flight pagination response', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    final alphaPage = List.generate(
      20,
      (index) => _artistRow(100 + index, 'Alpha $index'),
    );
    final oldPage = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', Future.value(alphaPage));
    harness.enqueue('Alpha', oldPage.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();

    SearchService.clearAllCache();
    harness.enqueue(
      'Alpha',
      Future.value([_artistRow(777, 'Alpha refreshed')]),
    );
    tester
        .state<ArtistSelectListViewState>(find.byType(ArtistSelectListView))
        .refresh();
    await tester.pump();

    oldPage.complete([_artistRow(999, 'Alpha stale page')]);
    await tester.pump();

    expect(harness.callCount('Alpha'), 3);
    expect(resultText('Alpha refreshed'), findsOneWidget);
    expect(resultText('Alpha stale page'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('locale change invalidates the pending request snapshot', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    final koreanRequest = Completer<List<Map<String, dynamic>>>();
    final englishRequest = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', koreanRequest.future);
    harness.enqueue('Alpha', englishRequest.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(list(), locale: const Locale('en')),
    );
    await tester.pump();

    englishRequest.complete([_artistRow(2, 'Alpha new locale')]);
    await tester.pump();
    koreanRequest.complete([_artistRow(1, 'Alpha old locale')]);
    await tester.pump();

    expect(harness.callCount('Alpha'), 2);
    expect(resultText('Alpha new locale'), findsOneWidget);
    expect(resultText('Alpha old locale'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('locale change does not reuse results ordered for old locale', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    harness.enqueue(
      'Alpha',
      Future.value([_artistRow(1, 'Alpha Korean order')]),
    );

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await tester.pump();
    expect(resultText('Alpha Korean order'), findsOneWidget);

    harness.enqueue(
      'Alpha',
      Future.value([_artistRow(2, 'Alpha English order')]),
    );
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(list(), locale: const Locale('en')),
    );
    await tester.pump();

    expect(harness.callCount('Alpha'), 2);
    expect(resultText('Alpha English order'), findsOneWidget);
    expect(resultText('Alpha Korean order'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('scope change invalidates the pending generation', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    final oldScope = Completer<List<Map<String, dynamic>>>();
    final newScope = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('', oldScope.future);
    harness.enqueue('', newScope.future, scope: ArtistSearchScope.musicalOnly);

    await pumpList(tester, harness);
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        list(
          config: const ArtistSelectConfig(
            searchScope: ArtistSearchScope.musicalOnly,
          ),
        ),
      ),
    );
    await tester.pump();

    newScope.complete([_artistRow(2, 'Beta result')]);
    await tester.pump();
    oldScope.complete([_artistRow(1, 'Alpha result')]);
    await tester.pump();

    expect(harness.callCount('', scope: ArtistSearchScope.musicalOnly), 1);
    expect(resultText('Beta result'), findsOneWidget);
    expect(resultText('Alpha result'), findsNothing);

    await disposeList(tester);
  });

  testWidgets('late completion after dispose does not update widget state', (
    tester,
  ) async {
    final harness = _ArtistHttpHarness();
    final alpha = Completer<List<Map<String, dynamic>>>();
    harness.enqueue('Alpha', alpha.future);

    await pumpList(tester, harness);
    await search(tester, 'Alpha');
    await disposeList(tester);

    alpha.complete([_artistRow(1, 'Alpha result')]);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
