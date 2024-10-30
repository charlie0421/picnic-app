import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class TopRightPostView extends ConsumerStatefulWidget {
  const TopRightPostView({
    super.key,
  });

  @override
  ConsumerState<TopRightPostView> createState() => _TopRightPostViewState();
}

class _TopRightPostViewState extends ConsumerState<TopRightPostView> {
  @override
  Widget build(BuildContext context) {
    final currentPost = ref.watch(communityStateInfoProvider).currentPost!;
    final currentPostNotifier = ref.watch(communityStateInfoProvider.notifier);

    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            if (!supabase.isLogged) {
              showRequireLoginDialog(context: context);
              return;
            }
            (currentPost.isScraped ?? false)
                ? unscrapPost(
                    ref, currentPost.postId, supabase.auth.currentUser!.id)
                : scrapPost(ref, currentPost.postId);
            currentPostNotifier.setCurrentPost(currentPost.copyWith(
                isScraped: !(currentPost.isScraped ?? false)));
          },
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/scrap_style=fill.svg',
              width: 14,
              height: 18,
              colorFilter: ColorFilter.mode(
                (currentPost.isScraped ?? false)
                    ? AppColors.primary500
                    : AppColors.grey300,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
