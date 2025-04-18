import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/openai.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

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
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;
  final int _maxLength = 100;

  bool _isInputValid = false;
  bool _isLoading = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();

    _registerListeners();
  }

  void _registerListeners() {
    _textEditingController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
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
        hintText: t('label_hint_comment'),
        hintStyle: TextStyle(
          fontSize: 16.sp,
          color: AppColors.grey400,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
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
          left: 10.w,
          right: 80.w,
          bottom: 30.h,
        ),
        counterText: '',
      ),
      onFieldSubmitted: (_) => _commitComment(),
    );
  }

  Widget _buildCharCounter() {
    return Positioned(
      right: 60.w,
      bottom: 8.h,
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
      return SizedBox(
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
        package: 'picnic_lib',
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
      OverlayLoadingProgress.start(context);

      final checkResult = await checkContent(_textEditingController.text);
      final isFlagged = checkResult['flagged'] as bool? ?? false;

      if (isFlagged) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          title: t('dialog_caution'),
          content: t('post_flagged'),
        );
        return;
      }

      final parentItemState = ref.read(parentItemProvider);
      widget.onPostComment?.call(
        widget.id,
        parentItemState?.parentCommentId ?? parentItemState?.commentId,
        getLocaleLanguage(),
        comment,
      );

      if (!mounted) return;

      ref.read(parentItemProvider.notifier).setParentItem(null);
      widget.pagingController.refresh();

      _textEditingController.clear();
      _onTextChanged();
      _focusNode.unfocus();

      SnackbarUtil().showSnackbar(t('post_comment_registered_comment'));
    } catch (e, s) {
      if (!mounted) return;

      SnackbarUtil().showSnackbar(
        t('post_comment_register_fail'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );

      logger.e('Error: $e', stackTrace: s);
    } finally {
      OverlayLoadingProgress.stop();
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
                  right: 16.w,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _buildSendButton()),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
    );
  }
}
