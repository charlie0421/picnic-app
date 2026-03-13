import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/post_write_body.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('PostWriteBody render', () {
    testWidgets('renders with required controllers', (WidgetTester tester) async {
      final titleController = TextEditingController();
      final contentController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildTestApp(
          PostWriteBody(
            titleController: titleController,
            contentController: contentController,
            attachments: const [],
            onAttachmentAdded: (_) {},
            onAttachmentRemoved: (_) {},
            onValidityChanged: (_) {},
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(PostWriteBody), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('title field accepts input', (WidgetTester tester) async {
      final titleController = TextEditingController();
      final contentController = quill.QuillController.basic();
      bool validityChanged = false;

      await tester.pumpWidget(
        buildTestApp(
          PostWriteBody(
            titleController: titleController,
            contentController: contentController,
            attachments: const [],
            onAttachmentAdded: (_) {},
            onAttachmentRemoved: (_) {},
            onValidityChanged: (isValid) {
              validityChanged = true;
            },
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Enter text in title field
      await tester.enterText(find.byType(TextField), 'Test Title');
      await pumpAndIgnoreErrors(tester);

      expect(titleController.text, 'Test Title');
      expect(validityChanged, isTrue);

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('renders toolbar with format buttons', (WidgetTester tester) async {
      final titleController = TextEditingController();
      final contentController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: PostWriteBody(
              titleController: titleController,
              contentController: contentController,
              attachments: const [],
              onAttachmentAdded: (_) {},
              onAttachmentRemoved: (_) {},
              onValidityChanged: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Toolbar area should have GestureDetector widgets for format buttons
      expect(find.byType(GestureDetector), findsWidgets);
      // VerticalDivider separates sections
      expect(find.byType(VerticalDivider), findsWidgets);

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('renders quill editor area', (WidgetTester tester) async {
      final titleController = TextEditingController();
      final contentController = quill.QuillController.basic();

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: PostWriteBody(
              titleController: titleController,
              contentController: contentController,
              attachments: const [],
              onAttachmentAdded: (_) {},
              onAttachmentRemoved: (_) {},
              onValidityChanged: (_) {},
            ),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // The widget tree should contain PostWriteBody
      expect(find.byType(PostWriteBody), findsOneWidget);
      // Verify containers are rendered (toolbar + editor area)
      expect(find.byType(Container), findsWidgets);

      titleController.dispose();
      contentController.dispose();
    });
  });
}
