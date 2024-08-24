import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/post_write_body.dart';
import 'package:picnic_app/components/community/write/post_write_bottom_bar.dart';
import 'package:picnic_app/components/community/write/post_write_header.dart';

class PostWriteView extends ConsumerStatefulWidget {
  const PostWriteView({
    super.key,
    required this.boardId,
  });
  final String boardId;

  @override
  ConsumerState<PostWriteView> createState() => _PostWriteViewState();
}

class _PostWriteViewState extends ConsumerState<PostWriteView> {
  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _contentController =
      quill.QuillController.basic();
  bool _isAnonymous = false;
  List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _savePost() {
    // Implementation for saving post
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PostWriteHeader(
                onSave: _savePost,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PostWriteBody(
                    titleController: _titleController,
                    contentController: _contentController,
                    attachments: _attachments,
                    onAttachmentAdded: (files) =>
                        setState(() => _attachments.addAll(files)),
                    onAttachmentRemoved: (index) =>
                        setState(() => _attachments.removeAt(index)),
                  ),
                ),
              ),
              PostWriteBottomBar(
                isAnonymous: _isAnonymous,
                onAnonymousChanged: (value) =>
                    setState(() => _isAnonymous = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
