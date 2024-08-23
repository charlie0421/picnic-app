import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_app/components/community/write/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/youtube_embed_builder.dart';
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
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_handleTitleFocusChange);
    _editorFocusNode.addListener(_handleEditorFocusChange);
    _controller = widget.contentController;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      // This will trigger a rebuild of the toolbar
    });
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_handleTitleFocusChange);
    _editorFocusNode.removeListener(_handleEditorFocusChange);
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _controller.removeListener(_onTextChanged);
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
      print('Editor focus changed: $_isEditorFocused'); // 로그 추가
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
      behavior: HitTestBehavior.translucent,
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
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCustomButton(
            'assets/icons/post/post_undo.svg',
            () => widget.contentController.undo(),
            widget.contentController.hasUndo,
          ),
          _buildCustomButton(
            'assets/icons/post/post_redo.svg',
            () => widget.contentController.redo(),
            widget.contentController.hasRedo,
          ),
          _buildFormatButton(
            'assets/icons/post/post_bold.svg',
            () => _toggleSelectionFormat(quill.Attribute.bold),
            _isStyleActive(quill.Attribute.bold),
          ),
          _buildFormatButton(
            'assets/icons/post/post_italic.svg',
            () => _toggleSelectionFormat(quill.Attribute.italic),
            _isStyleActive(quill.Attribute.italic),
          ),
          _buildFormatButton(
            'assets/icons/post/post_underline.svg',
            () => _toggleSelectionFormat(quill.Attribute.underline),
            _isStyleActive(quill.Attribute.underline),
          ),
          _buildFormatButton(
            'assets/icons/post/post_media.svg',
            _handleMediaButtonTap,
            false,
          ),
          _buildFormatButton(
            'assets/icons/post/post_link.svg',
            _insertLink,
            false,
          ),
          _buildFormatButton(
            'assets/icons/post/post_youtube.svg',
            _insertYouTubeLink,
            false,
          ),
          _buildFormatButton(
            'assets/icons/post/post_attachment.svg',
            () {},
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton(
      String assetName, VoidCallback onPressed, bool isEnabled) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: SvgPicture.asset(
        assetName,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isEnabled ? AppColors.grey900 : AppColors.grey600,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildFormatButton(
      String assetName, VoidCallback onPressed, bool isActive) {
    return GestureDetector(
      onTap: onPressed,
      child: SvgPicture.asset(
        assetName,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          _getIconColor(isActive),
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Color _getIconColor(bool isActive) {
    return isActive ? AppColors.grey900 : AppColors.grey500;
  }

  void _toggleSelectionFormat(quill.Attribute<dynamic> attribute) {
    final selection = _controller.selection;
    if (selection.isCollapsed) {
      final currentStyle = _controller.getSelectionStyle();

      final isActive = currentStyle.attributes.containsKey(attribute.key) &&
          currentStyle.attributes[attribute.key]?.value == attribute.value;

      logger.i('isActive, $isActive');

      if (isActive) {
        _controller.formatSelection(quill.Attribute.clone(attribute, null));
      } else {
        _controller.formatSelection(attribute);
      }
    } else {
      // If text is selected, toggle the style for the selected text
      final isActive = _isStyleActive(attribute);
      if (isActive) {
        _controller.formatSelection(quill.Attribute.clone(attribute, null));
      } else {
        _controller.formatSelection(attribute);
      }
    }

    setState(() {});

    // Log the updated style after toggling
    logger.i('Updated Style: ${_controller.getSelectionStyle()}');
  }

  bool _isStyleActive(quill.Attribute<dynamic> attribute) {
    if (_controller.selection.isCollapsed) {
      final currentStyle = _controller.getSelectionStyle();
      return currentStyle.attributes.containsKey(attribute.key) &&
          currentStyle.attributes[attribute.key]?.value == attribute.value;
    } else {
      final selectedText = _controller.document
          .getPlainText(_controller.selection.start, _controller.selection.end);
      final style = _controller.document.collectStyle(
          _controller.selection.start,
          _controller.selection.end - _controller.selection.start);
      return style.attributes.containsKey(attribute.key) &&
          style.attributes[attribute.key]?.value == attribute.value;
    }
  }

  Widget _buildQuillEditor() {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          constraints: const BoxConstraints(
            minHeight: 400, //  TODO 기기별 적정 크기 부여하기
          ),
          child: GestureDetector(
            onTap: () {
              if (!_editorFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_editorFocusNode);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isEditorFocused ? AppColors.primary500 : Colors.grey,
                  width: _isEditorFocused ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  quill.QuillEditor(
                    controller: widget.contentController,
                    scrollController: ScrollController(),
                    focusNode: _editorFocusNode,
                    configurations: quill.QuillEditorConfigurations(
                      embedBuilders: [
                        LocalImageEmbedBuilder(
                          isUploading:
                              _uploadProgress.containsKey('local-image'),
                          uploadProgress: _uploadProgress['local-image'] ?? 0.0,
                        ),
                        NetworkImageEmbedBuilder(),
                        LocalVideoEmbedBuilder(
                          isUploading:
                              _uploadProgress.containsKey('local-video'),
                          uploadProgress: _uploadProgress['local-video'] ?? 0.0,
                        ),
                        NetworkVideoEmbedBuilder(),
                        LinkEmbedBuilder(), // 새로 추가된 부분
                        YouTubeEmbedBuilder(), // 새로 추가된 부분
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ));
    });
  }

  void _insertLink() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Insert Link'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Paste URL here'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      print('Inserting Link: $result'); // 디버깅을 위한 출력
      final index = widget.contentController.selection.baseOffset;
      final length = widget.contentController.selection.extentOffset - index;
      widget.contentController.replaceText(
        index,
        length,
        BlockEmbed('link', result),
        null,
      );
      widget.contentController.document.insert(index + 1, "\n");
      print('Link inserted at index: $index'); // 디버깅을 위한 출력
      setState(() {}); // 화면 갱신을 강제로 트리거
    }
  }

  void _insertYouTubeLink() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert YouTube Link'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Paste YouTube URL here'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      print('Inserting YouTube URL: $result'); // 디버깅을 위한 출력
      final index = widget.contentController.selection.baseOffset;
      final length = widget.contentController.selection.extentOffset - index;

      // YouTube 임베드 삽입 전 문서 상태 출력
      print(
          'Document before insertion: ${widget.contentController.document.toPlainText()}');

      widget.contentController.replaceText(
        index,
        length,
        BlockEmbed('youtube', result),
        null,
      );
      widget.contentController.document.insert(index + 1, "\n");

      // YouTube 임베드 삽입 후 문서 상태 출력
      print(
          'Document after insertion: ${widget.contentController.document.toPlainText()}');

      print('YouTube URL inserted at index: $index'); // 디버깅을 위한 출력
      setState(() {}); // 화면 갱신을 강제로 트리거
    }
  }
}
