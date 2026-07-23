import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  static bool hasNoConnectivity(List<ConnectivityResult> results) {
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }

  Future<bool> checkOnlineStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity().timeout(
      const Duration(seconds: 3),
    );
    if (hasNoConnectivity(connectivityResult)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Stream<bool> get onlineStream async* {
    await for (final connectivityResult
        in _connectivity.onConnectivityChanged) {
      if (hasNoConnectivity(connectivityResult)) {
        yield false;
        continue;
      }

      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));
        yield result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        yield false;
      } on TimeoutException catch (_) {
        yield false;
      }
    }
  }
}
