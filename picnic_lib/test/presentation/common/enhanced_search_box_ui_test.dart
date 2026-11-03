import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';

import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

const _compactSize = Size(320, 568);

Finder _tapTargetForAsset(String assetName) {
  final asset = find.byWidgetPredicate((widget) {
    if (widget is! SvgPicture) return false;
    final loader = widget.bytesLoader;
    return loader is SvgAssetLoader && loader.assetName.endsWith(assetName);
  });
  return find.ancestor(of: asset, matching: find.byType(GestureDetector));
}

Future<void> _pumpSearchBox(
  WidgetTester tester, {
  TextEditingController? controller,
  FocusNode? focusNode,
  ValueChanged<String>? onSearchChanged,
  ValueChanged<String>? onSearchSubmitted,
  VoidCallback? onClear,
  bool enabled = true,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = _compactSize * 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 288,
          child: EnhancedSearchBox(
            hintText: '아티스트 또는 그룹 이름을 검색해 보세요',
            controller: controller,
            focusNode: focusNode,
            onSearchChanged: onSearchChanged,
            onSearchSubmitted: onSearchSubmitted,
            onClear: onClear,
            enabled: enabled,
          ),
        ),
      ),
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      textScaler: const TextScaler.linear(2),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  testWidgets('unfocused search field retains a visible input boundary', (
    tester,
  ) async {
    await _pumpSearchBox(tester);
    final container = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(EnhancedSearchBox),
            matching: find.byType(Container),
          ),
        )
        .singleWhere(
          (widget) =>
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).border != null,
        );
    final decoration = container.decoration! as BoxDecoration;
    final border = (decoration.border! as Border).top.color;
    final luminances = [
      border.computeLuminance(),
      decoration.color!.computeLuminance(),
    ]..sort();
    expect(
      (luminances.last + 0.05) / (luminances.first + 0.05),
      greaterThanOrEqualTo(3),
      reason:
          'The resting input edge must be distinguishable from its white fill.',
    );
  });

  testWidgets('320px 200% search and clear actions keep raw 48px targets', (
    tester,
  ) async {
    await _pumpSearchBox(tester);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(EnhancedSearchBox)).height,
      greaterThanOrEqualTo(48),
    );

    for (final target in [
      _tapTargetForAsset('search_icon.svg'),
      _tapTargetForAsset('cancel_style=fill.svg'),
    ]) {
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('disabled search actions cannot submit or clear external text', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Alpha');
    final changes = <String>[];
    final submissions = <String>[];
    var clears = 0;

    await _pumpSearchBox(
      tester,
      controller: controller,
      enabled: false,
      onSearchChanged: changes.add,
      onSearchSubmitted: submissions.add,
      onClear: () => clears++,
    );

    await tester.tap(
      _tapTargetForAsset('search_icon.svg'),
      warnIfMissed: false,
    );
    await tester.tap(
      _tapTargetForAsset('cancel_style=fill.svg'),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.text, 'Alpha');
    expect(changes, isEmpty);
    expect(submissions, isEmpty);
    expect(clears, 0);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    controller.dispose();
  });

  testWidgets('empty clear action is inert', (tester) async {
    final changes = <String>[];
    var clears = 0;
    await _pumpSearchBox(
      tester,
      onSearchChanged: changes.add,
      onClear: () => clears++,
    );

    await tester.tap(
      _tapTargetForAsset('cancel_style=fill.svg'),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(changes, isEmpty);
    expect(clears, 0);
  });

  testWidgets(
    'external controller focus and IME composition semantics survive',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final changes = <String>[];

      await _pumpSearchBox(
        tester,
        controller: controller,
        focusNode: focusNode,
        onSearchChanged: changes.add,
      );
      await tester.showKeyboard(find.byType(TextField));
      expect(focusNode.hasFocus, isTrue);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ㅎ',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.value.composing, const TextRange(start: 0, end: 1));
      expect(changes, ['ㅎ']);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        ),
      );
      await tester.pump(const Duration(milliseconds: 301));
      expect(changes, ['ㅎ', '한']);

      await tester.tap(_tapTargetForAsset('cancel_style=fill.svg'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(focusNode.hasFocus, isFalse);
      expect(changes, ['ㅎ', '한', '']);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      controller.text = 'still owned by the caller';
      expect(tester.takeException(), isNull);
      controller.dispose();
      focusNode.dispose();
    },
  );
}
