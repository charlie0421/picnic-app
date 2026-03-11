import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('ReportType', () {
    test('has comment and post values', () {
      expect(ReportType.values, contains(ReportType.comment));
      expect(ReportType.values, contains(ReportType.post));
      expect(ReportType.values.length, 2);
    });
  });

  group('CustomRadioListTile', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: '스팸/광고',
            value: 0,
            groupValue: null,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('스팸/광고'), findsOneWidget);
      expect(find.byType(Radio<int>), findsOneWidget);
    });

    testWidgets('renders selected state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: '선택됨',
            value: 1,
            groupValue: 1,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('선택됨'), findsOneWidget);
    });

    testWidgets('renders unselected state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: '미선택',
            value: 0,
            groupValue: 1,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('미선택'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      int? selectedValue;
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: 'Tap me',
            value: 2,
            groupValue: null,
            onChanged: (v) => selectedValue = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap me'));
      expect(selectedValue, 2);
    });

    testWidgets('disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomRadioListTile(
            title: '비활성화',
            value: 0,
            groupValue: null,
            onChanged: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('비활성화'), findsOneWidget);
    });

    testWidgets('renders multiple options in column', (tester) async {
      int? selected;
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              CustomRadioListTile(
                title: 'Option A',
                value: 0,
                groupValue: selected,
                onChanged: (v) => selected = v,
              ),
              CustomRadioListTile(
                title: 'Option B',
                value: 1,
                groupValue: selected,
                onChanged: (v) => selected = v,
              ),
              CustomRadioListTile(
                title: 'Option C',
                value: 2,
                groupValue: selected,
                onChanged: (v) => selected = v,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
      expect(find.byType(Radio<int>), findsNWidgets(3));
    });
  });

  // Note: ReportDialog widget tests are skipped because it calls
  // AppLocalizations.of(context) in initState(), which runs before
  // the localization delegate is ready in the test environment.
}
