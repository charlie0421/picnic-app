import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/community/write/post_write_attachments.dart';
import 'package:picnic_app/components/community/write/post_write_editor.dart';

class PostWriteBody extends StatelessWidget {
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final List<PlatformFile> attachments;
  final Function(int) onAttachmentRemoved;

  const PostWriteBody({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.attachments,
    required this.onAttachmentRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          PostWriteEditor(
            titleController: titleController,
            contentController: contentController,
          ),
          PostWriteAttachments(
            attachments: attachments,
            onAttachmentRemoved: onAttachmentRemoved,
          ),
        ],
      ),
    );
  }
}
