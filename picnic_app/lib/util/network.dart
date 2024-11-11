import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/logger.dart';

class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxAttempts;
  final Duration timeout;

  RetryHttpClient(
    this._inner, {
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        // Create a fresh copy of the request for each attempt
        final newRequest = await _copyRequest(request);
        return await _inner.send(newRequest).timeout(timeout);
      } on Exception catch (e) {
        lastException = e;
        if (e is SocketException ||
            e is TimeoutException ||
            e is http.ClientException) {
          logger.e('Attempt $attempts failed: $e');
          if (attempts < maxAttempts) {
            // Add exponential backoff
            await Future.delayed(
                Duration(milliseconds: 200 * attempts * attempts));
            continue;
          }
        }
        break;
      }
    }

    logger.e('All attempts failed. Last error: $lastException');
    return http.StreamedResponse(
      Stream.fromIterable([]),
      500,
      reasonPhrase: 'Network Error',
    );
  }

  Future<http.BaseRequest> _copyRequest(http.BaseRequest original) async {
    final copy = http.Request(original.method, original.url)
      ..encoding = (original as http.Request).encoding
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;

    if (original is http.Request) {
      (copy as http.Request).body = original.body;
    }

    return copy;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class NetworkCheck {
  static Future<bool> isOnline() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      logger.i('Connectivity result: $connectivityResult');
      return connectivityResult.isNotEmpty &&
          connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      logger.e('Error checking connectivity: $e');
      return false;
    }
  }
}

class NetworkStatusListener {
  final AuthService _authService;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _wasConnected = true;
  Timer? _periodicCheck;
  bool _isDisposed = false;

  NetworkStatusListener(this._authService) {
    _initConnectivity();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _startPeriodicCheck();
  }

  Future<void> _initConnectivity() async {
    if (_isDisposed) return;

    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e, s) {
      logger.e('Error checking initial connectivity: $e', stackTrace: s);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (_isDisposed) return;

    bool isConnected =
        result.isNotEmpty && result.first != ConnectivityResult.none;

    logger.i('Network connection status: $isConnected\n'
        'Previous connection status: $_wasConnected');

    if (isConnected && !_wasConnected) {
      logger.i('Network connection restored. Attempting token refresh.');
      try {
        await _authService.refreshToken();
      } catch (e) {
        logger.e('Failed to refresh token: $e');
      }
    } else if (!isConnected && _wasConnected) {
      logger.i('Network connection lost.');
    }

    _wasConnected = isConnected;
  }

  void _startPeriodicCheck() {
    if (_isDisposed) return;

    logger.i('Starting periodic network check');
    _periodicCheck = Timer.periodic(const Duration(seconds: 30), (_) {
      _initConnectivity();
    });
  }

  void dispose() {
    _isDisposed = true;
    _subscription.cancel();
    _periodicCheck?.cancel();
  }
}
