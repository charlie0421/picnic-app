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
    this.userIdTimeout = const Duration(seconds: 10),
    this.connectTimeout = const Duration(seconds: 15),
  }) : _setUserIdAndWait = setUserIdAndWait ?? setTapjoyUserIdAndWait,
       _currentUserId = currentUserId ?? _defaultCurrentUserId,
       _connect = connect ?? _defaultConnect;

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
  final Duration userIdTimeout;
  final Duration connectTimeout;

  /// connect 성공 이벤트로만 완료된다. 실패/채널 예외는 오류로 완료한다.
  Completer<void>? _connectReady;

  /// SDK 에 설정이 **확인된** 사용자 UUID.
  String? _readyUserId;

  /// 전역 단일 슬롯 리스너를 동시에 덮어쓰지 않게 하는 직렬화 큐.
  /// 첫 호출은 큐가 비어 있으므로 동기적으로 잠그고 바로 시작한다.
  Future<void>? _queue;

  /// SDK 사용자 ID 가 확인된 사용자. 확인 전이면 null.
  String? get readyUserId => _readyUserId;

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
    if (_readyUserId == userId) return userId;

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
    _readyUserId = userId;
    return userId;
  }

  Future<void> _awaitConnected() {
    final completer = _connectReady;
    if (completer == null) {
      return Future<void>.error(
        const TapjoySessionException('CONNECT_NOT_STARTED'),
      );
    }
    if (completer.isCompleted) return completer.future;
    return completer.future.timeout(
      connectTimeout,
      onTimeout: () => throw TapjoySessionException(
        'CONNECT_TIMEOUT',
        '${connectTimeout.inMilliseconds}ms',
      ),
    );
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
