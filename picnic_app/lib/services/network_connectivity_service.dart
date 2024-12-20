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

  Future<bool> checkOnlineStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.isEmpty &&
        connectivityResult.first == ConnectivityResult.none) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Stream<bool> get onlineStream async* {
    await for (final connectivityResult
        in _connectivity.onConnectivityChanged) {
      if (connectivityResult.isEmpty &&
          connectivityResult.first == ConnectivityResult.none) {
        yield false;
        continue;
      }

      try {
        final result = await InternetAddress.lookup('google.com');
        yield result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        yield false;
      }
    }
  }
}
