import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:retry/retry.dart';

class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxAttempts;

  RetryHttpClient(this._inner, {this.maxAttempts = 3});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await retry(
        () => _inner.send(request).timeout(const Duration(seconds: 30)),
        maxAttempts: maxAttempts,
        retryIf: (e) =>
            e is SocketException ||
            e is TimeoutException ||
            e is ClientException,
        onRetry: (e) => logger.e('재시도 중: $e'),
      );
    } on Exception catch (e, s) {
      logger.e('HTTP 요청 실패: $e, $s');
      return http.StreamedResponse(
        Stream.fromIterable([]),
        500,
        reasonPhrase: '네트워크 오류',
      );
    }
  }
}

class NetworkCheck {
  static Future<bool> isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    logger.i('Connectivity result: $connectivityResult');

    return connectivityResult.isNotEmpty &&
        connectivityResult.first != ConnectivityResult.none;
  }
}

class NetworkStatusListener {
  final AuthService _authService;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _wasConnected = true;
  Timer? _periodicCheck;

  NetworkStatusListener(this._authService) {
    _initConnectivity();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _startPeriodicCheck();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e, s) {
      logger.e('Error checking initial connectivity: $e', stackTrace: s);
      rethrow;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) async {
    bool isConnected =
        result.isNotEmpty && result.first != ConnectivityResult.none;

    logger.i('Network connection status: $isConnected\n'
        'Previous connection status: $_wasConnected');

    if (isConnected && !_wasConnected) {
      logger.i('Network connection restored. Attempting token refresh.');
      await _authService.refreshToken();
    } else if (!isConnected && _wasConnected) {
      logger.i('Network connection lost.');
    }

    _wasConnected = isConnected;
  }

  void _startPeriodicCheck() {
    logger.i('Starting periodic network check');
    _periodicCheck = Timer.periodic(const Duration(seconds: 30), (_) {
      _initConnectivity();
    });
  }

  void dispose() {
    _subscription.cancel();
    _periodicCheck?.cancel();
  }
}
