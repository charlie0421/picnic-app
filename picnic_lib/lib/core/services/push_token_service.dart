import 'dart:io';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _apnsWaited = false;
  static bool _notificationsInitialized = false;
  static Function(RemoteMessage)? _onNotificationTap;
  static Function(String)? _onActionUrlTap;

  static Future<void> initialize({
    Function(RemoteMessage)? onNotificationTap,
    Function(String)? onActionUrlTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    _onActionUrlTap = onActionUrlTap;
    if (kIsWeb) return; // Web handled in Next.js app

    try {
      final totalSw = Stopwatch()..start();

      // 로컬 알림 초기화 (포그라운드 알림 표시용)
      if (!_notificationsInitialized) {
        await _initializeLocalNotifications();
        _notificationsInitialized = true;
      }

      if (Platform.isIOS) {
        final permSw = Stopwatch()..start();
        final settings = await _messaging
            .requestPermission(alert: true, badge: true, sound: true)
            .timeout(const Duration(seconds: 5));
        permSw.stop();
        logger.i(
          'iOS notification permission: ${settings.authorizationStatus} (took ${permSw.elapsedMilliseconds}ms)',
        );
      } else if (Platform.isAndroid) {
        final permSw = Stopwatch()..start();
        final status = await Permission.notification.request().timeout(
          const Duration(seconds: 5),
        );
        permSw.stop();
        logger.i(
          'Android notification permission: $status (took ${permSw.elapsedMilliseconds}ms)',
        );
      }

      // iOS: APNS 토큰이 준비되기 전에 getToken()을 호출하면 예외가 발생할 수 있음
      if (Platform.isIOS) {
        final apnsSw = Stopwatch()..start();
        final apnsToken = await _awaitAPNSToken(
          timeout: const Duration(seconds: 10),
        );
        apnsSw.stop();
        logger.i(
          'APNS token ${apnsToken == null ? 'not ready' : 'ready'} (waited ${apnsSw.elapsedMilliseconds}ms)',
        );
        if (apnsToken == null) {
          // 이후 onTokenRefresh 리스너에서 처리되도록 지연
          logger.w(
            'Deferring FCM getToken() until APNS token becomes available',
          );
        }
      }

      final tokenSw = Stopwatch()..start();
      String? fcmToken;
      try {
        fcmToken = await _messaging.getToken().timeout(
          const Duration(seconds: 8),
        );
      } catch (e) {
        // APNS 미준비 등으로 실패 시, onTokenRefresh에서 후속 처리되도록 넘어간다
        logger.w(
          'getToken() failed early; will rely on onTokenRefresh. reason=$e',
        );
      }
      tokenSw.stop();
      final preview = fcmToken == null
          ? 'null'
          : (fcmToken.length > 12
                ? '${fcmToken.substring(0, 12)}...'
                : fcmToken);
      logger.i('FCM token: $preview (took ${tokenSw.elapsedMilliseconds}ms)');
      if (fcmToken != null) {
        final sessionReady =
            supabase.auth.currentSession?.accessToken.isNotEmpty == true;
        if (sessionReady) {
          // 초기화 지연을 막기 위해 비동기 호출로 전환
          // ignore: unawaited_futures
          registerToken(fcmToken);
        } else {
          logger.w(
            'Auth session not ready; will register push token on sign-in event',
          );
          supabase.auth.onAuthStateChange.listen((AuthState state) {
            if (state.event == AuthChangeEvent.signedIn) {
              // ignore: unawaited_futures
              registerToken(fcmToken!);
            }
          });
        }
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
        // 토큰 재등록은 실패하더라도 초기화 플로우를 막지 않도록 fire-and-forget
        // ignore: unawaited_futures
        registerToken(token);
      });

      // 앱 포그라운드 수신 처리 및 알림 표시
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        final title =
            msg.notification?.title ?? msg.data['title'] ?? '(no-title)';
        final body = msg.notification?.body ?? msg.data['body'] ?? '';
        logger.i(
          '[FCM] onMessage (foreground) title="$title" body="$body" data=${msg.data}',
        );

        // 포그라운드에서 알림 표시
        if (title != '(no-title)' && body.isNotEmpty) {
          await _showLocalNotification(
            title: title,
            body: body,
            data: msg.data,
          );
        }
      });

      // 백그라운드에서 알림 클릭 시 처리
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
        logger.i(
          '[FCM] onMessageOpenedApp (background tap) title="${msg.notification?.title}" data=${msg.data}',
        );
        _handleNotificationTap(msg);
      });

      // 앱이 종료된 상태에서 알림으로 시작된 경우 처리
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        logger.i(
          '[FCM] getInitialMessage (terminated tap) title="${initialMessage.notification?.title}" data=${initialMessage.data}',
        );
        // 앱이 완전히 초기화된 후 처리하기 위해 약간의 지연
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }

      totalSw.stop();
      logger.i(
        'PushTokenService.initialize completed in ${totalSw.elapsedMilliseconds}ms',
      );
    } catch (e, s) {
      final type = e.runtimeType.toString();
      logger.e(
        'PushTokenService initialize failed ($type)',
        error: e,
        stackTrace: s,
      );
    }
  }

  static Future<void> registerToken(String token) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        logger.w('registerToken skipped: no authenticated user');
        return;
      }

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : Platform.isMacOS
          ? 'macos'
          : Platform.isWindows
          ? 'windows'
          : 'web';

      final uriPreview =
          '${Environment.supabaseUrl}/functions/v1/register-push-token';
      final sw = Stopwatch()..start();
      logger.i(
        'Registering push token to Supabase Edge: POST $uriPreview (uid: ${user.id.substring(0, 6)}..., platform: $platform)',
      );

      // 최신 세션 토큰 확보 (v2 API 호환)
      var accessToken = supabase.auth.currentSession?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        final refreshed = await supabase.auth.refreshSession();
        accessToken = refreshed.session?.accessToken ?? accessToken;
      }
      if (accessToken == null || accessToken.isEmpty) {
        logger.e(
          'registerToken aborted: accessToken missing (user exists but session not ready)',
        );
        return;
      }

      // 다른 invoke 성공 사례와 동일하게, 명시적으로 클라이언트를 생성해 호출
      final client = SupabaseClient(
        Environment.supabaseUrl,
        Environment.supabaseAnonKey,
      );
      final res = await client.functions
          .invoke(
            'register-push-token',
            headers: {'Authorization': 'Bearer $accessToken'},
            body: {'platform': platform, 'token': token},
          )
          .timeout(const Duration(seconds: 12));
      sw.stop();
      if (res.status >= 300) {
        logger.e(
          'Failed to register push token: status=${res.status}, data=${res.data} (took ${sw.elapsedMilliseconds}ms)',
        );
      } else {
        logger.i('Push token registered (took ${sw.elapsedMilliseconds}ms)');
      }
    } on TimeoutException catch (e, s) {
      logger.e('registerToken timeout after 12s', error: e, stackTrace: s);
      // 1회 재시도 (워밍/일시 지연 대응)
      try {
        final refreshed = await supabase.auth.refreshSession();
        final retryToken =
            refreshed.session?.accessToken ??
            supabase.auth.currentSession?.accessToken;
        if (retryToken != null && retryToken.isNotEmpty) {
          final client = SupabaseClient(
            Environment.supabaseUrl,
            Environment.supabaseAnonKey,
          );
          final res = await client.functions
              .invoke(
                'register-push-token',
                headers: {'Authorization': 'Bearer $retryToken'},
                body: {
                  'platform': Platform.isIOS
                      ? 'ios'
                      : Platform.isAndroid
                      ? 'android'
                      : Platform.isMacOS
                      ? 'macos'
                      : Platform.isWindows
                      ? 'windows'
                      : 'web',
                  'token': token,
                },
              )
              .timeout(const Duration(seconds: 12));
          if (res.status >= 300) {
            logger.e(
              'Retry after timeout failed: status=${res.status}, data=${res.data}',
            );
          } else {
            logger.i('Push token registered on retry after timeout');
            return;
          }
        }
      } catch (ee, ss) {
        logger.e(
          'registerToken retry after timeout failed',
          error: ee,
          stackTrace: ss,
        );
      }
    } on SocketException catch (e, s) {
      logger.e(
        'registerToken network error (SocketException)',
        error: e,
        stackTrace: s,
      );
    } on FunctionException catch (e, s) {
      // 함수 예외 상세 로그 및 401 일회 재시도
      try {
        logger.e(
          'registerToken function error: status=${e.status}, details=${e.details}',
          error: e,
          stackTrace: s,
        );
        if (e.status == 401) {
          logger.w(
            'registerToken got 401 -> refreshing session and retrying once',
          );
          final refreshed = await supabase.auth.refreshSession();
          final retryToken = refreshed.session?.accessToken;
          if (retryToken != null && retryToken.isNotEmpty) {
            final client = SupabaseClient(
              Environment.supabaseUrl,
              Environment.supabaseAnonKey,
            );
            final res = await client.functions.invoke(
              'register-push-token',
              headers: {'Authorization': 'Bearer $retryToken'},
              body: {
                'platform': Platform.isIOS
                    ? 'ios'
                    : Platform.isAndroid
                    ? 'android'
                    : Platform.isMacOS
                    ? 'macos'
                    : Platform.isWindows
                    ? 'windows'
                    : 'web',
                'token': token,
              },
            );
            if (res.status >= 300) {
              logger.e(
                'Retry failed to register push token: status=${res.status}, data=${res.data}',
              );
            } else {
              logger.i('Push token registered on retry');
            }
            return;
          } else {
            logger.e('Session refresh returned no token; aborting');
          }
        }
      } catch (ee, ss) {
        logger.e(
          'registerToken error handling failed',
          error: ee,
          stackTrace: ss,
        );
      }
    } catch (e, s) {
      final type = e.runtimeType.toString();
      logger.e('registerToken failed ($type)', error: e, stackTrace: s);
    }
  }

  static Future<String?> _awaitAPNSToken({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (_apnsWaited) return null;
      _apnsWaited = true;
      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (_) {}
    return null;
  }

  /// 로컬 알림 초기화
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          logger.i('[FCM] Local notification tapped: ${response.payload}');
          // 로컬 알림 탭 처리 (포그라운드 알림)
          // payload는 action_url이 포함된 문자열
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              // payload에서 action_url 추출 시도
              // payload 형식: "{action_url: https://applink.picnic.fan/...}"
              final payloadStr = response.payload!;
              // 간단한 파싱: action_url이 포함되어 있으면 추출
              if (payloadStr.contains('action_url')) {
                final uriMatch = RegExp(
                  r'https?://[^\s}]+',
                ).firstMatch(payloadStr);
                if (uriMatch != null) {
                  final actionUrl = uriMatch.group(0);
                  if (actionUrl != null && actionUrl.isNotEmpty) {
                    logger.i(
                      '[FCM] Extracted action_url from local notification: $actionUrl',
                    );
                    if (_onActionUrlTap != null) {
                      _onActionUrlTap!(actionUrl);
                    } else {
                      logger.w('[FCM] onActionUrlTap callback not set');
                    }
                  }
                }
              }
            } catch (e) {
              logger.e(
                '[FCM] Failed to parse local notification payload',
                error: e,
              );
            }
          }
        },
      );

      // Android 알림 채널 생성
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // name
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidChannel);
      }

      logger.i('Local notifications initialized');
    } catch (e, s) {
      logger.e(
        'Failed to initialize local notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// 로컬 알림 표시
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 고유 ID 생성 (타임스탬프 기반)
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      // payload에 action_url 포함 (로컬 알림 탭 시 사용)
      final payload = data != null && data.containsKey('action_url')
          ? 'action_url: ${data['action_url']}'
          : data?.toString();

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      logger.i('[FCM] Local notification shown: title="$title" body="$body"');
    } catch (e, s) {
      logger.e('Failed to show local notification', error: e, stackTrace: s);
    }
  }

  /// 알림 탭 처리
  static void _handleNotificationTap(RemoteMessage msg) {
    try {
      final actionUrl = msg.data['action_url'];
      if (actionUrl != null && actionUrl is String && actionUrl.isNotEmpty) {
        logger.i('[FCM] Handling notification tap with action_url: $actionUrl');
        if (_onNotificationTap != null) {
          _onNotificationTap!(msg);
        } else {
          logger.w('[FCM] onNotificationTap callback not set');
        }
      } else {
        logger.i(
          '[FCM] Notification tap but no action_url in data: ${msg.data}',
        );
      }
    } catch (e, s) {
      logger.e(
        '[FCM] Failed to handle notification tap',
        error: e,
        stackTrace: s,
      );
    }
  }
}
