import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

const double _screenHeight = 812;
const double _keyboardInset = 320;

class _EmptyRequestService extends Fake implements VoteItemRequestService {
  @override
  Future<Map<String, dynamic>> loadAllApplicationsByArtist() async => {
    'artistApplicationSummaries': <Map<String, dynamic>>[],
    'totalApplications': 0,
  };

  @override
  Future<Map<String, dynamic>> searchArtistsWithPagination(
    String query, {
    required int page,
    required int pageSize,
  }) async => {'artists': <dynamic>[], 'hasMore': false, 'currentPage': page};
}

/// The opaque dialog surface: the only decorated container directly under the
/// dialog route that owns the whole body.
Finder _dialogSurface() => find
    .descendant(
      of: find.byType(VoteItemRequestDialog),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

Finder _nearestGestureTarget(Finder child) =>
    find.ancestor(of: child, matching: find.byType(GestureDetector)).first;

void main() {
  late VoteModel testVote;

  setUp(() {
    initTestColors();
    setupMockSupabase(<String, dynamic>{
      'vote_item_request_users': <Map<String, dynamic>>[],
      'vote_item': <Map<String, dynamic>>[],
      'vote_requests': <Map<String, dynamic>>[],
    });
    testVote = MockData.vote();
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpDialog(
    WidgetTester tester, {
    double keyboardInset = 0,
  }) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
            child: Material(
              child: VoteItemRequestDialog(
                vote: testVote,
                service: _EmptyRequestService(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('VoteItemRequestDialog presentation', () {
    testWidgets('the close action owns a 48px tap target', (tester) async {
      await pumpDialog(tester);

      final close = _nearestGestureTarget(find.byIcon(Icons.close_rounded));
      expect(close, findsOneWidget);
      final size = tester.getSize(close);
      expect(size.height, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      expect(size.width, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
    });

    testWidgets('the dialog surface stays above an open keyboard', (
      tester,
    ) async {
      await pumpDialog(tester, keyboardInset: _keyboardInset);

      expect(tester.takeException(), isNull);
      final surface = tester.getRect(_dialogSurface());
      expect(
        surface.bottom,
        lessThanOrEqualTo(_screenHeight - _keyboardInset + 0.5),
      );
      expect(surface.top, greaterThanOrEqualTo(0));
      expect(surface.height, greaterThan(0));
    });

    testWidgets('the dialog keeps its full-height surface with no keyboard', (
      tester,
    ) async {
      await pumpDialog(tester);

      expect(tester.getRect(_dialogSurface()).height, closeTo(748, 1));
    });
  });
}
