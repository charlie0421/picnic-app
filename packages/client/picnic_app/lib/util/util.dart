import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/supabase_options.dart';

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
    logger.e('세션 확인 중 오류 발생: $e', stackTrace: s);
    await supabase.auth.signOut();
    return false;
  }
}
