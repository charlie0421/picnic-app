import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/ui/style.dart';

class DialogType {
  static const normal = 'normal';
  static const error = 'error';
}

Widget buildDialogButton(
  BuildContext context,
  String buttonText,
  Color textColor,
  Function() onPressed,
) {
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
  String type = DialogType.normal,
}) {
  final context = navigatorKey.currentContext;
  if (context == null) {
    logger.e('Navigator context is null in showSimpleDialog');
    return;
  }

  // 에러 타입일 때 사용할 색상
  final backgroundColor =
      type == DialogType.error ? AppColors.grey00 : Colors.white;
  final titleColor =
      type == DialogType.error ? AppColors.point900 : AppColors.grey900;
  final contentColor =
      type == DialogType.error ? AppColors.point900 : AppColors.grey700;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // 애니메이션 설정
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: Dialog(
            alignment: Alignment.center,
            child: Container(
              width: getPlatformScreenSize(context).width,
              constraints: BoxConstraints(
                minWidth: 151.w,
              ),
              padding: EdgeInsets.only(
                top: 28,
                bottom: 20,
                left: 20.w,
                right: 20.w,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: type == DialogType.error
                    ? [
                        BoxShadow(
                          color: AppColors.grey300,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == DialogType.error) ...[
                      Icon(
                        Icons.error_outline,
                        color: AppColors.point900,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (title != null)
                      Text(
                        title,
                        style: getTextStyle(AppTypo.title18B, titleColor),
                        textAlign: TextAlign.center,
                      ),
                    if (titleWidget != null) titleWidget,
                    if (content != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        content,
                        style: getTextStyle(AppTypo.body14R, contentColor),
                        textAlign: TextAlign.center,
                      )
                    ],
                    if (contentWidget != null) ...[
                      const SizedBox(height: 12),
                      contentWidget
                    ],
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onCancel != null)
                          buildDialogButton(
                            context,
                            t('dialog_button_cancel'),
                            type == DialogType.error
                                ? AppColors.point900
                                : AppColors.grey700,
                            onCancel,
                          ),
                        if (onOk != null)
                          buildDialogButton(
                            context,
                            t('dialog_button_ok'),
                            type == DialogType.error
                                ? AppColors.point900
                                : AppColors.primary500,
                            onOk,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  SnackbarUtil().showSnackbar(
    'Dialog shown successfully!',
    duration: const Duration(seconds: 3),
  );
}

void showSimpleErrorDialog(
  BuildContext context,
  String message, {
  dynamic error,
  bool truncateError = true,
  String type = DialogType.error,
}) {
  if (!context.mounted) return;

  String displayMessage = message;
  if (error != null) {
    final errorMsg = error.toString();
    final truncatedError = truncateError && errorMsg.length > 150
        ? '${errorMsg.substring(0, 150)}...'
        : errorMsg;
    displayMessage = '$message\n\n$truncatedError';
  }

  showSimpleDialog(
    type: type,
    content: displayMessage,
  );
}
