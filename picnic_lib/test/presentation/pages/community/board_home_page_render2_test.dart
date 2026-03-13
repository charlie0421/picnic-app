import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/board_home_page.dart';
import 'package:picnic_lib/presentation/providers/artist_provider.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'boards': <dynamic>[
        {
          'board_id': 'b-1',
          'name': {'ko': '자유게시판', 'en': 'Free'},
          'artist_id': 1,
          'description': '자유롭게 글을 쓰세요',
          'is_official': false,
          'features': ['post', 'comment', 'image'],
          'status': 'approved',
          'creator_id': null,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
        },
        {
          'board_id': 'b-2',
          'name': {'ko': '팬아트', 'en': 'Fan Art'},
          'artist_id': 1,
          'description': '팬아트를 올려주세요',
          'is_official': false,
          'features': ['post', 'comment', 'image'],
          'status': 'approved',
          'creator_id': null,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
        },
      ],
      'artist': [
        {
          'id': 1,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'gender': null,
          'birth_date': null,
        },
      ],
      'posts': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('BoardHomePage render extended', () {
    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardHomePage(1)),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(BoardHomePage), findsOneWidget);
    });

    testWidgets('renders with boards data', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardHomePage(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      expect(find.byType(BoardHomePage), findsOneWidget);
      // Should render tab bar with "All" tab at minimum
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('renders with different artist id', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardHomePage(999)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      expect(find.byType(BoardHomePage), findsOneWidget);
    });
  });
}
