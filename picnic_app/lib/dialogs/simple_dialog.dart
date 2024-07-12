import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

Widget buildDialogButton(BuildContext context, String buttonText,
    Color textColor, Function() onPressed) {
  return Expanded(
    flex: 1,
    child: SizedBox(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: getTextStyle(AppTypo.BODY16B, textColor),
        ),
      ),
    ),
  );
}

void showSimpleDialog({
  required BuildContext context,
  String? title,
  Widget? titleWidget,
  String? content,
  Widget? contentWidget,
  Function()? onOk,
  Function()? onCancel,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        alignment: Alignment.center,
        child: Container(
          width: getPlatformScreenSize(context).width,
          constraints: BoxConstraints(
            minWidth: 151.w,
          ),
          padding: EdgeInsets.only(
            top: 28.h,
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title,
                  style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900),
                ),
              if (titleWidget != null) titleWidget,
              if (content != null) ...[
                SizedBox(
                  height: 12.h,
                ),
                Text(
                  content,
                  style: getTextStyle(AppTypo.BODY14R, AppColors.Grey700),
                  textAlign: TextAlign.center,
                )
              ],
              if (contentWidget != null) ...[
                SizedBox(
                  height: 12.h,
                ),
                contentWidget
              ],
              SizedBox(
                height: 28.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onCancel != null)
                    buildDialogButton(
                        context,
                        S.of(context).dialog_button_cancel,
                        AppColors.Grey700,
                        onCancel),
                  if (onOk != null)
                    buildDialogButton(context, S.of(context).dialog_button_ok,
                        AppColors.Primary500, onOk),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
