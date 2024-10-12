import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';

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
    logger.i('currentPost: $currentPost');
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        (currentPost.is_scraped ?? false)
            ? GestureDetector(
                onTap: () {
                  unscrapPost(
                      ref, currentPost.post_id, supabase.auth.currentUser!.id);
                  currentPostNotifier
                      .setCurrentPost(currentPost.copyWith(is_scraped: false));
                },
                child: SvgPicture.asset(
                  'assets/icons/scrap_style=fill.svg',
                  width: 14,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                      AppColors.primary500, BlendMode.srcIn),
                ),
              )
            : GestureDetector(
                onTap: () {
                  scrapPost(ref, currentPost.post_id);
                  currentPostNotifier
                      .setCurrentPost(currentPost.copyWith(is_scraped: true));
                },
                child: SvgPicture.asset(
                  'assets/icons/scrap_style=fill.svg',
                  width: 14,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                      AppColors.grey300, BlendMode.srcIn),
                ),
              ),
      ],
    );
  }
}
