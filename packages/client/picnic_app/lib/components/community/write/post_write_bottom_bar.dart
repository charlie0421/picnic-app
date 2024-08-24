import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Switch(value: false, onChanged: (value) {}),
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
