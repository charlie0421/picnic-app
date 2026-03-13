import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_summary_widget.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('GoonghapSummaryWidget', () {
    testWidgets('renders with localized result', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapSummaryWidget(
            localizedResult: LocalizedGoonghap(
              language: 'ko',
              score: 85,
              scoreTitle: '최고의 궁합',
              goonghapSummary: '환상적인 케미입니다!',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GoonghapSummaryWidget), findsOneWidget);
      expect(find.text('환상적인 케미입니다!'), findsOneWidget);
    });

    testWidgets('renders with null result', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapSummaryWidget(localizedResult: null),
        ),
      );
      await tester.pump();

      expect(find.byType(GoonghapSummaryWidget), findsOneWidget);
    });

    testWidgets('renders with empty summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapSummaryWidget(
            localizedResult: LocalizedGoonghap(
              language: 'en',
              score: 50,
              scoreTitle: 'Average',
              goonghapSummary: '',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GoonghapSummaryWidget), findsOneWidget);
    });
  });
}
