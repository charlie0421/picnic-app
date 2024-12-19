import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.first != ConnectivityResult.none;
  }

  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) =>
          results.any((result) => result != ConnectivityResult.none));
}
