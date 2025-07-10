import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';

void showRequireLoginDialog() {
  if (navigatorKey.currentContext == null) {
    logger.e('navigatorKey.currentContext is null');
    return;
  }

  try {
    showSimpleDialog(
      content: AppLocalizations.of(navigatorKey.currentContext!).dialog_content_login_required,
      onOk: () async {
        if (navigatorKey.currentContext!.mounted) {
          Navigator.of(navigatorKey.currentContext!).pop();
        }
        await Future.delayed(const Duration(milliseconds: 100));
        if (navigatorKey.currentContext!.mounted) {
          Navigator.pushNamed(
              navigatorKey.currentContext!, SignUpScreen.routeName);
        }
      },
      onCancel: () {
        if (navigatorKey.currentContext!.mounted) {
          Navigator.of(navigatorKey.currentContext!).pop();
        }
      },
    );
  } catch (e, s) {
    logger.e('error', error: e, stackTrace: s);
    rethrow;
  }
}
