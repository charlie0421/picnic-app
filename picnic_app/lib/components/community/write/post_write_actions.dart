import 'package:flutter/material.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
                  content: '제목을 입력해 주세요.',
                  onOk: () => Navigator.of(context).pop(),
                ),
          child: Text(
            S.of(context).post_header_temporary_save,
            style: getTextStyle(AppTypo.body14B, AppColors.primary500),
          ),
        ),
        SizedBox(width: 16.cw),
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
                side: const BorderSide(color: AppColors.primary500, width: 1),
              ),
            ),
            onPressed: isTitleValid
                ? () => onSave(false)
                : () => showSimpleDialog(
                      content: '제목을 입력해 주세요.',
                      onOk: () => Navigator.of(context).pop(),
                    ),
            child: Text(S.of(context).post_header_publish),
          ),
        ),
      ],
    );
  }
}
