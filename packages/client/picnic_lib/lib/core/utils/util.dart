import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  showSimpleDialog(
      content: S.of(context).text_copied_address,
      onOk: () => Navigator.of(context).pop());
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
