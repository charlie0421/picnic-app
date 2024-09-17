import 'package:flutter/material.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

Widget buildDialogButton(BuildContext context, String buttonText,
    Color textColor, Function() onPressed) {
  return Expanded(
    flex: 1,
    child: SizedBox(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: getTextStyle(AppTypo.body16B, textColor),
        ),
      ),
    ),
  );
}

void showSimpleDialog({
  String? title,
  Widget? titleWidget,
  String? content,
  Widget? contentWidget,
  Function()? onOk,
  Function()? onCancel,
}) {
  final context = navigatorKey.currentContext;
  if (context == null) {
    logger.e('Navigator context is null in showRequireLoginDialog');
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        alignment: Alignment.center,
        child: Container(
          width: getPlatformScreenSize(context).width,
          constraints: BoxConstraints(
            minWidth: 151.cw,
          ),
          padding: EdgeInsets.only(
            top: 28,
            bottom: 20,
            left: 20.cw,
            right: 20.cw,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title,
                  style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                ),
              if (titleWidget != null) titleWidget,
              if (content != null) ...[
                const SizedBox(
                  height: 12,
                ),
                Text(
                  content,
                  style: getTextStyle(AppTypo.body14R, AppColors.grey700),
                  textAlign: TextAlign.center,
                )
              ],
              if (contentWidget != null) ...[
                const SizedBox(
                  height: 12,
                ),
                contentWidget
              ],
              const SizedBox(
                height: 28,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onCancel != null)
                    buildDialogButton(
                        context,
                        S.of(context).dialog_button_cancel,
                        AppColors.grey700,
                        onCancel),
                  if (onOk != null)
                    buildDialogButton(context, S.of(context).dialog_button_ok,
                        AppColors.primary500, onOk),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
