import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class PostWriteBottomBar extends ConsumerWidget {
  const PostWriteBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAnonymousMode = ref
        .watch(appSettingProvider.select((value) => value.postAnonymousMode));
    final appSettingNotifier = ref.read(appSettingProvider.notifier);

    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            S.of(context).post_anonymous,
            style: getTextStyle(AppTypo.caption12R, AppColors.grey800),
          ),
          SizedBox(width: 8.cw),
          Switch(
              inactiveTrackColor: AppColors.grey300,
              inactiveThumbColor: AppColors.grey00,
              value: postAnonymousMode,
              onChanged: (value) =>
                  appSettingNotifier.setPostAnonymousMode(value)),
        ],
      ),
    );
  }
}
