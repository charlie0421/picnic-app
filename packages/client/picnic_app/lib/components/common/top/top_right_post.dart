import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/pages/community/post_search_page.dart';
import 'package:picnic_app/pages/community/post_write_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

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
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (supabase.isLogged) {
                  navigationInfoNotifier.setCurrentPage(const PostWritePage());
                } else {
                  showRequireLoginDialog(
                    context: context,
                  );
                }
              },
              child: Container(
                alignment: Alignment.centerLeft,
                width: 40.cw,
                height: 36,
                child: SvgPicture.asset(
                  'assets/icons/pencil_style=fill.svg',
                  width: 24.cw,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                      AppColors.primary500, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            if (supabase.isLogged) {
              navigationInfoNotifier.setCurrentPage(const PostSearchPage());
            } else {
              showRequireLoginDialog(
                context: context,
              );
            }
          },
          child: Stack(
            children: [
              SizedBox(
                width: 24.cw,
                height: 24,
                child: SvgPicture.asset(
                  'assets/icons/search_style=line.svg',
                  width: 24.cw,
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
