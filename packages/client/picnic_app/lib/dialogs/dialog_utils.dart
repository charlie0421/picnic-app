import 'package:flutter/material.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';

void closeDialogWithResult(BuildContext context, bool result) {
  Navigator.of(context).pop(result);
}

void showRequireLoginDialog({required BuildContext context}) {
  showSimpleDialog(
    context: context,
    content: S.of(context).dialog_content_login_required,
    onOk: () => Navigator.pushNamed(context, SignUpScreen.routeName)
        .then((value) => closeDialogWithResult(context, true)),
    onCancel: () => closeDialogWithResult(context, false),
  );
}
