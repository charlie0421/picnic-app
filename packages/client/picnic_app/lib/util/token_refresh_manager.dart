import 'dart:async';

import 'package:picnic_app/util/auth_service.dart';

class TokenRefreshManager {
  final AuthService _authService;
  Timer? _refreshTimer;

  TokenRefreshManager(this._authService);

  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _authService.refreshToken();
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
  }
}
