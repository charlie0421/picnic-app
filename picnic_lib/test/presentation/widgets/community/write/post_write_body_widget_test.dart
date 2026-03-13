import 'package:file_picker/file_picker.dart';
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

  group('PostWriteBody widget tests', () {
    testWidgets('renders PostWriteBody widget', (tester) async {
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

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('contains title text field', (tester) async {
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

      expect(find.byType(TextField), findsOneWidget);

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('renders toolbar with format buttons', (tester) async {
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

      // Toolbar area should have GestureDetector widgets for format buttons
      expect(find.byType(GestureDetector), findsWidgets);
      // VerticalDivider separates toolbar sections
      expect(find.byType(VerticalDivider), findsWidgets);

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('entering title text updates controller', (tester) async {
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

      await tester.enterText(find.byType(TextField), 'Test Title');
      await pumpAndIgnoreErrors(tester);

      expect(titleController.text, 'Test Title');

      titleController.dispose();
      contentController.dispose();
    });

    testWidgets('title validity callback fires on non-empty text',
        (tester) async {
      final titleController = TextEditingController();
      final contentController = quill.QuillController.basic();
      bool lastValidity = false;

      await tester.pumpWidget(
        buildTestApp(
          PostWriteBody(
            titleController: titleController,
            contentController: contentController,
            attachments: const [],
            onAttachmentAdded: (_) {},
            onAttachmentRemoved: (_) {},
            onValidityChanged: (valid) => lastValidity = valid,
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'Valid Title');
      await pumpAndIgnoreErrors(tester);

      expect(lastValidity, isTrue);

      titleController.dispose();
      contentController.dispose();
    });
  });
}
