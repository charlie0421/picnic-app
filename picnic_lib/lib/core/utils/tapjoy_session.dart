import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy SDK 가 오퍼월 요청을 보내도 안전한 상태임을 보장하지 못할 때 던진다.
///
/// PICNIC-2682: 이 예외를 삼키고 진행하면 SDK 가 아직 들고 있는 기본 기기 ID
/// (64자리 hex 로 관측됨)로 오퍼가 생성되고, Tapjoy 서버 콜백의 `snuid` 가
/// Picnic UUID 가 아니게 되어 보상이 영원히 지급되지 않는다.
class TapjoySessionException implements Exception {
  const TapjoySessionException(this.reason, [this.detail]);

  /// 로그/분류용 짧은 사유 코드.
  final String reason;
  final Object? detail;

  @override
  String toString() =>
      'TapjoySessionException($reason${detail == null ? '' : ': $detail'})';
}

/// `Tapjoy.setUserID` 를 호출하고 SDK 성공 이벤트까지 기다리는 자리.
typedef TapjoyUserIdSetter =
    Future<void> Function(String userId, {Duration timeout});

/// 현재 로그인 사용자의 UUID. 없으면 null.
typedef TapjoyUserIdReader = String? Function();

/// 네이티브 SDK 가 지금 들고 있는 사용자 ID. `Tapjoy.getUserID()` 자리.
typedef TapjoyNativeUserIdProbe = Future<String?> Function();

/// 네이티브 SDK 의 연결 여부. `Tapjoy.isConnected()` 자리.
typedef TapjoyConnectedProbe = Future<bool> Function();

/// `Tapjoy.connect` 호출 자리. MethodChannel 반환까지만 기다린다.
typedef TapjoyConnector =
    Future<void> Function({
      required String sdkKey,
      required Map<String, dynamic> options,
      required void Function() onConnectSuccess,
      required void Function(int code, String? message) onConnectFailure,
      required void Function(int code, String? message) onConnectWarning,
    });

/// Tapjoy 사용자 ID 를 설정하고 **SDK 의 성공 이벤트까지** 기다린다.
///
/// tapjoy_offerwall 14.6.0 의 Android 플러그인은 `setUserID` 요청 직후
/// `result.success(null)` 을 돌려주고(TapjoyOfferwallPlugin.kt:170), 실제
/// 성공/실패는 `TapjoyOnSetUserIDSuccess` / `TapjoyOnSetUserIDFailure` 채널
/// 이벤트로 나중에 보낸다(:160). 따라서 `await Tapjoy.setUserID(...)` 만으로는
/// ID 가 SDK 에 반영됐다고 볼 수 없고, 그 사이에 오퍼월을 요청하면 기본 기기
/// ID 로 오퍼가 만들어질 수 있다 (PICNIC-2682).
///
/// 실패·timeout·채널 예외는 모두 [TapjoySessionException] 으로 전파해 호출자가
/// 오퍼월 요청을 중단하게 한다.
Future<void> setTapjoyUserIdAndWait(
  String userId, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final completer = Completer<void>();

  try {
    await Tapjoy.setUserID(
      userId: userId,
      onSetUserIDSuccess: () {
        if (!completer.isCompleted) completer.complete();
      },
      onSetUserIDFailure: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            TapjoySessionException('SET_USER_ID_FAILED', error),
          );
        }
      },
    );
  } catch (error) {
    // 채널 호출 자체가 실패하면 성공 이벤트는 영영 오지 않는다.
    completer.future.ignore();
    throw TapjoySessionException('SET_USER_ID_CHANNEL_ERROR', error);
  }

  return completer.future.timeout(
    timeout,
    onTimeout: () => throw TapjoySessionException(
      'SET_USER_ID_TIMEOUT',
      '${timeout.inMilliseconds}ms',
    ),
  );
}

/// 늦게 도착한 SDK 콜백이 지난 시도의 화면을 열지 못하게 막는 토큰.
///
/// Tapjoy 의 placement 콜백은 전역 단일 슬롯에 등록되므로, 앞선 시도가 실패한
/// 뒤에 도착한 `onContentReady` 가 다음 시도의 화면을 여는 일을 막아야 한다.
class TapjoyAttemptGuard {
  int _token = 0;

  /// 새 시도를 시작하고 그 토큰을 돌려준다.
  int begin() => ++_token;

  /// [token] 이 아직 현재 시도인가.
  bool isCurrent(int token) => token == _token;

