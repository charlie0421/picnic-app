import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/util/auth_service.dart';

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
    } catch (e) {
      print('Error checking initial connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) async {
    print('Connectivity changed: $result');
    print('Previous connection status: $_wasConnected');

    bool isConnected =
        result.isNotEmpty && result.first != ConnectivityResult.none;
    print('Current connection status: $isConnected');

    if (isConnected && !_wasConnected) {
      print('Network connection restored. Attempting token refresh.');
      await _authService.refreshToken();
    } else if (!isConnected && _wasConnected) {
      print('Network connection lost.');
    }

    _wasConnected = isConnected;
  }

  void _startPeriodicCheck() {
    logger.i('Starting periodic network check');
    _periodicCheck = Timer.periodic(Duration(seconds: 30), (_) {
      _initConnectivity();
    });
  }

  void dispose() {
    _subscription.cancel();
    _periodicCheck?.cancel();
  }
}
