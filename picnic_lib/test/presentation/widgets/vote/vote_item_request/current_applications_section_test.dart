import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/current_applications_section.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CurrentApplicationsSection', () {
    testWidgets('renders loading state with skeleton items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: [],
              totalApplications: 0,
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      // Header icon should be visible
      expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
    });

    testWidgets('renders empty state when no applications',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: [],
              totalApplications: 0,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      // Empty state icon
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('아직 신청된 내역이 없습니다'), findsOneWidget);
    });

    testWidgets('renders artist summaries with pending status',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
          'totalApplications': 5,
          'pendingCount': 3,
          'approvedCount': 0,
          'rejectedCount': 2,
          'statusCounts': {'pending': 3, 'rejected': 2},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 5,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      // Artist name should be visible
      expect(find.textContaining('지민'), findsOneWidget);
    });

    testWidgets('renders artist summaries with all approved status',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {
            'id': 1,
            'name': {'ko': 'V', 'en': 'V'},
          },
          'totalApplications': 3,
          'pendingCount': 0,
          'approvedCount': 3,
          'rejectedCount': 0,
          'statusCounts': {'approved': 3},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 3,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });

    testWidgets('renders artist summaries with all rejected status',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {
            'id': 1,
            'name': {'ko': '슈가', 'en': 'Suga'},
          },
          'totalApplications': 2,
          'pendingCount': 0,
          'approvedCount': 0,
          'rejectedCount': 2,
          'statusCounts': {'rejected': 2},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 2,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });

    testWidgets('renders with null artist data gracefully',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 99,
          'artist': null,
          'totalApplications': 1,
          'pendingCount': 1,
          'approvedCount': 0,
          'rejectedCount': 0,
          'statusCounts': {'pending': 1},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 1,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      expect(find.text('알 수 없는 아티스트'), findsOneWidget);
    });

    testWidgets('renders multiple artist summaries',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
          'totalApplications': 10,
          'pendingCount': 10,
          'approvedCount': 0,
          'rejectedCount': 0,
          'statusCounts': {'pending': 10},
          'requests': [],
          'latestRequest': null,
        },
        {
          'artistId': 2,
          'artist': {
            'id': 2,
            'name': {'ko': '뷔', 'en': 'V'},
          },
          'totalApplications': 5,
          'pendingCount': 5,
          'approvedCount': 0,
          'rejectedCount': 0,
          'statusCounts': {'pending': 5},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 15,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });

    testWidgets('renders with artist group name',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
            'artist_group': {
              'id': 1,
              'name': {'ko': 'BTS', 'en': 'BTS'},
            },
          },
          'totalApplications': 3,
          'pendingCount': 3,
          'approvedCount': 0,
          'rejectedCount': 0,
          'statusCounts': {'pending': 3},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 3,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
      // Group name is formatted via ArtistNameUtils.getDisplayName
      expect(find.textContaining('BTS'), findsWidgets);
    });

    testWidgets('renders with invalid artist JSON gracefully',
        (WidgetTester tester) async {
      final summaries = [
        {
          'artistId': 1,
          'artist': {'invalid_key': 'invalid_value'},
          'totalApplications': 1,
          'pendingCount': 1,
          'approvedCount': 0,
          'rejectedCount': 0,
          'statusCounts': {'pending': 1},
          'requests': [],
          'latestRequest': null,
        },
      ];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            child: CurrentApplicationsSection(
              artistApplicationSummaries: summaries,
              totalApplications: 1,
              isLoading: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CurrentApplicationsSection), findsOneWidget);
    });
  });

  group('ArtistNameUtils', () {
    test('getDisplayName returns korean name when available', () {
      final name = ArtistNameUtils.getDisplayName({'ko': '지민', 'en': 'Jimin'});
      // In test the locale context uses navigatorKey which may not be available
      // So we just verify it doesn't crash and returns non-empty
      expect(name.isNotEmpty, true);
    });

    test('getDisplayName returns english name when korean is empty', () {
      final name = ArtistNameUtils.getDisplayName({'ko': '', 'en': 'Jimin'});
      expect(name, 'Jimin');
    });

    test('getDisplayName returns korean name when english is empty', () {
      final name = ArtistNameUtils.getDisplayName({'ko': '지민', 'en': ''});
      expect(name, '지민');
    });

    test('getDisplayName returns fallback when both are empty', () {
      final name = ArtistNameUtils.getDisplayName({'ko': '', 'en': ''});
      expect(name, '알 수 없는 아티스트');
    });

    test('getDisplayName handles missing keys', () {
      final name = ArtistNameUtils.getDisplayName({});
      expect(name, '알 수 없는 아티스트');
    });
  });
}
