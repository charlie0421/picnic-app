import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_app/components/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_app/components/community/write/post_write_attachments.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

import '../../ui/s3_uploader.dart';

class PostWriteBody extends StatefulWidget {
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final List<PlatformFile> attachments;
  final Function(List<PlatformFile>) onAttachmentAdded;
  final Function(int) onAttachmentRemoved;

  const PostWriteBody({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.attachments,
    required this.onAttachmentAdded,
    required this.onAttachmentRemoved,
  });

  @override
  _PostWriteBodyState createState() => _PostWriteBodyState();
}

class _PostWriteBodyState extends State<PostWriteBody> {
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  bool _isTitleFocused = false;
  bool _isEditorFocused = false;
  final ImagePicker _picker = ImagePicker();
  final Map<String, double> _uploadProgress = {};
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
    }
  }

  void _unfocusAll() {
    logger.d('Unfocusing all');
    _titleFocusNode.unfocus();
    _editorFocusNode.unfocus();
  }

  Future<void> _handleMediaButtonTap() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _insertLocalMediaToEditor(image.path);
    }
  }

  void _insertLocalMediaToEditor(String filePath) {
    final index = widget.contentController.selection.baseOffset;
    final length = widget.contentController.selection.extentOffset - index;

    widget.contentController.replaceText(
      index,
      length,
      quill.BlockEmbed('local-image', filePath),
      null,
    );

    widget.contentController.document.insert(index + 1, "\n");

    widget.contentController.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );
  }

  void _replaceLocalMediaWithNetwork(String localPath, String networkUrl) {
    final doc = widget.contentController.document;
    final delta = doc.toDelta();
    final operations = delta.toList();

    for (int i = 0; i < operations.length; i++) {
      final Operation operation = operations[i];
      if (operation.data is Map<String, dynamic>) {
        final data = operation.data as Map<String, dynamic>;
        if (data['local-image'] == localPath) {
          widget.contentController.replaceText(
            i,
            1,
            quill.BlockEmbed('image', networkUrl),
            null,
          );
          logger.d(
              'Replaced local image with network URL: $networkUrl at index $i');
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: Column(
        children: [
          GestureDetector(
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
          ),
          PostWriteAttachments(
            attachments: widget.attachments,
            onAttachmentAdded: widget.onAttachmentAdded,
            onAttachmentRemoved: widget.onAttachmentRemoved,
          ),
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
        placeholder: S.of(context).post_title_placeholder,
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
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHistoryButton(
            'assets/icons/post/post_undo.svg',
            () => widget.contentController.undo(),
            widget.contentController.hasUndo,
          ),
          _buildHistoryButton(
            'assets/icons/post/post_redo.svg',
            () => widget.contentController.redo(),
            widget.contentController.hasRedo,
          ),
          const VerticalDivider(
            color: AppColors.grey400,
            width: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
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
          const VerticalDivider(
            color: AppColors.grey400,
            width: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),
          _buildFeatureButton(
            'assets/icons/post/post_media.svg',
            _handleMediaButtonTap,
          ),
          _buildFeatureButton(
            'assets/icons/post/post_link.svg',
            _insertLink,
          ),
          _buildFeatureButton(
            'assets/icons/post/post_youtube.svg',
            _insertYouTubeLink,
          ),
          _buildFeatureButton(
            'assets/icons/post/post_attachment.svg',
            _pickFiles,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(
      String assetName, VoidCallback onPressed, bool isEnabled) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: SvgPicture.asset(
        assetName,
        width: 18,
        height: 18,
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

  Widget _buildFeatureButton(String assetName, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: SvgPicture.asset(
        assetName,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(
          AppColors.grey900,
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
          minHeight: 400,
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
                    placeholder: S.of(context).post_content_placeholder,
                    embedBuilders: [
                      DeletableLinkEmbedBuilder(),
                      DeletableYouTubeEmbedBuilder(),
                      LocalImageEmbedBuilder(
                        onUploadComplete: _replaceLocalMediaWithNetwork,
                      ),
                      NetworkImageEmbedBuilder(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _insertLink() async {
    final urlController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
          child: Text(
            S.of(context).post_hyperlink,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: S.of(context).post_insert_link,
                hintStyle: getTextStyle(AppTypo.body16M, AppColors.grey500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'url': urlController.text,
            }),
            child: Text(S.of(context).button_ok,
                style: const TextStyle(color: AppColors.primary500)),
          ),
        ],
      ),
    );

    if (result != null && result['url']!.isNotEmpty) {
      final linkData = {
        'name': result['name'],
        'url': result['url'],
      };
      _insertEmbed('link', jsonEncode(linkData));
    }
  }

  void _insertEmbed(String type, dynamic data) {
    final index = widget.contentController.selection.baseOffset;
    final length = widget.contentController.selection.extentOffset - index;

    widget.contentController.replaceText(
      index,
      length,
      BlockEmbed(type, data),
      null,
    );

    // 임베드 후 새 줄 추가
    widget.contentController.document.insert(index + 1, "\n");

    // 커서를 새 줄로 이동
    widget.contentController.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );

    setState(() {});

    // 에디터에 포커스 주기
    _editorFocusNode.requestFocus();
  }

  void _insertYouTubeLink() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context).post_youtube_link,
        ),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
              hintText: S.of(context).post_insert_link,
              hintStyle: const TextStyle(color: AppColors.grey500)),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(
              S.of(context).button_ok,
              style: const TextStyle(color: AppColors.primary500),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _insertEmbed('youtube', result);
    }
  }

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      widget.onAttachmentAdded(result.files);
    }
  }
}
