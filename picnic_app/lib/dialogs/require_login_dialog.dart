import 'package:flutter/material.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';

void showRequireLoginDialog({
  required BuildContext context,
  String? title,
  Widget? titleWidget,
  String? content,
  Widget? contentWidget,
  Widget? footerWidget,
}) {
  showSimpleDialog(
    context: context,
    content: S.of(context).dialog_content_login_required,
    footerWidget: footerWidget,
    onOk: () => Navigator.pushNamed(context, SignUpScreen.routeName)
        .then((value) => Navigator.of(context).pop(true)),
    onCancel: () => Navigator.of(context).pop(false),
  );
}
