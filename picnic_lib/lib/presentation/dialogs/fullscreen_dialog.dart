import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

// 공통 상수 정의
class FullScreenDialogConstants {
  static const double closeButtonSize = 48;
  static const Duration transitionDuration = Duration(milliseconds: 300);
}

// 전체화면 다이얼로그 표시 함수
Future<T?> showFullScreenDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: FullScreenDialogConstants.transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return builder(buildContext);
    },
  );
}

// 전체화면 다이얼로그 위젯
class FullScreenDialog extends StatefulWidget {
  final Widget child;
  final Widget? closeButton;
  final Color? closeButtonColor;
  final EdgeInsets? contentPadding;
  final BorderRadius? borderRadius;

  const FullScreenDialog({
    super.key,
    required this.child,
    this.closeButton,
    this.closeButtonColor,
    this.contentPadding,
    this.borderRadius,
  });

  @override
  State<FullScreenDialog> createState() => _FullScreenDialogState();
}

class _FullScreenDialogState extends State<FullScreenDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(0),
      ),
      child: Container(
        color: AppColors.grey00,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            widget.child,
            if (widget.closeButton != null)
              Positioned(
                top: 50,
                right: 15,
                child: widget.closeButton!,
              )
            else
              Positioned(
                top: 50,
                right: 15,
                child: _buildCloseButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: FullScreenDialogConstants.closeButtonSize,
        height: FullScreenDialogConstants.closeButtonSize,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}
