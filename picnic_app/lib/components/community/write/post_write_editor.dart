import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:video_player/video_player.dart';

class LocalImageEmbedBuilder extends EmbedBuilder {
  final bool isUploading;
  final double uploadProgress;

  LocalImageEmbedBuilder({this.isUploading = false, this.uploadProgress = 0.0});

  @override
  String get key => 'local-image';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final filePath = node.value.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;
    return Stack(
      children: [
        SizedBox(
          width: width,
          child: Image.file(File(filePath), fit: BoxFit.contain),
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 10),
                  Text(
                    'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class NetworkImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final imageUrl = node.value.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;
    return SizedBox(
      width: width,
      child: Image.network(imageUrl, fit: BoxFit.contain),
    );
  }
}

class LocalVideoEmbedBuilder extends EmbedBuilder {
  final bool isUploading;
  final double uploadProgress;

  LocalVideoEmbedBuilder({this.isUploading = false, this.uploadProgress = 0.0});

  @override
  String get key => 'local-video';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final filePath = node.value.data;
    final VideoPlayerController videoController =
        VideoPlayerController.file(File(filePath));
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;

    return Stack(
      children: [
        FutureBuilder(
          future: videoController.initialize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return SizedBox(
                width: width,
                child: AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                ),
              );
            } else {
              return SizedBox(
                width: width,
                height: width * 9 / 16,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 10),
                  Text(
                    'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.grey00),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class NetworkVideoEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.videoType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final videoUrl = node.value.data;
    final VideoPlayerController videoController =
        VideoPlayerController.network(videoUrl);
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;

    return FutureBuilder(
      future: videoController.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          );
        } else {
          return SizedBox(
            width: width,
            height: width * 9 / 16,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

class PostWriteEditor extends StatelessWidget {
  final TextEditingController titleController;
  final quill.QuillController contentController;

  const PostWriteEditor({
    Key? key,
    required this.titleController,
    required this.contentController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _PostWriteEditorContent(
      titleController: titleController,
      contentController: contentController,
    );
  }
}

class _PostWriteEditorContent extends StatefulWidget {
  final TextEditingController titleController;
  final quill.QuillController contentController;

  const _PostWriteEditorContent({
    Key? key,
    required this.titleController,
    required this.contentController,
  }) : super(key: key);

  @override
  _PostWriteEditorContentState createState() => _PostWriteEditorContentState();
}

class _PostWriteEditorContentState extends State<_PostWriteEditorContent> {
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  bool _isTitleFocused = false;
  bool _isEditorFocused = false;
  final ImagePicker _picker = ImagePicker();
  Map<String, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_handleTitleFocusChange);
    _editorFocusNode.addListener(_handleEditorFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_handleTitleFocusChange);
    _editorFocusNode.removeListener(_handleEditorFocusChange);
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _handleTitleFocusChange() {
    if (_isTitleFocused != _titleFocusNode.hasFocus) {
      setState(() {
        _isTitleFocused = _titleFocusNode.hasFocus;
      });
    }
  }

  void _handleEditorFocusChange() {
    if (_isEditorFocused != _editorFocusNode.hasFocus) {
      setState(() {
        _isEditorFocused = _editorFocusNode.hasFocus;
      });
    }
  }

  void _unfocusAll() {
    logger.d('Unfocusing all');
    _titleFocusNode.unfocus();
    _editorFocusNode.unfocus();
  }

  Future<void> _handleMediaButtonTap() async {
    final XFile? media = await _picker.pickMedia();
    if (media != null) {
      final file = File(media.path);
      final isVideo = media.path.toLowerCase().endsWith('.mp4');
      _insertLocalMediaToEditor(file.path, isVideo);
      _uploadMediaInBackground(file, isVideo);
    }
  }

  Future<void> _uploadMediaInBackground(File file, bool isVideo) async {
    try {
      setState(() {
        _uploadProgress[file.path] = 0.0;
      });

      final mediaUrl = await _uploadMedia(file, (progress) {
        setState(() {
          _uploadProgress[file.path] = progress;
        });
      });

      _replaceLocalMediaWithNetwork(file.path, mediaUrl, isVideo);

      setState(() {
        _uploadProgress.remove(file.path);
      });
    } catch (e) {
      print('Error uploading media: $e');
      setState(() {
        _uploadProgress.remove(file.path);
      });
      // Show error message to user
    }
  }

  Future<String> _uploadMedia(
      File file, Function(double) progressCallback) async {
    // Simulate upload with progress
    for (var i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      progressCallback(i / 100);
    }
    return 'https://example.com/uploaded_media';
  }

  void _insertLocalMediaToEditor(String filePath, bool isVideo) {
    final index = widget.contentController.selection.baseOffset;
    final length = widget.contentController.selection.extentOffset - index;

    if (isVideo) {
      widget.contentController.replaceText(
        index,
        length,
        quill.BlockEmbed('local-video', filePath),
        null,
      );
    } else {
      widget.contentController.replaceText(
        index,
        length,
        quill.BlockEmbed('local-image', filePath),
        null,
      );
    }

    widget.contentController.document.insert(index + 1, "\n");
  }

  void _replaceLocalMediaWithNetwork(
      String localPath, String networkUrl, bool isVideo) {
    final index =
        widget.contentController.document.toPlainText().indexOf(localPath);
    if (index != -1) {
      widget.contentController.replaceText(
        index,
        localPath.length,
        isVideo
            ? quill.BlockEmbed.video(networkUrl)
            : quill.BlockEmbed.image(networkUrl),
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusAll,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          _buildTitleField(),
          const SizedBox(height: 4),
          _buildQuillToolbar(),
          const SizedBox(height: 4),
          _buildQuillEditor(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return SizedBox(
      height: 48,
      child: CupertinoTextField(
        controller: widget.titleController,
        focusNode: _titleFocusNode,
        placeholder: 'Title',
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isTitleFocused ? AppColors.primary500 : Colors.grey,
            width: _isTitleFocused ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_editorFocusNode),
      ),
    );
  }

  Widget _buildQuillToolbar() {
    return quill.QuillToolbar.simple(
      controller: widget.contentController,
      configurations: quill.QuillSimpleToolbarConfigurations(
        showAlignmentButtons: false,
        showListNumbers: false,
        showListBullets: false,
        showCodeBlock: false,
        showQuote: false,
        showClearFormat: false,
        showLink: false,
        showUndo: true,
        showRedo: true,
        showSubscript: false,
        showSuperscript: false,
        showClipboardCut: false,
        showClipboardCopy: false,
        showClipboardPaste: false,
        showDirection: false,
        showSearchButton: false,
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showSmallButton: false,
        showUnderLineButton: true,
        showLineHeightButton: false,
        showStrikeThrough: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showJustifyAlignment: false,
        showLeftAlignment: false,
        showCenterAlignment: false,
        showRightAlignment: false,
        showHeaderStyle: false,
        showListCheck: false,
        showDividers: false,
        showIndent: false,
        customButtons: [
          quill.QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _handleMediaButtonTap,
          ),
        ],
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isEditorFocused ? AppColors.primary500 : Colors.grey,
          width: _isEditorFocused ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: quill.QuillEditor(
        controller: widget.contentController,
        scrollController: ScrollController(),
        focusNode: _editorFocusNode,
        configurations: quill.QuillEditorConfigurations(
          embedBuilders: [
            LocalImageEmbedBuilder(
              isUploading: _uploadProgress.containsKey('local-image'),
              uploadProgress: _uploadProgress['local-image'] ?? 0.0,
            ),
            NetworkImageEmbedBuilder(),
            LocalVideoEmbedBuilder(
              isUploading: _uploadProgress.containsKey('local-video'),
              uploadProgress: _uploadProgress['local-video'] ?? 0.0,
            ),
            NetworkVideoEmbedBuilder(),
          ],
        ),
      ),
    );
  }
}
