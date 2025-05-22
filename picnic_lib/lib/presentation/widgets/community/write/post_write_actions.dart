import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/ui/style.dart';

class PostWriteActions extends StatelessWidget {
  final bool isTitleValid;
  final Function(bool isTemporary) onSave;

  const PostWriteActions({
    super.key,
    required this.isTitleValid,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => isTitleValid
              ? onSave(true)
              : showSimpleDialog(
                  content: t('post_hint_title'),
                  onOk: () => Navigator.of(context).pop(),
                ),
          child: Text(
            t('post_header_temporary_save'),
            style: getTextStyle(AppTypo.body14B, AppColors.primary500),
          ),
        ),
        SizedBox(width: 16.w),
        SizedBox(
          height: 32,
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                backgroundColor: AppColors.grey00,
                textStyle: getTextStyle(AppTypo.body14B),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.primary500, width: 1),
                ),
              ),
              onPressed: isTitleValid
                  ? () => onSave(false)
                  : () => showSimpleDialog(
                        content: t('post_hint_title'),
                        onOk: () => Navigator.of(context).pop(),
                      ),
              child: Text(
                t('post_header_publish'),
              )),
        ),
      ],
    );
  }
}
