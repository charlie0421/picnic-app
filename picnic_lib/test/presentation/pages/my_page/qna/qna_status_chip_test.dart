import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_status_chip.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_status_badge.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void _expectStatusPresentation(WidgetTester tester) {
  final status = tester
      .widget<QnaStatusChip>(find.byType(QnaStatusChip))
      .status
      .toUpperCase();
  final l10n = AppLocalizations.of(tester.element(find.byType(QnaStatusChip)));
  final label = status == 'RESOLVED'
      ? l10n.qna_status_resolved
      : status == 'IN_PROGRESS'
      ? l10n.qna_status_in_progress
      : l10n.qna_status_received;
  final background = status == 'RESOLVED'
      ? AppColors.secondary500
      : status == 'IN_PROGRESS'
      ? AppColors.primary500
      : AppColors.sub500;
  expect(find.text(label), findsOneWidget);
  final badge = tester.widget<PicnicStatusBadge>(
    find.byType(PicnicStatusBadge),
  );
  expect(badge.backgroundColor, background);
  final foreground = tester.widget<Text>(find.text(label)).style!.color!;
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final contrast = a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
  expect(contrast, greaterThanOrEqualTo(4.5));
}

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('QnaStatusChip', () {
    testWidgets('renders RESOLVED status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const QnaStatusChip(status: 'RESOLVED')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
      expect(find.byType(QnaStatusChip), findsOneWidget);
    });

    testWidgets('renders IN_PROGRESS status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const QnaStatusChip(status: 'IN_PROGRESS')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
    });

    testWidgets('renders RECEIVED status (default)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const QnaStatusChip(status: 'RECEIVED')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
    });

    testWidgets('handles lowercase status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const QnaStatusChip(status: 'resolved')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
    });

    testWidgets('handles unknown status as RECEIVED', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const QnaStatusChip(status: 'UNKNOWN')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
    });

    testWidgets('accepts custom padding', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const QnaStatusChip(status: 'RESOLVED', padding: EdgeInsets.all(12)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PicnicStatusBadge), findsOneWidget);
      _expectStatusPresentation(tester);
      expect(
        tester
            .widget<PicnicStatusBadge>(find.byType(PicnicStatusBadge))
            .padding,
        const EdgeInsets.all(12),
      );
    });
  });
}