  /// dispose·로그아웃·계정 전환 — 진행 중인 모든 시도를 무효화한다.
  void cancel() => _token++;
}

/// 같은 이름의 placement 를 동시에 두 번 잡지 못하게 하는 앱 전역 gate.
///
/// tapjoy_offerwall 14.6.0 의 [TJPlacement] 는 placement **이름 하나**로 객체를
/// 캐시하고(`_placementMap`), `getPlacement` 가 불릴 때마다 그 객체의 콜백을
/// 통째로 덮어쓴다(models/tapjoy_placement.dart:33-41). `requestContent` 의
/// MethodChannel 반환은 즉시라 두 번째 탭이 곧바로 같은 placement 를 가져갈 수
/// 있고, 그러면 첫 요청의 늦은 `onContentReady` 도 최신 콜백으로 라우팅된다.
/// 시도 토큰은 같은 인스턴스의 지난 시도만 구별할 뿐 이 덮어쓰기를 막지 못한다.
///
/// 활성 수명은 `getPlacement` 부터 request failure 또는 content dismiss 까지다.
class TapjoyPlacementGate {
  TapjoyPlacementGate._();

  static final Map<String, Object> _active = <String, Object>{};

  /// [owner] 가 [placementName] 을 잡는다. 이미 누가 잡고 있으면 false.
  static bool tryEnter(String placementName, Object owner) {
    if (_active.containsKey(placementName)) return false;
    _active[placementName] = owner;
    return true;
  }

  /// [owner] 가 잡고 있을 때만 놓는다. 남의 gate 는 건드리지 않는다.
  static void exit(String placementName, Object owner) {
    if (identical(_active[placementName], owner)) {
      _active.remove(placementName);
    }
  }

  static bool isActive(String placementName) =>
      _active.containsKey(placementName);

  @visibleForTesting
  static void resetForTest() => _active.clear();
}

/// Tapjoy connect 준비 상태와 사용자 ID 동기화를 앱 전체가 공유하는 단일 세션.
///
/// 앱 시작에서 Auth 와 Tapjoy connect 는 병렬로 시작하므로
/// (main_initializer.dart 의 non-auth 그룹) 어느 쪽이 먼저 끝날지 보장이 없다.
/// 이 세션이 그 순서를 흡수한다:
///
/// * 이미 로그인 상태면 connect 옵션(`TJC_OPTION_USER_ID`)으로 UUID 를 넘긴다.
/// * Auth 가 늦으면 connect 성공 뒤 `setUserID` 를 보내고 성공 이벤트를 기다린다.
/// * 오퍼월 요청 직전에 현재 Auth 사용자와 다시 대조한다.
class TapjoySession {
  TapjoySession({
    TapjoyUserIdSetter? setUserIdAndWait,
    TapjoyUserIdReader? currentUserId,
    TapjoyConnector? connect,
    TapjoyNativeUserIdProbe? nativeUserId,
    TapjoyConnectedProbe? nativeConnected,
    this.userIdTimeout = const Duration(seconds: 10),
    this.connectTimeout = const Duration(seconds: 15),
  }) : _setUserIdAndWait = setUserIdAndWait ?? setTapjoyUserIdAndWait,
       _currentUserId = currentUserId ?? _defaultCurrentUserId,
       _connect = connect ?? _defaultConnect,
       _nativeUserId = nativeUserId ?? Tapjoy.getUserID,
       _nativeConnected = nativeConnected ?? Tapjoy.isConnected;

  static String? _defaultCurrentUserId() => supabase.auth.currentUser?.id;

  static Future<void> _defaultConnect({
    required String sdkKey,
    required Map<String, dynamic> options,
    required void Function() onConnectSuccess,
    required void Function(int code, String? message) onConnectFailure,
    required void Function(int code, String? message) onConnectWarning,
  }) => Tapjoy.connect(
    sdkKey: sdkKey,
    options: options,
    onConnectSuccess: () async => onConnectSuccess(),
    onConnectFailure: (code, message) async => onConnectFailure(code, message),
    onConnectWarning: (code, message) async => onConnectWarning(code, message),
  );

  /// 앱 전체가 공유하는 단일 세션. SDK 리스너가 전역 단일 슬롯이라 인스턴스를
  /// 여러 개 두면 서로 덮어쓴다.
  static TapjoySession instance = TapjoySession();

  @visibleForTesting
  static void setInstanceForTest(TapjoySession session) {
    instance = session;
  }

