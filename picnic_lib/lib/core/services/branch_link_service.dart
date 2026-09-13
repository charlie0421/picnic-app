import 'dart:async';
import 'dart:collection';

import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:picnic_lib/core/utils/logger.dart';

typedef BranchDestinationHandler = Future<void> Function(String url);

class BranchLinkService {
  BranchLinkService({
    required Stream<Map<dynamic, dynamic>> Function() sessionEvents,
  }) : _sessionEvents = sessionEvents;

  static final BranchLinkService instance = BranchLinkService(
    sessionEvents: FlutterBranchSdk.listSession,
  );

  final Stream<Map<dynamic, dynamic>> Function() _sessionEvents;
  final LinkedHashSet<String> _pending = LinkedHashSet<String>();
  final Set<String> _inFlight = <String>{};
  StreamSubscription<Map<dynamic, dynamic>>? _subscription;
  BranchDestinationHandler? _handler;
  bool _handlerReady = false;
  bool _acceptEvents = true;
  bool _draining = false;
  bool _disposed = false;
  int _handlerGeneration = 0;

  bool get isHandlerReady => _handlerReady && _handler != null;

  Future<void> start() async {
    if (_disposed || _subscription != null) return;
    try {
      _subscription = _sessionEvents().listen(
        _onSession,
        onError: (Object error, StackTrace stackTrace) {
          logger.e(
            'Branch session stream error',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      logger.e(
        'Branch session listener start failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  int attachHandler(BranchDestinationHandler handler) {
    if (_disposed) return -1;
    final owner = ++_handlerGeneration;
    _handler = handler;
    _handlerReady = false;
    _acceptEvents = true;
    _drain();
    return owner;
  }

  void setHandlerReady(int owner, bool ready) {
    if (_disposed || owner != _handlerGeneration || _handlerReady == ready) {
      return;
    }
    _handlerReady = ready;
    if (ready) _drain();
  }

  void detachHandler(int owner) {
    if (_disposed || owner != _handlerGeneration) return;
    _handlerGeneration++;
    _handler = null;
    _handlerReady = false;
    _acceptEvents = false;
    _pending.clear();
    _inFlight.clear();
  }

  void _onSession(Map<dynamic, dynamic> data) {
    if (_disposed || !_acceptEvents || data['+clicked_branch_link'] != true) {
      return;
    }
    final destination = data[r'$desktop_url'];
    if (destination is! String || destination.trim().isEmpty) return;
    final url = destination.trim();
    if (_pending.contains(url) || _inFlight.contains(url)) return;
    _pending.add(url);
    _drain();
  }

  void _drain() {
    if (_disposed ||
        _draining ||
        !_handlerReady ||
        _handler == null ||
        _pending.isEmpty) {
      return;
    }
    _draining = true;
    final generation = _handlerGeneration;
    unawaited(() async {
      try {
        while (!_disposed &&
            generation == _handlerGeneration &&
            _handlerReady &&
            _handler != null &&
            _pending.isNotEmpty) {
          final url = _pending.first;
          _pending.remove(url);
          _inFlight.add(url);
          try {
            await _handler!(url);
          } catch (error, stackTrace) {
            logger.e(
              'Branch destination handling failed',
              error: error,
              stackTrace: stackTrace,
            );
          } finally {
            _inFlight.remove(url);
          }
        }
      } finally {
        _draining = false;
        // The old handler may finish after detach/reattach. Always offer the
        // queue to the current generation; _drain performs all current-owner
        // readiness checks and cannot resurrect the stale handler.
        _drain();
      }
    }());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _handlerGeneration++;
    _handler = null;
    _pending.clear();
    _inFlight.clear();
    await _subscription?.cancel();
    _subscription = null;
  }
}
