import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_section.dart';

import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  testWidgets('unused direct consumer remains usable at 320px and 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    addTearDown(tester.view.reset);
    final changes = <String>[];

    await tester.pumpWidget(
      buildTestApp(
        SingleChildScrollView(
          child: SearchSection(onSearchChanged: changes.add),
        ),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(EnhancedSearchBox)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.enterText(find.byType(TextField), 'BTS');
    await tester.pump(const Duration(milliseconds: 301));
    expect(changes, ['BTS']);
  });
}