  final TapjoyUserIdSetter _setUserIdAndWait;
  final TapjoyUserIdReader _currentUserId;
  final TapjoyConnector _connect;
  final TapjoyNativeUserIdProbe _nativeUserId;
  final TapjoyConnectedProbe _nativeConnected;
  final Duration userIdTimeout;
  final Duration connectTimeout;

  /// connect 성공 이벤트로만 완료된다. 실패/채널 예외는 오류로 완료한다.
  Completer<void>? _connectReady;

  /// SDK 에 설정이 **확인된** 사용자 UUID.
  String? _readyUserId;

  /// 전역 단일 슬롯 리스너를 동시에 덮어쓰지 않게 하는 직렬화 큐.
  /// 첫 호출은 큐가 비어 있으므로 동기적으로 잠그고 바로 시작한다.
  Future<void>? _queue;

  /// connect 성공 이벤트 대기는 waiter 마다 timeout 을 새로 시작하지 않는다.
  Future<void>? _connectWait;

  /// SDK 사용자 ID 가 확인된 사용자. 확인 전이면 null.
  String? get readyUserId => _readyUserId;

  /// 현재 로그인 사용자의 UUID. 세션이 "현재 사용자"의 단일 소스이므로
  /// 오퍼월 콜백의 계정 재확인도 전역 supabase 대신 이 값을 쓴다.
  String? get currentUserId => _currentUserId();

  /// `Tapjoy.connect` 를 보낸다. MethodChannel 반환까지만 기다리므로 앱 시작이
  /// SDK 이벤트 때문에 막히지 않는다. 준비 완료는 [ensureUserReady] 가 기다린다.
  Future<void> connect({
    required String sdkKey,
    String? initialUserId,
    Future<void> Function()? onConnected,
  }) async {
    final completer = Completer<void>();
    // 리스너가 붙기 전에 실패해도 unhandled error 로 새지 않게 한다.
    completer.future.ignore();
    _connectReady = completer;
    // 재연결이면 앞선 연결의 공유 대기(실패했을 수도 있다)를 버린다.
    _connectWait = null;
    _readyUserId = null;

    final options = <String, dynamic>{
      if (initialUserId != null && initialUserId.isNotEmpty)
        TapjoyConnectFlags.user_id: initialUserId,
    };

    try {
      await _connect(
        sdkKey: sdkKey,
        options: options,
        onConnectSuccess: () {
          if (!completer.isCompleted) completer.complete();
          final hook = onConnected;
          if (hook != null) unawaited(hook());
        },
        onConnectFailure: (code, message) {
          logger.e('[Tapjoy] connect failed: $code, $message');
          _readyUserId = null;
          if (!completer.isCompleted) {
            completer.completeError(
              TapjoySessionException('CONNECT_FAILED', '$code: $message'),
            );
          }
        },
        onConnectWarning: (code, message) {
          logger.w('[Tapjoy] connect warning: $code, $message');
        },
      );
    } catch (error) {
      if (!completer.isCompleted) {
        completer.completeError(
          TapjoySessionException('CONNECT_CHANNEL_ERROR', error),
        );
      }
      rethrow;
    }
  }

  /// 로그아웃·계정 전환·dispose 로 SDK 사용자 상태를 더는 신뢰할 수 없을 때.
  void invalidateUser() {
    _readyUserId = null;
  }

  /// SDK 가 현재 로그인 사용자의 UUID 를 확인할 때까지 기다린다.
  ///
  /// connect 준비 → 로그인 확인 → `setUserID` 성공 이벤트 → 계정 재확인 순.
  Future<String> ensureUserReady() => _serialized(_ensureUserReadyNow);

  /// [body] 를 SDK 사용자 ID 가 확인된 상태에서만, 그리고 다른 오퍼월 시도와
  /// 겹치지 않게 실행한다.
  Future<T> runOfferwall<T>(Future<T> Function(String userId) body) =>
      _serialized(() async {
        final userId = await _ensureUserReadyNow();
        // 준비와 요청 사이에도 계정이 바뀔 수 있다.
        if (_currentUserId() != userId) {
          _readyUserId = null;
          throw const TapjoySessionException('ACCOUNT_CHANGED');
        }
        return body(userId);
      });

  Future<String> _ensureUserReadyNow() async {
    await _awaitConnected();

    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw const TapjoySessionException('NO_AUTHENTICATED_USER');
    }

