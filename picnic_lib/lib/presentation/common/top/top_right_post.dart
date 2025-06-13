import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/post_search_page.dart';
import 'package:picnic_lib/presentation/pages/community/post_write_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class TopRightPost extends ConsumerStatefulWidget {
  const TopRightPost({
    super.key,
  });

  @override
  ConsumerState<TopRightPost> createState() => _TopRightPostState();
}

class _TopRightPostState extends ConsumerState<TopRightPost> {
  @override
  Widget build(BuildContext context) {
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            if (isSupabaseLoggedSafely) {
              navigationInfoNotifier.setCurrentPage(const PostWritePage());
            } else {
              showRequireLoginDialog();
            }
          },
          child: Container(
            alignment: Alignment.centerLeft,
            width: 40.w,
            height: 36,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/pencil_style=fill.svg',
              width: 24.w,
              height: 24,
              colorFilter:
                  ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            navigationInfoNotifier.setCurrentPage(const PostSearchPage());
          },
          child: Stack(
            children: [
              SizedBox(
                width: 24.w,
                height: 24,
                child: SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/search_style=line.svg',
                  width: 24.w,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                      AppColors.grey900, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
