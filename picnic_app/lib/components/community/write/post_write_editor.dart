import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/style.dart';

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
      configurations: const quill.QuillSimpleToolbarConfigurations(
        showAlignmentButtons: false,
        showListNumbers: false,
        showListBullets: false,
        showCodeBlock: false,
        showQuote: false,
        showClearFormat: false,
        showLink: true,
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
      child: quill.QuillEditor.basic(
        controller: widget.contentController,
        focusNode: _editorFocusNode,
        scrollController: ScrollController(),
      ),
    );
  }
}
