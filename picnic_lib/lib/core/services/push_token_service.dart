import 'dart:io';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/services/locale_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _apnsWaited = false;
  static bool _notificationsInitialized = false;
  static Function(RemoteMessage)? _onNotificationTap;
  static Function(String)? _onActionUrlTap;
  static PushTokenInitializationCoordinator? _coordinator;
  static PushTokenInitializationCoordinator Function()?
  _debugCoordinatorFactory;
  static int _ownerGeneration = 0;

  static Future<void> initialize({
    Function(RemoteMessage)? onNotificationTap,
    Function(String)? onActionUrlTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    _onActionUrlTap = onActionUrlTap;
    if (kIsWeb) return; // Web handled in Next.js app
    _coordinator ??= (_debugCoordinatorFactory ?? _createCoordinator)();
    await _coordinator!.initialize();
  }

  static Future<void> resume() async {
    if (kIsWeb) return;
    _coordinator ??= (_debugCoordinatorFactory ?? _createCoordinator)();
    await _coordinator!.resume();
  }

  static Future<void> dispose() async {
    _ownerGeneration++;
    final coordinator = _coordinator;
    _coordinator = null;
    _onNotificationTap = null;
    _onActionUrlTap = null;
    if (coordinator != null) await coordinator.dispose();
  }

  static PushTokenInitializationCoordinator _createCoordinator() {
    final owner = _ownerGeneration;
    return PushTokenInitializationCoordinator(
      PushInitializationDependencies(
        initializeLocalNotifications: () async {
          if (_notificationsInitialized) return;
          await _initializeLocalNotifications();
          _notificationsInitialized = true;
        },
        requestPermission: () async {
          if (Platform.isIOS) {
            final settings = await _messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
            return _isAuthorized(settings.authorizationStatus)
                ? PushPermissionStatus.granted
                : PushPermissionStatus.denied;
          }
          if (Platform.isAndroid) {
            final status = await Permission.notification.request();
            return status.isGranted
                ? PushPermissionStatus.granted
                : PushPermissionStatus.denied;
          }
          return PushPermissionStatus.denied;
        },
        checkPermission: () async {
          if (Platform.isIOS) {
            final settings = await _messaging.getNotificationSettings();
            return _isAuthorized(settings.authorizationStatus)
                ? PushPermissionStatus.granted
                : PushPermissionStatus.denied;
          }
          if (Platform.isAndroid) {
            final status = await Permission.notification.status;
            return status.isGranted
                ? PushPermissionStatus.granted
                : PushPermissionStatus.denied;
          }
          return PushPermissionStatus.denied;
        },
        getToken: _getTokenForRegistration,
        subscribeToBroadcastTopic: () => _supportsBroadcastTopics
            ? _messaging.subscribeToTopic('all')
            : Future<void>.value(),
        registerToken: (token) {
          final userId = supabase.auth.currentUser?.id;
          if (userId == null) return Future<void>.value();
          return _registerToken(token, owner: owner, userId: userId);
        },
        tokenRefreshes: _messaging.onTokenRefresh,
        foregroundMessages: FirebaseMessaging.onMessage.cast<Object>(),
        openedMessages: FirebaseMessaging.onMessageOpenedApp.cast<Object>(),
        authChanges: supabase.auth.onAuthStateChange.cast<Object>(),
        isSignedIn: () =>
            supabase.auth.currentSession?.accessToken.isNotEmpty == true,
        isSignedInEvent: (event) =>
            event is AuthState && event.event == AuthChangeEvent.signedIn,
        onForegroundMessage: (message) async {
          if (owner != _ownerGeneration) return;
          await _handleForegroundMessage(message as RemoteMessage);
        },
        onOpenedMessage: (message) {
          if (owner != _ownerGeneration) return;
          final remoteMessage = message as RemoteMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (owner != _ownerGeneration) return;
            _handleNotificationTap(remoteMessage);
          });
        },
        getInitialMessage: () => _messaging.getInitialMessage(),
        onError: (error, stackTrace) {
          logger.e(
            'Push initialization step failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  static bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static Future<String?> _getTokenForRegistration() async {
    if (Platform.isIOS) {
      await _awaitAPNSToken(timeout: const Duration(seconds: 10));
    }
    return _messaging.getToken().timeout(const Duration(seconds: 8));
  }

  static Future<void> _handleForegroundMessage(RemoteMessage msg) async {
    final title = msg.notification?.title ?? msg.data['title'] ?? '(no-title)';
    final body = msg.notification?.body ?? msg.data['body'] ?? '';
    logger.i(
      '[FCM] onMessage (foreground) title="$title" body="$body" data=${msg.data}',
    );
    if (title != '(no-title)' && body.isNotEmpty) {
      await _showLocalNotification(title: title, body: body, data: msg.data);
    }
  }

  /// 앱 언어 변경 시 푸시 토큰 재등록
  /// 서버에 저장된 device_locale을 최신 앱 언어로 업데이트
  static Future<void> refreshTokenWithLanguage() async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        logger.i('Refreshing push token with updated app language');
        await registerToken(token);
      }
    } catch (e, s) {
      logger.e(
        'Failed to refresh token with language',
        error: e,
        stackTrace: s,
      );
    }
  }

  static Future<void> registerToken(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      logger.w('registerToken skipped: no authenticated user');
      return;
    }
    await _registerToken(token, owner: _ownerGeneration, userId: userId);
  }

  static Future<void> _registerToken(
    String token, {
    required int owner,
    required String userId,
  }) async {
    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
        ? 'android'
        : Platform.isMacOS
        ? 'macos'
        : Platform.isWindows
        ? 'windows'
        : 'web';
    final appLanguage = _getAppLanguage();
    try {
      final user = supabase.auth.currentUser;
      if (user == null ||
          user.id != userId ||
          !_isRegistrationOwnerActive(owner, userId)) {
        return;
      }

      final uriPreview =
          '${Environment.supabaseUrl}/functions/v1/register-push-token';
      final sw = Stopwatch()..start();
      logger.i(
        'Registering push token to Supabase Edge: POST $uriPreview (uid: ${user.id.substring(0, 6)}..., platform: $platform, language: $appLanguage)',
      );

      // 최신 세션 토큰 확보 (v2 API 호환)
      var accessToken = supabase.auth.currentSession?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        final refreshed = await supabase.auth.refreshSession().timeout(
          const Duration(seconds: 12),
        );
        if (!_isRegistrationOwnerActive(owner, userId)) return;
        accessToken = refreshed.session?.accessToken ?? accessToken;
      }
      if (accessToken == null || accessToken.isEmpty) {
        logger.e(
          'registerToken aborted: accessToken missing (user exists but session not ready)',
        );
        return;
      }

      if (!_isRegistrationOwnerActive(owner, userId)) return;
      final res = await _invokeRegistration(
        accessToken: accessToken,
        platform: platform,
        token: token,
        appLanguage: appLanguage,
      );
      if (!_isRegistrationOwnerActive(owner, userId)) return;
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
        if (!_isRegistrationOwnerActive(owner, userId)) return;
        final refreshed = await supabase.auth.refreshSession().timeout(
          const Duration(seconds: 12),
        );
        if (!_isRegistrationOwnerActive(owner, userId)) return;
        final retryToken =
            refreshed.session?.accessToken ??
            supabase.auth.currentSession?.accessToken;
        if (retryToken != null && retryToken.isNotEmpty) {
          final res = await _invokeRegistration(
            accessToken: retryToken,
            platform: platform,
            token: token,
            appLanguage: appLanguage,
          );
          if (!_isRegistrationOwnerActive(owner, userId)) return;
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
          if (!_isRegistrationOwnerActive(owner, userId)) return;
          final refreshed = await supabase.auth.refreshSession().timeout(
            const Duration(seconds: 12),
          );
          if (!_isRegistrationOwnerActive(owner, userId)) return;
          final retryToken = refreshed.session?.accessToken;
          if (retryToken != null && retryToken.isNotEmpty) {
            final res = await _invokeRegistration(
              accessToken: retryToken,
              platform: platform,
              token: token,
              appLanguage: appLanguage,
            );
            if (!_isRegistrationOwnerActive(owner, userId)) return;
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

  static bool _isRegistrationOwnerActive(int owner, String userId) =>
      owner == _ownerGeneration && supabase.auth.currentUser?.id == userId;

  @visibleForTesting
  static int get debugOwnerGeneration => _ownerGeneration;

  @visibleForTesting
  static bool debugIsRegistrationOwnerActive(int owner, String userId) =>
      _isRegistrationOwnerActive(owner, userId);

  static Future<FunctionResponse> _invokeRegistration({
    required String accessToken,
    required String platform,
    required String token,
    required String appLanguage,
  }) async {
    final client = SupabaseClient(
      Environment.supabaseUrl,
      Environment.supabaseAnonKey,
    );
    try {
      return await client.functions
          .invoke(
            'register-push-token',
            headers: {'Authorization': 'Bearer $accessToken'},
            body: {
              'platform': platform,
              'token': token,
              'device_locale': appLanguage,
            },
          )
          .timeout(const Duration(seconds: 12));
    } finally {
      await client.dispose();
    }
  }

  static Future<String?> _awaitAPNSToken({
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 250),
    Future<String?> Function()? getToken,
  }) async {
    try {
      if (_apnsWaited) return null;
      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        final remaining = timeout - sw.elapsed;
        if (remaining <= Duration.zero) break;
        final token = await (getToken ?? _messaging.getAPNSToken)().timeout(
          remaining,
        );
        if (token != null && token.isNotEmpty) {
          _apnsWaited = true;
          return token;
        }
        final delay = pollInterval < remaining ? pollInterval : remaining;
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      }
    } catch (_) {}
    return null;
  }

  static bool get _supportsBroadcastTopics =>
      Platform.isIOS || Platform.isAndroid;

  @visibleForTesting
  static bool get debugSupportsBroadcastTopics => _supportsBroadcastTopics;

  @visibleForTesting
  static void debugUseCoordinatorFactory(
    PushTokenInitializationCoordinator Function() factory,
  ) {
    assert(_coordinator == null);
    _debugCoordinatorFactory = factory;
  }

  @visibleForTesting
  static Future<String?> debugWaitForApnsToken({
    required Future<String?> Function() getToken,
    required Duration timeout,
    Duration pollInterval = Duration.zero,
  }) => _awaitAPNSToken(
    timeout: timeout,
    pollInterval: pollInterval,
    getToken: getToken,
  );

  @visibleForTesting
  static Future<void> debugResetForTest() async {
    await dispose();
    _debugCoordinatorFactory = null;
    _apnsWaited = false;
    _notificationsInitialized = false;
  }

  /// 로컬 알림 초기화
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
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

  /// 앱 언어 설정 가져오기
  /// LocaleService에서 현재 설정된 앱 언어를 반환
  /// fallback: 디바이스 로케일 -> 'en'
  static String _getAppLanguage() {
    try {
      // 1. LocaleService에서 앱 언어 가져오기
      final appLanguage = LocaleService.instance.currentLanguageCode;
      if (appLanguage.isNotEmpty) {
        // zh-TW 처리 (번체 중국어)
        if (appLanguage == 'zh-TW' || appLanguage == 'zh_TW') {
          return 'zh-TW';
        }
        return appLanguage.toLowerCase();
      }

      // 2. Fallback: 디바이스 로케일
      final localeName = Platform.localeName;
      if (localeName.isEmpty) return 'en';

      final lowerName = localeName.toLowerCase();
      if (lowerName.startsWith('zh_tw') ||
          lowerName.startsWith('zh-tw') ||
          lowerName.startsWith('zh_hk') ||
          lowerName.startsWith('zh-hk') ||
          lowerName.contains('hant')) {
        return 'zh-TW';
      }

      final parts = localeName.split(RegExp(r'[_-]'));
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].toLowerCase();
      }

      return 'en';
    } catch (e) {
      logger.w('Failed to get app language: $e');
      return 'en';
    }
  }
}
