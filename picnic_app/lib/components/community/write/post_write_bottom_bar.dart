import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 4),
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

class _LinkDialog extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final String title;

  _LinkDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "Enter link here"),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Insert'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}
