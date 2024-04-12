import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/dialogs/common_dialog.dart';
import 'package:prame_app/screens/login_screen.dart';

Future showLoginCheckDialog(
    BuildContext context, LoginScreenArguments? arguments) {
  return showCommonDialog(
      context: context,
      title: Intl.message('modal_title_guide'),
      contents: Intl.message('modal_login_alert'),
      okBtnFn: () {
        if (arguments != null) {
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName,
              arguments: arguments);
        } else {
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
        }
      },
      cancelBtnFn: () => Navigator.pop(context, false));
}
