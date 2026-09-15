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

/// 네이티브 `setUserID` 한 건의 소유권.
///
/// [terminal] 은 **SDK 의 terminal 이벤트로만** 끝난다. 호출자의 timeout 과
/// 무관하게 살아 있어야 앞선 시도의 늦은 이벤트를 새 시도가 가로채지 않는다.
class TapjoyUserIdAttempt {
  TapjoyUserIdAttempt(
    this.userId, {
    required this.dispatch,
    required this.terminal,
  });

  final String userId;

  /// MethodChannel 호출의 결과. 이게 실패해도 리스너는 이미 등록돼 있어
  /// (tapjoy.dart:81-84) 네이티브 terminal 이벤트가 뒤늦게 올 수 있다.
  final Future<void> dispatch;

  /// SDK terminal 이벤트로만 끝난다.
  final Future<void> terminal;
}

/// `Tapjoy.setUserID` 를 보내고 그 시도의 소유권을 돌려주는 자리.
///
/// **동기**다. 채널 응답을 기다리지 않아야 응답이 오지 않는 단말에서 직렬화
/// 큐가 무기한 멈추지 않는다.
typedef TapjoyUserIdSetter = TapjoyUserIdAttempt Function(String userId);

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

/// `Tapjoy.setUserID` 를 보내고 그 시도의 소유권을 돌려준다.
///
/// tapjoy_offerwall 14.6.0 의 Android 플러그인은 `setUserID` 요청 직후
/// `result.success(null)` 을 돌려주고(TapjoyOfferwallPlugin.kt:170), 실제
/// 성공/실패는 `TapjoyOnSetUserIDSuccess` / `TapjoyOnSetUserIDFailure` 채널
/// 이벤트로 나중에 보낸다(:160). 따라서 `await Tapjoy.setUserID(...)` 만으로는
/// ID 가 SDK 에 반영됐다고 볼 수 없다 (PICNIC-2682).
///
/// **timeout 을 여기서 걸지 않는다.** 리스너는 `TapjoyMethodCallHandler` 의
/// static 단일 슬롯이라(:102-110) 호출자가 기다리기를 포기해도 네이티브 이벤트는
/// 여전히 이 시도의 것이다. 그 소유권은 [TapjoySession] 이 관리한다.
TapjoyUserIdAttempt sendTapjoyUserId(String userId) {
  final completer = Completer<void>();

  // `Tapjoy.setUserID` 는 리스너를 등록한 **뒤** invokeMethod 한다
  // (tapjoy.dart:81-84). 채널 호출을 await 하지 않고 시작만 시켜, 응답이
  // 실패하거나 오지 않아도 이 시도의 소유권을 잃지 않는다.
  final dispatch = Tapjoy.setUserID(
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

  return TapjoyUserIdAttempt(
    userId,
    dispatch: dispatch,
    terminal: completer.future,
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
    this.reconnectCooldown = const Duration(seconds: 30),
    this.probeTimeout = const Duration(seconds: 5),
  }) : _sendUserId = setUserIdAndWait ?? sendTapjoyUserId,
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

  final TapjoyUserIdSetter _sendUserId;
  final TapjoyUserIdReader _currentUserId;
  final TapjoyConnector _connect;
  final TapjoyNativeUserIdProbe _nativeUserId;
  final TapjoyConnectedProbe _nativeConnected;
  final Duration userIdTimeout;
  final Duration connectTimeout;
  final Duration reconnectCooldown;

  /// 네이티브 상태 조회(`isConnected`/`getUserID`)의 상한. 채널 응답이 오지
  /// 않으면 connectTimeout·userIdTimeout 밖에서 기다려 전역 직렬화 큐가 영구
  /// pending 이 된다 (blocker-3).
  final Duration probeTimeout;

  /// connect 성공 이벤트로만 완료된다. 실패/채널 예외는 오류로 완료한다.
  Completer<void>? _connectReady;

  /// SDK 에 설정이 **확인된** 사용자 UUID.
  String? _readyUserId;

  /// 전역 단일 슬롯 리스너를 동시에 덮어쓰지 않게 하는 직렬화 큐.
  /// 첫 호출은 큐가 비어 있으므로 동기적으로 잠그고 바로 시작한다.
  Future<void>? _queue;

  /// connect 성공 이벤트 대기는 waiter 마다 timeout 을 새로 시작하지 않는다.
  Future<void>? _connectWait;

  /// 실제 connect 실패 뒤 재연결에 쓸 마지막 인자. MethodChannel 은 즉시
  /// 반환하므로 startup stage 는 성공으로 캐시되고, 뒤늦게 오는 진짜
  /// CONNECT_FAILED 는 앱에 재호출 경로가 없으면 프로세스 재시작 전까지
  /// Tapjoy 를 전면 차단한다 (major-D).
  String? _sdkKey;
  Future<void> Function()? _onConnectedHook;

  /// connect 가 확정된 뒤 정확히 한 번 실행되는 hook. 채널 성공 이벤트든
  /// `isConnected()` fallback 이든 같은 경로를 탄다 (major-C).
  Future<void>? _connectedHookRun;

  /// 진행 중인 단일 재연결. 연타가 SDK 를 두들기지 않게 공유한다.
  Future<void>? _reconnect;
  Timer? _reconnectCooldown;

  /// timeout 으로 Dart Future 는 끝냈지만 네이티브 terminal 이벤트를 아직
  /// 소비하지 못한 setUserID 시도.
  ///
  /// blocker-A: 이게 살아 있는 동안 새 `setUserID` 를 보내면 SDK 의 static 단일
  /// 슬롯 리스너를 덮어써, 앞선 시도의 늦은 이벤트가 새 시도의 Completer 를
  /// 완료시킨다. Android SDK 14.6.0 은 HTTP 검증 **이전에** 로컬
  /// `TJUser.setUserId` 를 실행하므로 `getUserID()` 대조로도 구별되지 않는다.
  /// 그래서 소유권이 정리될 때까지 fail-closed 로 막는다.
  TapjoyUserIdAttempt? _orphanedAttempt;

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
    _sdkKey = sdkKey;
    _onConnectedHook = onConnected;
    // 새 네이티브 연결은 privacy 설정을 다시 적용해야 한다.
    _connectedHookRun = null;

    final options = <String, dynamic>{
      if (initialUserId != null && initialUserId.isNotEmpty)
        TapjoyConnectFlags.user_id: initialUserId,
    };

    try {
      await _connect(
        sdkKey: sdkKey,
        options: options,
        onConnectSuccess: () => _markConnected(completer),
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

  /// 로그아웃·계정 전환 때마다 증가하는 단조 세대 번호.
  ///
  /// 오퍼월 시도가 이 값을 캡처해 두면, 계정이 A→B→A 로 되돌아와도 앞선 시도의
  /// 늦은 콜백을 문자열 일치만으로 되살리지 않는다 (blocker-2).
  ///
  /// **static 인 이유**: SDK 도 Auth 도 프로세스에 하나뿐이고, 세대가 뒤로
  /// 가는 순간 앞선 시도가 캡처한 값과 다시 같아져 가드가 무력화된다. 세션
  /// 인스턴스가 교체돼도 단조성을 잃지 않아야 한다.
  int get authGeneration => _authGeneration;
  static int _authGeneration = 0;

  /// 로그아웃·계정 전환·dispose 로 SDK 사용자 상태를 더는 신뢰할 수 없을 때.
  void invalidateUser() {
    _readyUserId = null;
    _authGeneration++;
  }

  /// 네이티브 SDK 가 지금 [userId] 를 들고 있는가. 확인 실패는 던진다.
  Future<bool> nativeUserIdMatches(String userId) =>
      _nativeUserIdMatches(userId);

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
    await _sendUserIdOwned(userId);

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

  /// `setUserID` 를 보내고 terminal 이벤트를 기다린다.
  ///
  /// timeout 은 Dart Future 만 끝내고 네이티브 소유권은 [_orphanedAttempt] 로
  /// 유지한다. 소유권이 살아 있는 동안은 새 요청을 보내지 않는다 — 보내는 순간
  /// static 단일 슬롯 리스너가 덮어써져 늦은 이벤트의 주인을 알 수 없게 된다.
  Future<void> _sendUserIdOwned(String userId) async {
    final orphan = _orphanedAttempt;
    if (orphan != null) {
      throw TapjoySessionException('SET_USER_ID_QUARANTINED', orphan.userId);
    }

    final attempt = _sendUserId(userId);
    try {
      await _awaitUserIdAttempt(attempt);
    } on TapjoySessionException catch (error) {
      // terminal 이벤트를 소비하지 못한 채 호출자 대기만 끝난 경우는 모두
      // 격리한다. 채널이 실패했어도 리스너는 살아 있어 늦은 이벤트가 온다.
      if (error.reason == 'SET_USER_ID_TIMEOUT' ||
          error.reason == 'SET_USER_ID_CHANNEL_ERROR') {
        _quarantine(attempt);
      }
      rethrow;
    } catch (error) {
      throw TapjoySessionException('SET_USER_ID_FAILED', error);
    }
  }

  /// terminal 이벤트를 기다리되, 채널 실패와 timeout 으로 대기를 끝낸다.
  /// 어느 쪽이든 [TapjoyUserIdAttempt.terminal] 은 살아 있어 소유권은 유지된다.
  Future<void> _awaitUserIdAttempt(TapjoyUserIdAttempt attempt) {
    final settled = Completer<void>();

    attempt.terminal.then<void>(
      (_) {
        if (!settled.isCompleted) settled.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!settled.isCompleted) settled.completeError(error, stackTrace);
      },
    );

    // 채널 호출 자체가 실패하면 더 기다릴 근거가 없다. 다만 terminal 이벤트가
    // 올 가능성은 남으므로 소유권은 호출자가 격리로 유지한다.
    attempt.dispatch.then<void>(
      (_) {},
      onError: (Object error) {
        if (!settled.isCompleted) {
          settled.completeError(
            TapjoySessionException('SET_USER_ID_CHANNEL_ERROR', error),
          );
        }
      },
    );

    return settled.future.timeout(
      userIdTimeout,
      onTimeout: () => throw TapjoySessionException(
        'SET_USER_ID_TIMEOUT',
        '${userIdTimeout.inMilliseconds}ms',
      ),
    );
  }

  /// 네이티브 terminal 이벤트를 아직 못 받은 시도를 격리한다.
  void _quarantine(TapjoyUserIdAttempt attempt) {
    _orphanedAttempt = attempt;
    logger.w('[Tapjoy] setUserID terminal 이벤트 대기 중 — 새 요청을 보류한다');
    attempt.terminal.then<void>((_) {}, onError: (Object _) {}).whenComplete(
      () {
        if (identical(_orphanedAttempt, attempt)) {
          _orphanedAttempt = null;
          logger.i('[Tapjoy] setUserID 소유권 정리 완료 — 보류 해제');
        }
      },
    );
  }

  /// 네이티브 SDK 가 [userId] 를 들고 있는가. 확인 자체가 실패하면 던진다.
  Future<bool> _nativeUserIdMatches(String userId) async {
    try {
      final native = await _nativeUserId().timeout(
        probeTimeout,
        onTimeout: () => throw TapjoySessionException(
          'USER_ID_PROBE_TIMEOUT',
          '${probeTimeout.inMilliseconds}ms',
        ),
      );
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
      // 응답이 오지 않는 probe 를 무한정 기다리면 큐 전체가 멈춘다.
      return await _nativeConnected().timeout(
        probeTimeout,
        onTimeout: () => false,
      );
    } catch (error) {
      logger.w('[Tapjoy] isConnected probe failed: $error');
      return false;
    }
  }

  Future<void> _awaitConnected({bool allowReconnect = true}) async {
    final completer = _connectReady;
    if (completer == null) {
      throw const TapjoySessionException('CONNECT_NOT_STARTED');
    }
    if (completer.isCompleted) {
      try {
        await completer.future;
        // 확정된 연결이라도 hook 이 아직이면(이벤트 유실 후 fallback) 실행한다.
        await _runConnectedHook();
        return;
      } on TapjoySessionException catch (error) {
        if (!allowReconnect || !_isRecoverableConnectFailure(error)) rethrow;
        // 네트워크가 정상화돼도 앱에 재호출 경로가 없으면 프로세스 재시작
        // 전까지 Tapjoy 가 막힌다 (major-D).
        await _attemptReconnect();
        return;
      }
    }

    // connect 성공 채널 이벤트가 유실되면 completer 는 영구 pending 이다. SDK 가
    // 실제로 연결돼 있으면 정상 사용자를 앱 재시작 전까지 막을 이유가 없다.
    if (await _probeConnected()) {
      _markConnected(completer);
      await _runConnectedHook();
      return;
    }

    // 대기는 공유한다. waiter 마다 timeout 을 새로 시작하면 탭마다 15초씩 멈춘다.
    await (_connectWait ??= _waitForConnectEvent(completer));
    await _runConnectedHook();
  }

  static bool _isRecoverableConnectFailure(TapjoySessionException error) =>
      error.reason == 'CONNECT_FAILED' ||
      error.reason == 'CONNECT_CHANNEL_ERROR' ||
      // timeout 도 네트워크가 돌아오면 복구 가능한 상태다. 영구 캐시하면
      // 프로세스 재시작 전까지 Tapjoy 를 못 쓴다 (major-G).
      error.reason == 'CONNECT_TIMEOUT';

  /// 실제 connect 실패 뒤 사용자 시도 한 건당 최대 한 번, 공유 재연결.
  ///
  /// 쿨다운 거절은 [_runReconnect] 밖에서 끝낸다. 거절까지 catch 안에 두면
  /// 탭마다 Timer 가 새로 시작돼 연타하는 사용자는 무기한 재연결이 막힌다.
  Future<void> _attemptReconnect() {
    if (_reconnectCooldown?.isActive ?? false) {
      return Future<void>.error(
        const TapjoySessionException('CONNECT_FAILED_COOLDOWN'),
      );
    }
    return _reconnect ??= _runReconnect();
  }

  Future<void> _runReconnect() async {
    try {
      final sdkKey = _sdkKey;
      if (sdkKey == null) {
        throw const TapjoySessionException('CONNECT_NOT_STARTED');
      }
      logger.i('[Tapjoy] reconnecting after a failed connect');
      await connect(
        sdkKey: sdkKey,
        initialUserId: _currentUserId(),
        onConnected: _onConnectedHook,
      );
      await _awaitConnected(allowReconnect: false);
    } catch (error) {
      // 실제로 connect 를 보낸 재연결이 실패했을 때만 쿨다운을 시작한다.
      _reconnectCooldown?.cancel();
      _reconnectCooldown = Timer(reconnectCooldown, () {});
      rethrow;
    } finally {
      _reconnect = null;
    }
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
    } on TapjoySessionException catch (error) {
      // timeout 직전에 연결이 끝났을 수 있다 — 네이티브에 마지막으로 한 번 더 묻는다.
      if (await _probeConnected()) {
        _markConnected(completer);
        return;
      }
      // timeout 을 completer 의 명시적 terminal 상태로 소유한다. pending 인 채로
      // 두면 다음 시도가 _connectWait 의 캐시된 오류만 되읽어 재연결 분기를
      // 영영 타지 못한다 (major-G).
      if (!completer.isCompleted) completer.completeError(error);
      rethrow;
    }
  }

  void _markConnected(Completer<void> completer) {
    if (!completer.isCompleted) completer.complete();
    _runConnectedHook();
  }

  /// 앱 안에서 Tapjoy GDPR·user consent·age·US privacy 를 설정하는 유일한
  /// 지점이다(app_initializer.dart 의 `_onTapjoyConnectSuccess`). 채널 성공
  /// 이벤트가 유실돼 `isConnected()` fallback 으로 확정된 경우에도 반드시
  /// 실행돼야 한다 (major-C).
  Future<void> _runConnectedHook() {
    final hook = _onConnectedHook;
    if (hook == null) return Future<void>.value();
    return _connectedHookRun ??= () async {
      try {
        await hook();
      } catch (error, stackTrace) {
        logger.e(
          '[Tapjoy] connected hook failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }();
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
