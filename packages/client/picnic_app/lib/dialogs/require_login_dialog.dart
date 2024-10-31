import 'package:flutter/material.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';
import 'package:picnic_app/util/logger.dart';

void showRequireLoginDialog() {
  if (navigatorKey.currentContext == null) {
    logger.e('navigatorKey.currentContext is null');
    return;
  }

  try {
    showSimpleDialog(
      content: S.of(navigatorKey.currentContext!).dialog_content_login_required,
      onOk: () => Navigator.pushNamed(
              navigatorKey.currentContext!, SignUpScreen.routeName)
          .then(
              (value) => Navigator.of(navigatorKey.currentContext!).pop(true)),
      onCancel: () => Navigator.of(navigatorKey.currentContext!).pop(false),
    );
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    rethrow;
  }
}
