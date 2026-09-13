import 'dart:async';

enum PushPermissionStatus { granted, denied }

class PushInitializationDependencies {
  const PushInitializationDependencies({
    required this.initializeLocalNotifications,
    required this.requestPermission,
    required this.checkPermission,
    required this.getToken,
    required this.subscribeToBroadcastTopic,
    required this.registerToken,
    required this.tokenRefreshes,
    required this.foregroundMessages,
    required this.openedMessages,
    required this.authChanges,
    required this.isSignedIn,
    required this.isSignedInEvent,
    required this.onForegroundMessage,
    required this.onOpenedMessage,
    required this.getInitialMessage,
    this.onError,
  });

  final Future<void> Function() initializeLocalNotifications;
  final Future<PushPermissionStatus> Function() requestPermission;
  final Future<PushPermissionStatus> Function() checkPermission;
  final Future<String?> Function() getToken;
  final Future<void> Function() subscribeToBroadcastTopic;
  final Future<void> Function(String token) registerToken;
  final Stream<String> tokenRefreshes;
  final Stream<Object> foregroundMessages;
  final Stream<Object> openedMessages;
  final Stream<Object> authChanges;
  final bool Function() isSignedIn;
  final bool Function(Object event) isSignedInEvent;
  final FutureOr<void> Function(Object message) onForegroundMessage;
  final FutureOr<void> Function(Object message) onOpenedMessage;
  final Future<Object?> Function() getInitialMessage;
  final void Function(Object error, StackTrace stackTrace)? onError;
}

/// Owns one generation of push subscriptions and permission/token setup.
///
/// Message/tap/token/auth streams are installed before any user-controlled
/// permission future is awaited. Every async continuation checks the owner
/// generation so disposal cannot revive work or call into a dead widget tree.
class PushTokenInitializationCoordinator {
  PushTokenInitializationCoordinator(this._dependencies);

  final PushInitializationDependencies _dependencies;
  final List<StreamSubscription<Object>> _subscriptions = [];
  Future<void>? _inFlight;
  bool _subscriptionsInstalled = false;
  bool _disposed = false;
  int _generation = 0;
  String? _latestToken;

  Future<void> initialize() {
    if (_disposed) return Future<void>.value();
    _installSubscriptions();
    final current = _inFlight;
    if (current != null) return current;
    return _startAttempt(requestPermission: true);
  }

  Future<void> resume() {
    if (_disposed) return Future<void>.value();
    _installSubscriptions();
    final current = _inFlight;
    if (current != null) return current;
    return _startAttempt(requestPermission: false);
  }

  Future<void> _startAttempt({required bool requestPermission}) {
    final owner = _generation;
    late final Future<void> attempt;
    attempt = () async {
      try {
        await _bestEffort(_dependencies.initializeLocalNotifications);
        if (!_isActive(owner)) return;

        final status = await (requestPermission
            ? _dependencies.requestPermission()
            : _dependencies.checkPermission());
        if (!_isActive(owner)) return;

        if (status == PushPermissionStatus.granted) {
          await _refreshToken(owner);
        }
        if (!_isActive(owner)) return;
        await _bestEffort(_dependencies.subscribeToBroadcastTopic);
      } catch (error, stackTrace) {
        _report(error, stackTrace);
      } finally {
        if (identical(_inFlight, attempt)) _inFlight = null;
      }
    }();
    _inFlight = attempt;
    return attempt;
  }

  void _installSubscriptions() {
    if (_subscriptionsInstalled || _disposed) return;
    _subscriptionsInstalled = true;
    final owner = _generation;

    _subscriptions.add(
      _dependencies.tokenRefreshes.listen((token) {
        if (!_isActive(owner)) return;
        _latestToken = token;
        if (_dependencies.isSignedIn()) {
          unawaited(_registerIfActive(owner, token));
        }
      }, onError: (Object error, StackTrace stack) => _report(error, stack)),
    );
    _subscriptions.add(
      _dependencies.foregroundMessages.listen((message) {
        if (_isActive(owner)) {
          unawaited(
            Future<void>.sync(() => _dependencies.onForegroundMessage(message)),
          );
        }
      }, onError: (Object error, StackTrace stack) => _report(error, stack)),
    );
    _subscriptions.add(
      _dependencies.openedMessages.listen((message) {
        if (_isActive(owner)) {
          unawaited(
            Future<void>.sync(() => _dependencies.onOpenedMessage(message)),
          );
        }
      }, onError: (Object error, StackTrace stack) => _report(error, stack)),
    );
    _subscriptions.add(
      _dependencies.authChanges.listen((event) {
        final token = _latestToken;
        if (_isActive(owner) &&
            token != null &&
            _dependencies.isSignedInEvent(event)) {
          unawaited(_registerIfActive(owner, token));
        }
      }, onError: (Object error, StackTrace stack) => _report(error, stack)),
    );

    unawaited(() async {
      try {
        final initial = await _dependencies.getInitialMessage();
        if (initial != null && _isActive(owner)) {
          await _dependencies.onOpenedMessage(initial);
        }
      } catch (error, stackTrace) {
        _report(error, stackTrace);
      }
    }());
  }

  Future<void> _refreshToken(int owner) async {
    try {
      final token = await _dependencies.getToken();
      if (!_isActive(owner) || token == null || token.isEmpty) return;
      _latestToken = token;
      if (_dependencies.isSignedIn()) await _registerIfActive(owner, token);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  Future<void> _registerIfActive(int owner, String token) async {
    if (!_isActive(owner)) return;
    try {
      await _dependencies.registerToken(token);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  Future<void> _bestEffort(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  bool _isActive(int owner) => !_disposed && owner == _generation;

  void _report(Object error, StackTrace stackTrace) {
    if (!_disposed) _dependencies.onError?.call(error, stackTrace);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    final subscriptions = List<StreamSubscription<Object>>.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  }
}
