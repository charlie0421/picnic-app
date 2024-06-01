import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/common/cancel_button.dart';
import 'package:picnic_app/dialogs/common/header.dart';
import 'package:picnic_app/dialogs/common/ok_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future showWithdrawalDialog(
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
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: Container(
        width: 344,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogCommonHeader(title: widget.title),
            Container(
                constraints: const BoxConstraints(minHeight: 80),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: Intl.message('password'),
                        hintStyle:
                            const TextStyle(color: picMainColor, fontSize: 30),
                        errorStyle: const TextStyle(
                            color: Colors.redAccent, fontSize: 15),
                        errorMaxLines: 2,
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.redAccent,
                            width: 1.0,
                          ),
                        ),
                      ),
                      obscureText: true,
                      style: const TextStyle(color: picMainColor, fontSize: 30),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Intl.message('label_input_password_error');
                        } else if (value.length < 8 || value.length > 16) {
                          return Intl.message(
                              'label_input_password_error_length');
                        }
                        return null;
                      },
                    ),
                  ),
                )),
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
                  callback: () => _passwordCheck().then((bool value) {
                    logger.i(value);
                    Navigator.pop(context, value);
                  }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _passwordCheck() async {
    // TODO 실제 탈퇴 로직 구현
    final response = await Supabase.instance.client.auth.signOut();
    return true;
  }
}
