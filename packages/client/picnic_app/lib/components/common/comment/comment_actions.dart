import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CommentActions extends ConsumerWidget {
  final CommentModel item;

  const CommentActions({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  ref.read(parentItemProvider.notifier).setParentItem(item);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(
                    top: 5,
                    bottom: 10,
                  ),
                  child: Text(S.of(context).label_reply,
                      style:
                          getTextStyle(AppTypo.caption10SB, AppColors.grey600)),
                ),
              ),
            ],
          )),
    );
  }
}
