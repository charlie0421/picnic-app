import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

final localeProvider = StateProvider<Locale>((ref) => const Locale('ko_KR'));

