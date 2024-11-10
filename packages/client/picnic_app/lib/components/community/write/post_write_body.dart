import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_height_plugin/keyboard_height_plugin.dart';
import 'package:picnic_app/components/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_app/components/community/write/post_write_attachments.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class PostWriteBody extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final List<PlatformFile> attachments;
  final Function(List<PlatformFile>) onAttachmentAdded;
  final Function(int) onAttachmentRemoved;
  final Function(bool) onValidityChanged;

  const PostWriteBody({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.attachments,
    required this.onAttachmentAdded,
    required this.onAttachmentRemoved,
    required this.onValidityChanged,
  });

  @override
  ConsumerState<PostWriteBody> createState() => _PostWriteBodyState();
}

class _PostWriteBodyState extends ConsumerState<PostWriteBody> {
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  bool _isTitleFocused = false;
  bool _isEditorFocused = false;
  bool _isTitleValid = false;
  final ImagePicker _picker = ImagePicker();
  late final quill.QuillController _controller;
  double _keyboardHeight = 0;
  KeyboardHeightPlugin? _keyboardHeightPlugin;
  bool _isKeyboardListenerInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_handleTitleFocusChange);
    _editorFocusNode.addListener(_handleEditorFocusChange);
    widget.titleController.addListener(_validateTitle);
    _controller = widget.contentController;
    _controller.addListener(_onTextChanged);

    // 웹이 아닌 경우에만 키보드 플러그인 초기화
    if (!kIsWeb) {
      _initializeKeyboardListener();
    }
  }

  Future<void> _initializeKeyboardListener() async {
    try {
      _keyboardHeightPlugin = KeyboardHeightPlugin();
      // 플러그인이 정상적으로 초기화될 때까지 대기
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return; // 위젯이 이미 dispose된 경우 리턴

      _keyboardHeightPlugin?.onKeyboardHeightChanged((double height) {
        if (mounted) {
          // setState 호출 전에 mounted 체크
          setState(() {
            _keyboardHeight = height;
          });
        }
      });

      _isKeyboardListenerInitialized = true;
    } catch (e) {
      debugPrint('Keyboard height plugin initialization failed: $e');
      _isKeyboardListenerInitialized = false;
    }
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_handleTitleFocusChange);
    _editorFocusNode.removeListener(_handleEditorFocusChange);
    widget.titleController.removeListener(_validateTitle);
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _keyboardHeightPlugin = null; // 명시적으로 null로 설정
    super.dispose();
  }

  // 키보드 높이 getter
  double get keyboardHeight {
    if (!_isKeyboardListenerInitialized || kIsWeb) {
      return 0;
    }
    return _keyboardHeight;
  }

  @override
  Widget build(BuildContext context) {
    final currentBoard = ref.watch(communityStateInfoProvider).currentBoard;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: GestureDetector(
        onTap: _unFocusAll,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _buildTitleField(),
            const SizedBox(height: 4),
            _buildQuillToolbar(currentBoard),
            const SizedBox(height: 4),
            _buildQuillEditor(),
            PostWriteAttachments(
              attachments: widget.attachments,
              onAttachmentAdded: widget.onAttachmentAdded,
              onAttachmentRemoved: widget.onAttachmentRemoved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuillEditor() {
    return LayoutBuilder(builder: (context, constraint) {
      return KeyboardVisibilityBuilder(
          builder: (context, bool isKeyboardVisible) {
        final double containerSize = MediaQuery.of(context).size.height - 420;

        // Adjust editor height based on platform and keyboard visibility
        final double editorHeight = !kIsWeb && isKeyboardVisible
            ? containerSize - _keyboardHeight + 40
            : containerSize;

        return SizedBox(
          height: editorHeight,
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
                  color: _isEditorFocused
                      ? AppColors.primary500
                      : AppColors.grey400,
                  width: _isEditorFocused ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: quill.QuillEditor(
                controller: _controller,
                scrollController: ScrollController(),
                focusNode: _editorFocusNode,
                configurations: quill.QuillEditorConfigurations(
                  placeholder: S.of(context).post_content_placeholder,
                  embedBuilders: [
                    DeletableLinkEmbedBuilder(),
                    DeletableYouTubeEmbedBuilder(),
                    LocalImageEmbedBuilder(
                        onUploadComplete: _replaceLocalMediaWithNetwork),
                    NetworkImageEmbedBuilder(),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  Widget _buildTitleField() {
    return SizedBox(
      height: 48,
      child: TextField(
        textAlignVertical: TextAlignVertical.center,
        controller: widget.titleController,
        focusNode: _titleFocusNode,
        decoration: InputDecoration(
          hintText: S.of(context).post_title_placeholder,
          hintStyle: const TextStyle(color: AppColors.grey300),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: _isTitleFocused ? AppColors.primary500 : AppColors.grey400,
              width: _isTitleFocused ? 2.0 : 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: AppColors.grey400,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: AppColors.primary500,
              width: 2.0,
            ),
          ),
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_editorFocusNode),
      ),
    );
  }

  Widget _buildQuillToolbar(BoardModel? currentBoard) {
    final featuresList = currentBoard?.features;
    return SizedBox(
      height: 40,
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHistoryButton(
                  'assets/icons/post/post_undo.svg',
                  () => _controller.undo(),
                  _controller.hasUndo,
                ),
                _buildHistoryButton(
                  'assets/icons/post/post_redo.svg',
                  () => _controller.redo(),
                  _controller.hasRedo,
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
              ],
            ),
          ),
          SizedBox(width: 16.cw),
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (featuresList != null && featuresList.contains('image'))
                  _buildFeatureButton(
                    'assets/icons/post/post_media.svg',
                    _handleMediaButtonTap,
                  ),
                if (featuresList != null && featuresList.contains('link'))
                  _buildFeatureButton(
                    'assets/icons/post/post_link.svg',
                    _insertLink,
                  ),
                if (featuresList != null && featuresList.contains('youtube'))
                  _buildFeatureButton(
                    'assets/icons/post/post_youtube.svg',
                    _insertYouTubeLink,
                  ),
                if (featuresList != null && featuresList.contains('attachment'))
                  _buildFeatureButton(
                    'assets/icons/post/post_attachment.svg',
                    _pickFiles,
                  ),
              ],
            ),
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

  void _onTextChanged() {
    setState(() {});
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

  void _validateTitle() {
    final isValid = widget.titleController.text.trim().isNotEmpty;
    if (isValid != _isTitleValid) {
      setState(() {
        _isTitleValid = isValid;
      });
      widget.onValidityChanged(_isTitleValid);
    }
  }

  void _unFocusAll() {
    _titleFocusNode.unfocus();
    _editorFocusNode.unfocus();
  }

  Color _getIconColor(bool isActive) {
    return isActive ? AppColors.grey900 : AppColors.grey500;
  }

  void _toggleSelectionFormat(quill.Attribute<dynamic> attribute) {
    final isActive = _isStyleActive(attribute);

    _controller.formatSelection(
        isActive ? quill.Attribute.clone(attribute, null) : attribute);
    setState(() {});
  }

  bool _isStyleActive(quill.Attribute<dynamic> attribute) {
    final selection = _controller.selection;
    final currentStyle = selection.isCollapsed
        ? _controller.getSelectionStyle()
        : _controller.document
            .collectStyle(selection.start, selection.end - selection.start);

    return currentStyle.attributes.containsKey(attribute.key) &&
        currentStyle.attributes[attribute.key]?.value == attribute.value;
  }

  Future<void> _handleMediaButtonTap() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _insertLocalMediaToEditor(image.path);
    }
  }

  void _insertLocalMediaToEditor(String filePath) {
    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - index;

    _controller.replaceText(
      index,
      length,
      quill.BlockEmbed('local-image', filePath),
      null,
    );

    _controller.document.insert(index + 1, "\n");

    _controller.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      quill.ChangeSource.local,
    );
  }

  void _replaceLocalMediaWithNetwork(String localPath, String networkUrl) {
    final doc = _controller.document;
    final delta = doc.toDelta();
    final operations = delta.toList();

    for (int i = 0; i < operations.length; i++) {
      final operation = operations[i];
      if (operation.data is Map<String, dynamic>) {
        final data = operation.data as Map<String, dynamic>;
        if (data['local-image'] == localPath) {
          _controller.replaceText(
            i,
            1,
            quill.BlockEmbed('image', networkUrl),
            null,
          );
          break;
        }
      }
    }
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
            onPressed: () =>
                Navigator.of(context).pop({'url': urlController.text}),
            child: Text(S.of(context).button_ok,
                style: const TextStyle(color: AppColors.primary500)),
          ),
        ],
      ),
    );

    if (result != null && result['url']!.isNotEmpty) {
      _insertEmbed(
          'link', jsonEncode({'name': result['name'], 'url': result['url']}));
    }
  }

  void _insertEmbed(String type, dynamic data) {
    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - index;

    _controller.replaceText(index, length, quill.BlockEmbed(type, data), null);
    _controller.document.insert(index + 1, "\n");
    _controller.updateSelection(
        TextSelection.collapsed(offset: index + 2), quill.ChangeSource.local);
    setState(() {});
    _editorFocusNode.requestFocus();
  }

  void _insertYouTubeLink() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).post_youtube_link),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: S.of(context).post_insert_link,
            hintStyle: const TextStyle(color: AppColors.grey500),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(S.of(context).button_ok,
                style: const TextStyle(color: AppColors.primary500)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _insertEmbed('youtube', result);
    }
  }

  void _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      widget.onAttachmentAdded(result.files);
    }
  }
}
