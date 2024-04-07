import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/main.reflectable.dart';
import 'package:prame_app/prame_app.dart';
import 'package:prame_app/reflector.dart';
import 'package:prame_app/util.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (isMobile()) {
    await initializeWidgetsAndDeviceOrientation(widgetsBinding);
  }

  const reflector = const Reflector();

  initializeReflectable();

  runApp(const ProviderScope(child: PrameApp()));

  globalStorage.saveData('ACCESS_TOKEN',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiZW1haWwiOiJpcm9ubG92ZTc3QGdtYWlsLmNvbSIsIm5pY2tuYW1lIjoi7JaR7J6s64-Z6rCc67Cc66i47IugIiwicHJvZmlsZUltYWdlIjoiaHR0cHM6Ly9jZG4tZGV2LjFzdHlwZS5pby91c2VyLzIvZTQzMDEzYzItMjc5OC00YTMxLWE0ZWUtZTMyZjIyNTkzMGEzLmpwZyIsInJvbGUiOiJ1c2VyIiwiaXNzIjoiMXN0eXBlIiwidHlwZSI6IkFDQ0VTU19UT0tFTiIsImlhdCI6MTcxMjUwMjk0OSwiZXhwIjoxNzEyNTAzMDA5fQ.UQkXaGjU00br5vi8n9JJOGG83HP-fZmJC5rYKLQIwtI');
  globalStorage.saveData('REFRESH_TOKEN',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiZW1haWwiOiJpcm9ubG92ZTc3QGdtYWlsLmNvbSIsIm5pY2tuYW1lIjoi7JaR7J6s64-Z6rCc67Cc66i47IugIiwicHJvZmlsZUltYWdlIjoiaHR0cHM6Ly9jZG4tZGV2LjFzdHlwZS5pby91c2VyLzIvZTQzMDEzYzItMjc5OC00YTMxLWE0ZWUtZTMyZjIyNTkzMGEzLmpwZyIsInJvbGUiOiJ1c2VyIiwiaXNzIjoiMXN0eXBlIiwidHlwZSI6IlJFRlJFU0hfVE9LRU4iLCJpYXQiOjE3MTIzOTg2MzcsImV4cCI6MTc0MzkzNDYzN30.u1knDrjR6HMy4bEh654vsZuHyWrM8QW0e2Ec2LsZJIs');

  FlutterNativeSplash.remove();
}

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}
