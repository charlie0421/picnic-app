import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

void showSimpleDialog({
  required BuildContext context,
  String? title,
  Widget? titleWidget,
  String? content,
  Widget? contentWidget,
  Widget? footerWidget,
  Function? onOk,
  Function? onCancel,
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
          padding: EdgeInsets.symmetric(
            vertical: 20.w,
            horizontal: 28.w,
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
              if (content != null)
                SizedBox(
                  height: 12.w,
                ),
              if (content != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).w,
                  child: Text(
                    content,
                    style: getTextStyle(AppTypo.BODY14R, AppColors.Grey900),
                  ),
                ),
              if (contentWidget != null)
                SizedBox(
                  height: 12.w,
                ),
              if (contentWidget != null) contentWidget,
              SizedBox(
                height: 28.w,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onCancel != null)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        child: TextButton(
                          child: Text(
                            S.of(context).dialog_button_cancel,
                            style: getTextStyle(
                                AppTypo.BODY16B, AppColors.Mint500),
                          ),
                          onPressed: () {
                            onCancel();
                          },
                        ),
                      ),
                    ),
                  if (onOk != null)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        child: TextButton(
                          child: Text(
                            S.of(context).dialog_button_ok,
                            style: getTextStyle(
                                AppTypo.BODY16B, AppColors.Primary500),
                          ),
                          onPressed: () {
                            onOk();
                          },
                        ),
                      ),
                    ),
                ],
              ),
              if (footerWidget != null) footerWidget,
            ],
          ),
        ),
      );
    },
  );
}
