import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivityService {
  static const _checkTimeout = Duration(seconds: 5);
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  Future<bool> checkOnlineStatus() async {
    try {
      // Startup must be able to show its retry screen even when the platform
      // channel or DNS resolver never replies.
      return await _checkOnlineStatus().timeout(_checkTimeout);
    } on Exception {
      return false;
    }
  }

  Future<bool> _checkOnlineStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (!_hasConnection(connectivityResult)) return false;
    return _checkInternetAccess();
  }

  static bool _hasConnection(List<ConnectivityResult> result) =>
      result.any((connection) => connection != ConnectivityResult.none);

  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(_checkTimeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  Stream<bool> get onlineStream async* {
    await for (final connectivityResult
        in _connectivity.onConnectivityChanged) {
      if (!_hasConnection(connectivityResult)) {
        yield false;
        continue;
      }

      yield await _checkInternetAccess();
    }
  }
}
