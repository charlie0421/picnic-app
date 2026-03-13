import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(body: child),
        );
      },
    );
  }

  group('ShareSection', () {
    testWidgets('renders save and share buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ShareSection(
            onSave: () {},
            onShare: () {},
            saveButtonText: 'Save',
            shareButtonText: 'Share',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('uses default button text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ShareSection(
            onSave: () {},
            onShare: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('save'), findsOneWidget);
      expect(find.text('share'), findsOneWidget);
    });

    testWidgets('onSave callback triggers on tap', (tester) async {
      bool saveTapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          ShareSection(
            onSave: () => saveTapped = true,
            onShare: () {},
            saveButtonText: 'Save',
            shareButtonText: 'Share',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      expect(saveTapped, isTrue);
    });

    testWidgets('onShare callback triggers on tap', (tester) async {
      bool shareTapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          ShareSection(
            onSave: () {},
            onShare: () => shareTapped = true,
            saveButtonText: 'Save',
            shareButtonText: 'Share',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Share'));
      expect(shareTapped, isTrue);
    });

    testWidgets('contains ElevatedButton widgets', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ShareSection(
            onSave: () {},
            onShare: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('is a StatelessWidget', (tester) async {
      final widget = ShareSection(
        onSave: () {},
        onShare: () {},
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
