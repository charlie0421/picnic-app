import 'package:flutter/foundation.dart';

class Logger {
  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('INFO: $message');
      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('WARNING: $message');
      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }
}

final logger = Logger();
