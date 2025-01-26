import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ttja_app/app.dart';
import 'package:ttja_app/firebase_options.dart';
import 'package:ttja_app/main.reflectable.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';

void main() async {
  await runZonedGuarded(() async {
    try {
      logger.i('Starting app initialization...');

      await AppInitializer.initializeBasics();
      await AppInitializer.initializeEnvironment('prod');
      await AppInitializer.initializeSentry();

      await initializeSupabase();
      await AppInitializer.initializeWebP();
      await AppInitializer.initializeTapjoy();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await AppInitializer.initializeAuth();
      await AppInitializer.initializeTimezone();
      initializeReflectable();
      await AppInitializer.initializePrivacyConsent();

      setPathUrlStrategy();

      logger.i('Starting app...');
      runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
      logger.i('App started successfully');
    } catch (e, s) {
      logger.e('Error during initialization', error: e, stackTrace: s);
      rethrow;
    }
  }, (Object error, StackTrace s) async {
    logger.e('Main Uncaught error', error: error, stackTrace: s);
    await Sentry.captureException(error, stackTrace: s);
  });
}

void logStorageData() async {
  const storage = FlutterSecureStorage();
  final storageData = await storage.readAll();

  final storageDataString =
      storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  logger.i(storageDataString);
}

Future<void> requestAppTrackingTransparency() async {
  await PrivacyConsentManager.initialize();
}
