import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class SnackbarUtil {
  static final SnackbarUtil _instance = SnackbarUtil._internal();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  factory SnackbarUtil() {
    return _instance;
  }

  SnackbarUtil._internal();

  /// 타입 구분용 스낵바 종류
  /// - success: 성공 알림 (primary)
  /// - error: 오류 알림 (statusError)
  /// - info: 정보성 알림 (point)
  /// - warning: 경고 알림 (secondary)
  static const _defaultDuration = Duration(seconds: 2);

  void show(
    String message, {
    SnackType type = SnackType.info,
    Duration duration = _defaultDuration,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    BuildContext? context,
  }) {
    final Color bgColor = switch (type) {
      SnackType.success => AppColors.primary500,
      SnackType.error => AppColors.statusError,
      SnackType.info => AppColors.point500,
      SnackType.warning => AppColors.secondary500,
    };

    final messenger = context != null
        ? (ScaffoldMessenger.maybeOf(context) ??
            scaffoldMessengerKey.currentState)
        : scaffoldMessengerKey.currentState;

    if (messenger == null) {
      return;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bgColor,
      duration: duration,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, color: Colors.white),
            ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    messenger.clearSnackBars();
    messenger.showSnackBar(snackBar);
  }

  void success(String message,
      {Duration duration = _defaultDuration,
      IconData icon = Icons.check_circle,
      String? actionLabel,
      VoidCallback? onAction,
      BuildContext? context}) {
    show(message,
        type: SnackType.success,
        duration: duration,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        context: context);
  }

  void error(String message,
      {Duration duration = _defaultDuration,
      IconData icon = Icons.error,
      String? actionLabel,
      VoidCallback? onAction,
      BuildContext? context}) {
    show(message,
        type: SnackType.error,
        duration: duration,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        context: context);
  }

  void info(String message,
      {Duration duration = _defaultDuration,
      IconData icon = Icons.info,
      String? actionLabel,
      VoidCallback? onAction,
      BuildContext? context}) {
    show(message,
        type: SnackType.info,
        duration: duration,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        context: context);
  }

  void warning(String message,
      {Duration duration = _defaultDuration,
      IconData icon = Icons.warning,
      String? actionLabel,
      VoidCallback? onAction,
      BuildContext? context}) {
    show(message,
        type: SnackType.warning,
        duration: duration,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        context: context);
  }
}

enum SnackType { success, error, info, warning }
