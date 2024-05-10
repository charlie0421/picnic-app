import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/dialogs/common/cancel_button.dart';
import 'package:prame_app/dialogs/common/header.dart';
import 'package:prame_app/dialogs/common/ok_button.dart';

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
      {Key? key,
      required this.title,
      required this.contents,
      required this.okBtnFn,
      this.cancelBtnFn})
      : super(key: key);

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
                        hintStyle: TextStyle(
                            color: Constants.fanMainColor, fontSize: 30),
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
                      style: TextStyle(
                          color: Constants.fanMainColor, fontSize: 30),
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
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    try {
      final response = await dio.post('/user/passwordCheck', data: {
        'password': _controller.text,
      });
      logger.i(response.data);
      return response.data == "true" ? true : false;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }
}
