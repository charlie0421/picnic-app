import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';

class PushTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Web handled in Next.js app

    try {
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        logger.i(
          'iOS notification permission: ${settings.authorizationStatus}',
        );
      } else if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        logger.i('Android notification permission: $status');
      }

      final fcmToken = await _messaging.getToken();
      final preview = fcmToken == null
          ? 'null'
          : (fcmToken.length > 12
                ? '${fcmToken.substring(0, 12)}...'
                : fcmToken);
      logger.i('FCM token: $preview');
      if (fcmToken != null) {
        await registerToken(fcmToken);
      }

      // Subscribe to broadcast topic 'all' for global notifications (mobile only)
      try {
        if (Platform.isIOS || Platform.isAndroid) {
          await _messaging.subscribeToTopic('all');
          logger.i('Subscribed to FCM topic: all');
        }
      } catch (e, s) {
        logger.w('Failed to subscribe topic all: $e');
        logger.d('$s');
      }

      _messaging.onTokenRefresh.listen((token) async {
        logger.i('FCM token refreshed');
        await registerToken(token);
      });
    } catch (e, s) {
      logger.e('PushTokenService initialize failed', error: e, stackTrace: s);
    }
  }

  static Future<void> registerToken(String token) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : Platform.isMacOS
          ? 'macos'
          : Platform.isWindows
          ? 'windows'
          : 'web';

      final res = await supabase.functions.invoke(
        'register-push-token',
        body: {'platform': platform, 'token': token},
      );
      if (res.status >= 300) {
        logger.e('Failed to register push token: ${res.data}');
      } else {
        logger.i('Push token registered');
      }
    } catch (e, s) {
      logger.e('registerToken failed', error: e, stackTrace: s);
    }
  }
}
