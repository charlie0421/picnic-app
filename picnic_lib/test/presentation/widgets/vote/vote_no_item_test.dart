import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('VoteNoItem', () {
    testWidgets('renders with active status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.active,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
      expect(find.text('현재 진행 중인 투표가 없습니다.'), findsOneWidget);
      // A 100 minimum that keeps its natural height (not the whole screen).
      expect(tester.getSize(find.byType(VoteNoItem)).height, 100);
    });

    testWidgets('renders with end status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.end,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
    });

    testWidgets('renders with upcoming status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.upcoming,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
    });
  });
}
