import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaSubmitButton {
  const QnaSubmitButton._();

  static Widget fab(BuildContext context, {required VoidCallback onPressed}) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.primary500,
      foregroundColor: Colors.white,
      elevation: 3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      icon: const Icon(Icons.edit, size: 16),
      label: Text(
        AppLocalizations.of(context).qna_submit_button,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  static Widget primary(
    BuildContext context, {
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData icon = Icons.check,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(
        AppLocalizations.of(context).qna_submit_button,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        minimumSize: const Size(64, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
