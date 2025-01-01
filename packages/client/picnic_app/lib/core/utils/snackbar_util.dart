import 'package:flutter/material.dart';

class SnackbarUtil {
  static final SnackbarUtil _instance = SnackbarUtil._internal();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  factory SnackbarUtil() {
    return _instance;
  }

  SnackbarUtil._internal();

  void showSnackbar(
    String message, {
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
