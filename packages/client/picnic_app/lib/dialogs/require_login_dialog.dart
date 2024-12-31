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

  final context = navigatorKey.currentContext!;

  try {
    showSimpleDialog(
      content: S.of(context).dialog_content_login_required,
      onOk: () async {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          Navigator.pushNamed(context, SignUpScreen.routeName);
        }
      },
      onCancel: () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );
  } catch (e, s) {
    logger.e('error', error: e, stackTrace: s);
    rethrow;
  }
}
