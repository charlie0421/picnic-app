import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/post_write_bottom_bar.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('PostWriteBottomBar', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PostWriteBottomBar(),
        ),
      );
      await tester.pump();

      expect(find.byType(PostWriteBottomBar), findsOneWidget);
    });

    testWidgets('has a switch widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PostWriteBottomBar(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
