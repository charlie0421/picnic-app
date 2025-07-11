import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class CommentReplyLayer extends ConsumerWidget {
  const CommentReplyLayer({
    super.key,
    required PagingController<int, CommentModel> pagingController,
    required this.parentComment,
  });

  final CommentModel parentComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primary500,
      width: double.infinity,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
              AppLocalizations.of(context)
                  .post_replying_comment(parentComment.user?.nickname ?? ''),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey00)),
          IconButton(
            onPressed: () {
              ref.read(parentItemProvider.notifier).setParentItem(null);
            },
            iconSize: 20,
            icon: const Icon(Icons.close, color: AppColors.grey00),
          ),
        ],
      ),
    );
  }
}
