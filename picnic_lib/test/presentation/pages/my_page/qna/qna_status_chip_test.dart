import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_status_chip.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('QnaStatusChip', () {
    testWidgets('renders RESOLVED status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'RESOLVED'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
      expect(find.byType(QnaStatusChip), findsOneWidget);
    });

    testWidgets('renders IN_PROGRESS status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'IN_PROGRESS'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders RECEIVED status (default)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'RECEIVED'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('handles lowercase status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'resolved'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('handles unknown status as RECEIVED', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'UNKNOWN'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('accepts custom padding', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(
            status: 'RESOLVED',
            padding: EdgeInsets.all(12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
