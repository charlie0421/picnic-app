import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';

void showRequireLoginDialog() {
  final context = navigatorKey.currentContext;
  if (context == null) {
    logger.e('navigatorKey.currentContext is null');
    return;
  }

  try {
    showSimpleDialog(
      content: AppLocalizations.of(context).dialog_content_login_required,
      onOk: () async {
        final navContext = navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          Navigator.of(navContext).pop();
        }
        await Future.delayed(const Duration(milliseconds: 100));
        final navContext2 = navigatorKey.currentContext;
        if (navContext2 != null && navContext2.mounted) {
          Navigator.pushNamed(navContext2, SignUpScreen.routeName);
        }
      },
      onCancel: () {
        final navContext = navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          Navigator.of(navContext).pop();
        }
      },
    );
  } catch (e, s) {
    logger.e('error', error: e, stackTrace: s);
    rethrow;
  }
}
