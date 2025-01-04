import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class MenuItem extends ConsumerWidget {
  final String title;
  final String assetPath;
  final int index;
  final bool? needLogin;

  const MenuItem({
    super.key,
    required this.title,
    required this.assetPath,
    required this.index,
    this.needLogin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(navigationInfoProvider.notifier);
    final navigationInfo = ref.watch(navigationInfoProvider);

    final index = navigationInfo.getBottomNavigationIndex();
    final bool isSelected = index == this.index;

    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: () {
          if ((needLogin ?? false) && !supabase.isLogged) {
            showRequireLoginDialog();
            return;
          }
          navigationNotifier.setBottomNavigationIndex(this.index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  package: 'picnic_lib',
                  assetPath,
                  colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.grey900 : AppColors.grey400,
                      BlendMode.srcIn),
                )),
            Text(
              Intl.message(title),
              style: getTextStyle(
                isSelected ? AppTypo.caption12B : AppTypo.caption12R,
                isSelected ? AppColors.grey900 : AppColors.grey400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
