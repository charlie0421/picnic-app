import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

class PostListItem extends ConsumerStatefulWidget {
  final PostModel post;
  final Widget? popupMenu;

  const PostListItem({super.key, required this.post, required this.popupMenu});

  @override
  ConsumerState<PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends ConsumerState<PostListItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref
            .read(communityStateInfoProvider.notifier)
            .setCurrentBoard(widget.post.board!);

        ref
            .read(navigationInfoProvider.notifier)
            .setCommunityCurrentPage(PostViewPage(widget.post.postId));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: PicnicUi.vertical(12),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: PicnicUi.border, width: 1.w),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: PicnicUi.horizontal(4),
                    runSpacing: PicnicUi.vertical(4),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (widget.post.board != null)
                        Text(
                          getLocaleTextFromJson(
                            widget.post.board!.name,
                            context,
                          ),
                          style: PicnicUi.text(
                            size: 12,
                            weight: FontWeight.w600,
                            color: PicnicUi.actionColor,
                          ),
                        ),
                      widget.post.isAnonymous ?? false
                          ? const NoAvatar(
                              width: 18,
                              height: 18,
                              borderRadius: 4,
                            )
                          : ProfileImageContainer(
                              avatarUrl: widget.post.userProfiles?.avatarUrl,
                              borderRadius: 4,
                              width: 18,
                              height: 18,
                            ),
                      Text(
                        (widget.post.isAnonymous ?? false)
                            ? AppLocalizations.of(context).anonymous
                            : widget.post.userProfiles?.nickname ?? '',
                        style: PicnicUi.text(size: 12, weight: FontWeight.w600),
                      ),
                      Text(
                        formatTimeAgo(context, widget.post.createdAt!),
                        style: PicnicUi.text(
                          size: 12,
                          color: PicnicUi.quietText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PicnicUi.vertical(4)),
                  Text(
                    widget.post.title ?? '',
                    style: PicnicUi.text(weight: FontWeight.w500),
                  ),
                  SizedBox(height: PicnicUi.vertical(4)),
                  Text(
                    '${AppLocalizations.of(context).views} ${widget.post.viewCount}  '
                    '${AppLocalizations.of(context).replies} ${widget.post.replyCount}',
                    style: PicnicUi.text(
                      size: 12,
                      color: PicnicUi.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.popupMenu != null) ...[
              SizedBox(width: PicnicUi.horizontal(8)),
              widget.popupMenu!,
            ],
          ],
        ),
      ),
    );
  }
}
