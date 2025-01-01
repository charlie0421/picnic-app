// token_refresh_manager.dart

import 'dart:async';

import 'package:picnic_app/core/services/auth/auth_service.dart';
import 'package:picnic_app/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TokenRefreshManager {
  static const _refreshThreshold = Duration(minutes: 5);

  final AuthService _authService;
  Timer? _refreshTimer;
  StreamSubscription? _sessionSubscription;

  TokenRefreshManager(this._authService);

  void startPeriodicRefresh() {
    stopPeriodicRefresh();

    _sessionSubscription = _authService.sessionStream.listen((session) {
      if (session != null) {
        _scheduleNextRefresh(session);
      } else {
        stopPeriodicRefresh();
      }
    });

    logger.i('Token refresh monitoring started');
  }

  void _scheduleNextRefresh(Session session) {
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final refreshTime = expiresAt.subtract(_refreshThreshold);

    _refreshTimer?.cancel();

    if (refreshTime.isAfter(DateTime.now())) {
      final delay = refreshTime.difference(DateTime.now());
      _refreshTimer = Timer(delay, () async {
        try {
          final success = await _authService.refreshSession();
          if (success) {
            logger.i('Token refresh completed successfully');
          } else {
            logger.w('Token refresh failed');
          }
        } catch (e, s) {
          logger.e('Token refresh failed', error: e, stackTrace: s);
        }
      });
    } else {
      // 만료 시간이 임박했거나 지난 경우 즉시 갱신
      _authService.refreshSession();
    }
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    _sessionSubscription?.cancel();
    _sessionSubscription = null;

    logger.i('Token refresh monitoring stopped');
  }

  void dispose() {
    stopPeriodicRefresh();
  }
}
