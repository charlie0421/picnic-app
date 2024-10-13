import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class CommentInput extends ConsumerStatefulWidget {
  const CommentInput(
      {required this.id, required this.pagingController, super.key});

  final PagingController<int, CommentModel> pagingController;
  final String id;

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final _textEditingController = TextEditingController();
  final int _maxLength = 100;
  bool _isInputValid = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textEditingController.text;
    final isValid = text.trim().isNotEmpty;
    final newLength = text.length;

    setState(() {
      _isInputValid = isValid;
      _currentLength = newLength;
    });
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
                TextFormField(
                  controller: _textEditingController,
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
                        left: 10.cw, right: 80.cw, bottom: 30.ch),
                    counterText: '',
                  ),
                  maxLength: _maxLength,
                  textInputAction: TextInputAction.done,
                  style: getTextStyle(AppTypo.body16R, AppColors.grey900),
                  onFieldSubmitted: (value) => _commitComment(),
                ),
                Positioned(
                  right: 60.cw,
                  bottom: 8.ch,
                  child: Text(
                    '$_currentLength/$_maxLength',
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey400),
                  ),
                ),
                Positioned(
                  right: 16.cw,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isInputValid ? _commitComment : null,
                      child: SvgPicture.asset(
                        'assets/icons/send_style=fill.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          _isInputValid
                              ? AppColors.primary500
                              : AppColors.grey400,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.cw),
        ],
      ),
    );
  }

  void _commitComment() async {
    if (!_isInputValid) return;

    final parentItemState = ref.watch(parentItemProvider);
    await postComment(
        ref,
        widget.id,
        parentItemState?.parentCommentId ?? parentItemState?.commentId,
        _textEditingController.text.trim());
    ref.read(parentItemProvider.notifier).setParentItem(null);

    widget.pagingController.refresh();
    _textEditingController.clear();
    _onTextChanged();
  }
}
