import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/supabase_options.dart';

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  showSimpleDialog(
      content: AppLocalizations.of(context).text_copied_address,
      onOk: () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
}

final numberFormatter = NumberFormat('#,###');

Future<bool> checkSession() async {
  try {
    final session = supabase.auth.currentSession;
    return session != null;
  } catch (e, s) {
    logger.e('session fail: $e', stackTrace: s);
    await supabase.auth.signOut();
    return false;
  }
}
