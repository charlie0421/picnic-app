import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';

class PostWriteBottomBar extends StatelessWidget {
  const PostWriteBottomBar({
    super.key,
    required this.isAnonymous,
    required this.onAnonymousChanged,
  });
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4),
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
          SizedBox(width: 8.w),
          Switch(
              value: isAnonymous,
              onChanged: (value) => onAnonymousChanged(value)),
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
