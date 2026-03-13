import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:picnic_lib/core/services/app_badge_helper.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage app icon badge count
/// Syncs the badge number with unread notifications count
class AppBadgeService {
  static bool _isSupported = false;
  static bool _checkedSupport = false;

  /// Check if app badges are supported on this device
  static Future<bool> isSupported() async {
    if (_checkedSupport) return _isSupported;

    if (kIsWeb) {
      _checkedSupport = true;
      _isSupported = false;
      return false;
    }

    try {
      _isSupported = await FlutterAppBadger.isAppBadgeSupported();
      _checkedSupport = true;
      logger.i('App badge supported: $_isSupported');
      return _isSupported;
    } catch (e) {
      logger.w('Failed to check badge support: $e');
      _checkedSupport = true;
      _isSupported = false;
      return false;
    }
  }

  /// Update badge count to match unread notifications
  static Future<void> syncBadgeWithUnreadCount() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      final supported = await isSupported();
      if (!supported) return;

      final count = await _getUnreadCount();
      await _updateBadge(count);
    } catch (e, s) {
      logger.e('Failed to sync badge', error: e, stackTrace: s);
    }
  }

  /// Set badge to a specific count
  static Future<void> setBadgeCount(int count) async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      final supported = await isSupported();
      if (!supported) return;

      await _updateBadge(count);
    } catch (e, s) {
      logger.e('Failed to set badge count', error: e, stackTrace: s);
    }
  }

  /// Remove badge (set count to 0)
  static Future<void> removeBadge() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      final supported = await isSupported();
      if (!supported) return;

      await FlutterAppBadger.removeBadge();
      logger.i('App badge removed');
    } catch (e, s) {
      logger.e('Failed to remove badge', error: e, stackTrace: s);
    }
  }

  /// Get unread notifications count from database
  static Future<int> _getUnreadCount() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return 0;

      final List<dynamic> rows = await client
          .from('user_notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .limit(200);

      return rows.length;
    } catch (e) {
      logger.w('Failed to get unread count for badge: $e');
      return 0;
    }
  }

  /// Update badge with count
  static Future<void> _updateBadge(int count) async {
    try {
      final action = AppBadgeHelper.determineBadgeAction(count);
      switch (action) {
        case BadgeUpdateAction.remove:
          await FlutterAppBadger.removeBadge();
          logger.i('App badge removed (count: 0)');
          break;
        case BadgeUpdateAction.update:
          await FlutterAppBadger.updateBadgeCount(count);
          logger.i('App badge updated: $count');
          break;
      }
    } catch (e) {
      logger.w('Failed to update badge: $e');
    }
  }
}
