import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void showRequireLoginDialog({
  required BuildContext context,
}) {
  try {
    showSimpleDialog(
      content: S.of(context).dialog_content_login_required,
      onOk: () => Navigator.pushNamed(context, SignUpScreen.routeName)
          .then((value) => Navigator.of(context).pop(true)),
      onCancel: () => Navigator.of(context).pop(false),
    );
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);
  }
}
