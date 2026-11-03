import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';

class QnaSubmitButton {
  const QnaSubmitButton._();

  static Widget fab(BuildContext context, {required VoidCallback onPressed}) {
    return PicnicActionButton(
      key: const Key('qna-create-action'),
      label: AppLocalizations.of(context).qna_submit_button,
      onPressed: onPressed,
      icon: const Icon(Icons.edit, size: 20),
    );
  }

  static Widget primary(
    BuildContext context, {
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData icon = Icons.check,
  }) {
    return PicnicActionButton(
      label: AppLocalizations.of(context).qna_submit_button,
      onPressed: onPressed,
      isLoading: isLoading,
      busySemanticLabel: AppLocalizations.of(context).loading,
      icon: Icon(icon, size: 20),
    );
  }
}
