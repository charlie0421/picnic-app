// iOS simulator probe using the public notification APIs and a demo Firebase app.
// Evidence: the app container's tmp/notification-lifecycle-probe.json.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(Platform.isIOS);
  final local = FlutterLocalNotificationsPlugin();
  final output =
      File('${Directory.systemTemp.path}/notification-lifecycle-probe.json');
  final display = ValueNotifier<String>('Starting notification probe');
  final evidence = <String, dynamic>{
    'remoteOpened': <dynamic>[],
    'localResponses': <dynamic>[],
  };
  Future<void> writes = Future<void>.value();

  void save() {
    final text = jsonEncode(evidence);
    display.value = text;
    writes = writes.then((_) => output.writeAsString(text, flush: true));
  }

  runApp(MaterialApp(
      home: Scaffold(
    appBar: AppBar(title: const Text('Notification lifecycle probe')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      ElevatedButton(
          onPressed: () async {
            if (evidence['phase'] != 'ready') return;
            evidence['permission'] = await local
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()!
                .requestPermissions(alert: true, sound: true, badge: true);
            save();
          },
          child: const Text('Allow test notifications')),
      ElevatedButton(
          onPressed: () async {
            if (evidence['phase'] != 'ready') return;
            await local.zonedSchedule(
              9029,
              'LOCAL cold launch regression',
              'Tap after terminating this test app',
              tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 10)),
              const NotificationDetails(iOS: DarwinNotificationDetails()),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'foldable-regression-local-cold',
            );
            evidence['scheduledLocal'] = true;
            save();
          },
          child: const Text('Schedule local test in 10 seconds')),
      ValueListenableBuilder<String>(
          valueListenable: display,
          builder: (context, value, child) => Text(value)),
    ]),
  )));

  try {
    evidence['phase'] = 'core';
    save();
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: 'AIza00000000000000000000000000000000000',
      appId: '1:1234567890:ios:0123456789abcdef',
      messagingSenderId: '1234567890',
      projectId: 'demo-foldable-regression',
    )).timeout(const Duration(seconds: 10));
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      (evidence['remoteOpened'] as List).add(message.toMap());
      save();
    });
    await local.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ), onDidReceiveNotificationResponse: (response) {
      (evidence['localResponses'] as List).add({
        'id': response.id,
        'payload': response.payload,
      });
      save();
    });
    evidence['phase'] = 'initial-message';
    save();
    evidence['remoteInitial'] = (await FirebaseMessaging.instance
            .getInitialMessage()
            .timeout(const Duration(seconds: 10)))
        ?.toMap();
    final launch = await local.getNotificationAppLaunchDetails();
    evidence['localLaunch'] = {
      'didNotificationLaunchApp': launch?.didNotificationLaunchApp,
      'payload': launch?.notificationResponse?.payload,
    };
    evidence['phase'] = 'ready';
    save();
  } catch (error) {
    evidence['error'] = error.toString();
    save();
  }
}
