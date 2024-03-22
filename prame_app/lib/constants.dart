import 'package:prame_app/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

const mainColorLightMode = Color(0xFF07E88F);
const mainColorDarkMode = Color(0xFF08C97E);
const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const String userApiUrl = String.fromEnvironment('API_USER_ROOT',
      defaultValue: 'https://api-dev.1stype.io/user');
  static const String authApiUrl = String.fromEnvironment(
    'API_AUTH_ROOT',
    defaultValue: 'https://api-dev.1stype.io/auth',
  );
  static double webMaxWidth = 600.0;
  static int snackBarDuration = 3;
  static Color mainColor = const Color(0xFF0A481E);
}

var logger = Logger();


LocalStorage globalStorage = LocalStorage();

