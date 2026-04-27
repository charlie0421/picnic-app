// ignore_for_file: strict_top_level_inference

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';
import 'package:picnic_lib/presentation/providers/check_update_helper.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part '../../generated/providers/check_update_provider.g.dart';

/// SharedPreferences key for caching the last successful [UpdateInfo].
///
/// Cached value is used as a best-effort fallback when [checkUpdate] fails
/// with a determinate error (e.g. a `TypeError` from postgrest 2.6.0's
/// `response.request!.method` NPE — see PICNIC-APP-T2). This ensures that
/// even if a release is shipped with a broken supabase/postgrest version,
/// previously-fetched force-update info still drives the dialog.
const String kCheckUpdateCacheKey = 'check_update_last_info_v1';

enum UpdateStatus {
  upToDate,
  updateRecommended,
  updateRequired,
  needPatch,
}

class UpdateInfo {
  final UpdateStatus status;
  final String currentVersion;
  final String latestVersion;
  final String forceVersion;
  final String? url;

  const UpdateInfo({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.forceVersion,
    this.url,
  });

  UpdateInfo copyWith({
    UpdateStatus? status,
    String? currentVersion,
    String? latestVersion,
    String? forceVersion,
    String? url,
  }) {
    return UpdateInfo(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      forceVersion: forceVersion ?? this.forceVersion,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'forceVersion': forceVersion,
        'url': url,
      };

  static UpdateInfo? fromJson(Map<String, dynamic> json) {
    try {
      final statusName = json['status'] as String?;
      final status = UpdateStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => UpdateStatus.upToDate,
      );
      return UpdateInfo(
        status: status,
        currentVersion: json['currentVersion'] as String? ?? '',
        latestVersion: json['latestVersion'] as String? ?? '',
        forceVersion: json['forceVersion'] as String? ?? '',
        url: json['url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

@riverpod
Future<UpdateInfo?> checkUpdate(ref) async {
  // Resolve current version first; if even this step fails (e.g. test env
  // without WidgetsFlutterBinding, or a platform channel error), preserve
  // the original silent-null behavior so callers don't crash.
  final String currentVersion;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    currentVersion = packageInfo.version;
  } catch (e) {
    logger.d('checkUpdate: PackageInfo unavailable — $e');
    return null;
  }

  try {
    final fresh = await _fetchUpdateInfoFromServer(currentVersion);
    if (fresh != null) {
      // Re-derive status against current package version (fresh.currentVersion
      // equals currentVersion already, so this is just the cache write).
      await _saveCache(fresh);
    }
    return fresh;
  } on TypeError catch (e, stack) {
    // Determinate library defect (e.g. postgrest 2.6.0 NPE on response.request).
    // Retry won't help; surface to Sentry explicitly so silent failures of
    // checkUpdate are observable, then fall back to the last cached info so
    // force-update dialogs still trigger for users on the broken release.
    logger.w('checkUpdate hit a TypeError — falling back to cache', error: e);
    unawaited(
      Sentry.captureException(
        e,
        stackTrace: stack,
        withScope: (scope) {
          scope.setTag('checkUpdate.fallback', 'typeerror');
          scope.setTag('checkUpdate.currentVersion', currentVersion);
        },
      ),
    );
    return _restatusCache(await _loadCache(), currentVersion);
  } catch (e) {
    // Network/transient — keep silent. Best-effort cache fallback so the
    // dialog at least uses the most recent known force_version.
    logger.d('checkUpdate failed (transient): $e — using cache if any');
    return _restatusCache(await _loadCache(), currentVersion);
  }
}

/// Real server fetch — extracted so the catch-flow above stays small.
Future<UpdateInfo?> _fetchUpdateInfoFromServer(String currentVersion) async {
  final response = await supabase
      .from("version")
      .select()
      .filter('deleted_at', 'is', null)
      .limit(1)
      .single();
  final appVersionModel = AppVersionModel.fromJson(response);

  final platformName = _getPlatformName();
  final platformInfo =
      CheckUpdateHelper.getPlatformInfo(appVersionModel, platformName);

  if (platformInfo == null) {
    return null;
  }

  final latestVersion = platformInfo['version'];
  final forceVersion = platformInfo['force_version'];
  final url = platformInfo['url'];

  if (latestVersion == null || forceVersion == null || url == null) {
    return null;
  }

  final status = CheckUpdateHelper.determineUpdateStatus(
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    forceVersion: forceVersion,
  );

  return UpdateInfo(
    status: status,
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    forceVersion: forceVersion,
    url: url,
  );
}

Future<void> _saveCache(UpdateInfo info) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kCheckUpdateCacheKey, jsonEncode(info.toJson()));
  } catch (e) {
    logger.d('checkUpdate cache write failed (non-fatal): $e');
  }
}

Future<UpdateInfo?> _loadCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kCheckUpdateCacheKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UpdateInfo.fromJson(json);
  } catch (e) {
    logger.d('checkUpdate cache read failed (non-fatal): $e');
    return null;
  }
}

/// Recompute [UpdateStatus] using cached forceVersion/latestVersion against
/// the *current* package version. Without this, a cached snapshot taken when
/// the user was on an older version would carry a stale status.
UpdateInfo? _restatusCache(UpdateInfo? cached, String currentVersion) {
  if (cached == null) return null;
  final status = CheckUpdateHelper.determineUpdateStatus(
    currentVersion: currentVersion,
    latestVersion: cached.latestVersion,
    forceVersion: cached.forceVersion,
  );
  return cached.copyWith(
    currentVersion: currentVersion,
    status: status,
  );
}

String _getPlatformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'unknown';
}
