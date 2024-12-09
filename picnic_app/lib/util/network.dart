import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/util/logger.dart';

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
