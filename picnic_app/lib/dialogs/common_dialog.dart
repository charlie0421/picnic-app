import 'package:flutter/material.dart';
import 'package:picnic_app/dialogs/common/cancel_button.dart';
import 'package:picnic_app/dialogs/common/header.dart';
import 'package:picnic_app/dialogs/common/ok_button.dart';

Future showCommonDialog(
    {required BuildContext context,
    required String title,
    required String contents,
    required VoidCallback okBtnFn,
    VoidCallback? cancelBtnFn}) {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CommonDialog(
            title: title,
            contents: contents,
            okBtnFn: okBtnFn,
            cancelBtnFn: cancelBtnFn);
      }).then((value) {
    return value;
  });
}

class CommonDialog extends StatefulWidget {
  final String title;
  final String contents;
  final VoidCallback okBtnFn;
  final VoidCallback? cancelBtnFn;

  const CommonDialog(
      {super.key,
      required this.title,
      required this.contents,
      required this.okBtnFn,
      this.cancelBtnFn});

  @override
  State<CommonDialog> createState() => _CommonDialog();
}

class _CommonDialog extends State<CommonDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogCommonHeader(title: widget.title),
            const Divider(
              thickness: 0.3,
            ),
            Container(
                constraints: const BoxConstraints(minHeight: 80),
                child: Center(
                    child: Text(widget.contents,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.cancelBtnFn != null)
                  DialogCommonCancelButton(
                    callback: () {
                      Navigator.pop(context, false);
                    },
                  ),
                DialogCommonOkButton(
                  callback: widget.okBtnFn,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
