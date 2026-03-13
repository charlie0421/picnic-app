import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/presentation/common/common_my_point_info.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/gradient_border_painter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommonMyPoint', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider
                .overrideWith(() => _MockScreenInfosNotifier({})),
          ],
        ),
      );
      await tester.pump();
      // Clear Image.asset errors (asset not available in test)
      tester.takeException();

      expect(find.byType(CommonMyPoint), findsOneWidget);
    });

    testWidgets('contains CustomPaint with GradientBorderPainter',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider
                .overrideWith(() => _MockScreenInfosNotifier({})),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      final customPaint = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is GradientBorderPainter,
      );
      expect(customPaint, findsOneWidget);
    });

    testWidgets('contains Row widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider
                .overrideWith(() => _MockScreenInfosNotifier({})),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      final rowFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Row &&
            widget.mainAxisAlignment == MainAxisAlignment.spaceBetween,
      );
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('displays star candy count via AnimatedDigitWidget',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider
                .overrideWith(() => _MockScreenInfosNotifier({})),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      expect(find.byType(AnimatedDigitWidget), findsOneWidget);
    });

    testWidgets('GestureDetector is present for tap', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider
                .overrideWith(() => _MockScreenInfosNotifier({})),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}

class _MockScreenInfosNotifier extends ScreenInfosNotifier {
  final Map<String, ScreenInfo> _initial;

  _MockScreenInfosNotifier(this._initial);

  @override
  Map<String, ScreenInfo> build() => _initial;
}
