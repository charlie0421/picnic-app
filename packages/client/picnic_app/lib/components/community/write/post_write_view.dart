import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/post_write_body.dart';
import 'package:picnic_app/components/community/write/post_write_bottom_bar.dart';
import 'package:picnic_app/components/community/write/post_write_header.dart';

class CustomBlockEmbed extends quill.CustomBlockEmbed {
  CustomBlockEmbed(String type, Map<String, dynamic> data)
      : super(type, jsonEncode(data));

  static CustomBlockEmbed media(String path, String name) =>
      CustomBlockEmbed('media', {'path': path, 'name': name});

  static CustomBlockEmbed youtube(String videoId) =>
      CustomBlockEmbed('youtube', {'videoId': videoId});

  static CustomBlockEmbed link(String url) =>
      CustomBlockEmbed('link', {'url': url});
}

class PostWriteView extends ConsumerStatefulWidget {
  const PostWriteView({super.key, required this.boardId});
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
                isAnonymous: _isAnonymous,
                onAnonymousChanged: (value) =>
                    setState(() => _isAnonymous = value),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PostWriteBody(
                    titleController: _titleController,
                    contentController: _contentController,
                    attachments: _attachments,
                    onAttachmentRemoved: (index) =>
                        setState(() => _attachments.removeAt(index)),
                  ),
                ),
              ),
              PostWriteBottomBar(
                onMediaPicked: (file) => _insertMediaPreview(file),
                onYoutubeLinkInserted: (videoId) =>
                    _insertYoutubePreview(videoId),
                onLinkInserted: (link) => _insertLinkPreview(link),
                onFilesPicked: (files) =>
                    setState(() => _attachments.addAll(files)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _insertMediaPreview(PlatformFile file) {
    final index = _contentController.selection.baseOffset;
    _contentController.document.insert(index, '\n');
    _contentController.document.insert(
      index + 1,
      CustomBlockEmbed.media(file.path!, file.name),
    );
    _contentController.document.insert(index + 2, '\n');
  }

  void _insertYoutubePreview(String videoId) {
    final index = _contentController.selection.baseOffset;
    _contentController.document.insert(index, '\n');
    _contentController.document.insert(
      index + 1,
      CustomBlockEmbed.youtube(videoId),
    );
    _contentController.document.insert(index + 2, '\n');
  }

  void _insertLinkPreview(String link) {
    final index = _contentController.selection.baseOffset;
    _contentController.document.insert(index, '\n');
    _contentController.document.insert(
      index + 1,
      CustomBlockEmbed.link(link),
    );
    _contentController.document.insert(index + 2, '\n');
  }
}
