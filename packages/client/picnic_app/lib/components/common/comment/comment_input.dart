import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class CommentInput extends ConsumerStatefulWidget {
  const CommentInput({
    required this.id,
    required this.pagingController,
    this.onPostComment,
    super.key,
  });

  final PagingController<int, CommentModel> pagingController;
  final String id;
  final Function(
          String postId, String? parentId, String locale, String content)?
      onPostComment;

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
  final int _maxLength = 100;

  bool _isInputValid = false;
  bool _isLoading = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // 포커스를 받았을 때의 추가 동작
      // 예: 스크롤 위치 조정, 부모 알림 등
    }
  }

  void _onTextChanged() {
    if (!mounted) return;

    final text = _textEditingController.text;
    final isValid = text.trim().isNotEmpty && text.length <= _maxLength;
    final newLength = text.length;

    setState(() {
      _isInputValid = isValid;
      _currentLength = newLength;
    });
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _textEditingController,
      focusNode: _focusNode,
      enabled: !_isLoading,
      maxLength: _maxLength,
      textInputAction: TextInputAction.done,
      style: getTextStyle(AppTypo.body16R, AppColors.grey900),
      decoration: InputDecoration(
        hintText: S.of(context).label_hint_comment,
        hintStyle: TextStyle(
          fontSize: 16.sp,
          color: AppColors.grey400,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            color: AppColors.primary500,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.only(
          left: 10.cw,
          right: 80.cw,
          bottom: 30.ch,
        ),
        counterText: '',
      ),
      onFieldSubmitted: (_) => _commitComment(),
    );
  }

  Widget _buildCharCounter() {
    return Positioned(
      right: 60.cw,
      bottom: 8.ch,
      child: Text(
        '$_currentLength/$_maxLength',
        style: getTextStyle(
          AppTypo.caption12R,
          _currentLength > _maxLength ? Colors.red : AppColors.grey400,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary500,
        ),
      );
    }

    return GestureDetector(
      onTap: _isInputValid ? _commitComment : null,
      child: SvgPicture.asset(
        'assets/icons/send_style=fill.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          _isInputValid ? AppColors.primary500 : AppColors.grey400,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Future<void> _commitComment() async {
    if (!_isInputValid || _isLoading) return;

    final comment = _textEditingController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final parentItemState = ref.read(parentItemProvider);

      widget.onPostComment?.call(
        widget.id,
        parentItemState?.parentCommentId ?? parentItemState?.commentId,
        Localizations.localeOf(context).languageCode,
        comment,
      );

      if (!mounted) return;

      ref.read(parentItemProvider.notifier).setParentItem(null);
      widget.pagingController.refresh();

      _textEditingController.clear();
      _onTextChanged();
      _focusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 등록되었습니다.'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, s) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 등록에 실패했습니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      logger.e('Error: $e', stackTrace: s);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      width: getPlatformScreenSize(context).width,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildTextField(),
                _buildCharCounter(),
                Positioned(
                  right: 16.cw,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _buildSendButton()),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.cw),
        ],
      ),
    );
  }
}