    // Dart 캐시는 네이티브 상태의 사본일 뿐이다. reconnect·복귀 중 SDK 가 ID 를
    // 잃거나 기본 기기 ID 로 되돌아가면 캐시만 과거 UUID 로 남아 PICNIC-2682 의
    // 근본 원인 경로가 그대로 재발한다. 캐시 적중도 네이티브로 확인한다.
    if (_readyUserId == userId && await _nativeUserIdMatches(userId)) {
      return userId;
    }

    _readyUserId = null;
    try {
      await _setUserIdAndWait(userId, timeout: userIdTimeout);
    } on TapjoySessionException {
      rethrow;
    } catch (error) {
      throw TapjoySessionException('SET_USER_ID_FAILED', error);
    }

    // 성공 이벤트를 기다리는 사이 로그아웃·계정 전환이 일어났을 수 있다.
    if (_currentUserId() != userId) {
      throw const TapjoySessionException('ACCOUNT_CHANGED');
    }

    // SDK 의 setUserID 성공/실패 리스너는 static 단일 슬롯이라
    // (tapjoy_method_call_handler.dart:102-110) 이 시도가 timeout 된 앞선 시도의
    // 늦은 이벤트로 완료됐을 수 있다. 이벤트에는 주인을 식별할 값이 없으므로
    // 네이티브가 실제로 이 UUID 를 들고 있는지 직접 확인한다 (fail-closed).
    if (!await _nativeUserIdMatches(userId)) {
      throw const TapjoySessionException('USER_ID_MISMATCH');
    }
    _readyUserId = userId;
    return userId;
  }

  /// 네이티브 SDK 가 [userId] 를 들고 있는가. 확인 자체가 실패하면 던진다.
  Future<bool> _nativeUserIdMatches(String userId) async {
    try {
      final native = await _nativeUserId();
      if (native == null) return false;
      // UUID 는 hex 라 표기 차이만 흡수하면 된다. 기기 ID(64 hex)는 이래도 안 맞는다.
      return native.trim().toLowerCase() == userId.trim().toLowerCase();
    } catch (error) {
      // 확인할 수 없으면 진행하지 않는다 — 잘못된 snuid 로 오퍼를 여느니 실패한다.
      throw TapjoySessionException('USER_ID_PROBE_FAILED', error);
    }
  }

  Future<bool> _probeConnected() async {
    try {
      return await _nativeConnected();
    } catch (error) {
      logger.w('[Tapjoy] isConnected probe failed: $error');
      return false;
    }
  }

  Future<void> _awaitConnected() async {
    final completer = _connectReady;
    if (completer == null) {
      throw const TapjoySessionException('CONNECT_NOT_STARTED');
    }
    if (completer.isCompleted) {
      await completer.future;
      return;
    }

    // connect 성공 채널 이벤트가 유실되면 completer 는 영구 pending 이다. SDK 가
    // 실제로 연결돼 있으면 정상 사용자를 앱 재시작 전까지 막을 이유가 없다.
    if (await _probeConnected()) {
      _markConnected(completer);
      return;
    }

    // 대기는 공유한다. waiter 마다 timeout 을 새로 시작하면 탭마다 15초씩 멈춘다.
    await (_connectWait ??= _waitForConnectEvent(completer));
  }

  Future<void> _waitForConnectEvent(Completer<void> completer) async {
    try {
      await completer.future.timeout(
        connectTimeout,
        onTimeout: () => throw TapjoySessionException(
          'CONNECT_TIMEOUT',
          '${connectTimeout.inMilliseconds}ms',
        ),
      );
    } catch (_) {
      // timeout 직전에 연결이 끝났을 수 있다 — 네이티브에 마지막으로 한 번 더 묻는다.
      if (await _probeConnected()) {
        _markConnected(completer);
        return;
      }
      rethrow;
    }
  }

  void _markConnected(Completer<void> completer) {
    if (!completer.isCompleted) completer.complete();
  }

  Future<T> _serialized<T>(Future<T> Function() body) {
    final completer = Completer<T>();
    final previous = _queue;
    _queue = completer.future.then<void>((_) {}, onError: (Object _) {});
    if (previous == null) {
      unawaited(_runSerialized(completer, body));
    } else {
      previous.whenComplete(() => _runSerialized(completer, body));
    }
    return completer.future;
  }

  Future<void> _runSerialized<T>(
    Completer<T> completer,
    Future<T> Function() body,
  ) async {
    try {
      completer.complete(await body());
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }
}
