import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/ui/style.dart';

void showSimpleDialog({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  Function? onOk,
  Function? onCancel,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        alignment: Alignment.center,
        child: Container(
          width: 361.w,
          constraints: const BoxConstraints(
            minWidth: 151,
          ),
          padding: EdgeInsets.symmetric(
            vertical: 20.w,
            horizontal: 28.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900),
              ),
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
                    SizedBox(
                      width: 100.w,
                      child: TextButton(
                        child: Text(
                          Intl.message('dialog_button_cancel'),
                          style:
                              getTextStyle(AppTypo.BODY14B, AppColors.Mint500),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCancel();
                        },
                      ),
                    ),
                  if (onOk != null)
                    SizedBox(
                      width: 100.w,
                      child: TextButton(
                        child: Text(
                          Intl.message('dialog_button_ok'),
                          style: getTextStyle(
                              AppTypo.BODY14B, AppColors.Primary500),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOk();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
