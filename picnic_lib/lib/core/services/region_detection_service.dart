import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRegion {
  china,
  other,
}

class RegionInfo {
  final UserRegion region;
  final String countryCode;
  final String countryName;
  final DateTime? detectedAt;

  const RegionInfo({
    required this.region,
    required this.countryCode,
    required this.countryName,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
        'region': region.name,
        'countryCode': countryCode,
        'countryName': countryName,
        'detectedAt': detectedAt?.toIso8601String(),
      };

  factory RegionInfo.fromJson(Map<String, dynamic> json) => RegionInfo(
        region: UserRegion.values.firstWhere(
          (e) => e.name == json['region'],
          orElse: () => UserRegion.other,
        ),
        countryCode: json['countryCode'] ?? '',
        countryName: json['countryName'] ?? '',
        detectedAt: json['detectedAt'] != null
            ? DateTime.parse(json['detectedAt'])
            : null,
      );

  bool get isChina => region == UserRegion.china;

  bool get isCacheValid {
    if (detectedAt == null) return false;
    final now = DateTime.now();
    final cacheAge = now.difference(detectedAt!);
    return cacheAge.inHours < 24; // Cache for 24 hours
  }
}

class RegionDetectionService {
  static const String _cacheKey = 'user_region_info';
  static const String _debugRegionKey = 'debug_region_override';
  static const Duration _timeout = Duration(seconds: 10);

  // List of Chinese country codes and regions
  static const Set<String> _chineseRegions = {
    'CN', // China mainland only
  };

  // Debug region simulation (only available in debug mode)
  static String? _debugRegionOverride;

  /// Set debug region override (only works in debug mode)
  static Future<void> setDebugRegion(String? countryCode) async {
    logger
        .i('setDebugRegion called with: $countryCode, kDebugMode: $kDebugMode');

    if (!kDebugMode) {
      logger.w('Debug region override is only available in debug mode');
      return;
    }

    _debugRegionOverride = countryCode?.toUpperCase();

    if (countryCode != null) {
      logger.i('Debug region override set to: $countryCode');

      // Save to preferences for persistence
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_debugRegionKey, countryCode.toUpperCase());
        logger.i('Debug region saved to preferences: $countryCode');
      } catch (e) {
        logger.e('Failed to save debug region to preferences: $e');
      }
    } else {
      logger.i('Debug region override cleared');

      // Remove from preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_debugRegionKey);
        logger.i('Debug region removed from preferences');
      } catch (e) {
        logger.e('Failed to remove debug region from preferences: $e');
      }
    }
  }

  /// Get current debug region override
  static String? get debugRegionOverride =>
      kDebugMode ? _debugRegionOverride : null;

  /// Load debug region override from preferences
  static Future<void> _loadDebugRegionOverride() async {
    if (!kDebugMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _debugRegionOverride = prefs.getString(_debugRegionKey);

      if (_debugRegionOverride != null) {
        logger.i('Loaded debug region override: $_debugRegionOverride');
      }
    } catch (e) {
      logger.w('Failed to load debug region override: $e');
    }
  }

  /// Simulate China region (debug mode only)
  static Future<void> simulateChina() async {
    await setDebugRegion('CN');
  }

  /// Simulate other region (debug mode only)
  static Future<void> simulateOtherRegion([String countryCode = 'US']) async {
    await setDebugRegion(countryCode);
  }

  /// Clear region simulation (debug mode only)
  static Future<void> clearSimulation() async {
    await setDebugRegion(null);
  }

  /// Detect user region with caching and fallback mechanisms
  static Future<RegionInfo> detectRegion() async {
    try {
      // Load debug override if not already loaded
      if (kDebugMode && _debugRegionOverride == null) {
        await _loadDebugRegionOverride();
      }

      // Check for debug region override first (debug mode only)
      if (kDebugMode && _debugRegionOverride != null) {
        final region = _chineseRegions.contains(_debugRegionOverride!)
            ? UserRegion.china
            : UserRegion.other;

        final debugRegionInfo = RegionInfo(
          region: region,
          countryCode: _debugRegionOverride!,
          countryName: 'Debug: $_debugRegionOverride',
          detectedAt: DateTime.now(),
        );

        logger.i(
            'Using debug region override: $_debugRegionOverride (${region.name})');
        logger.i('Available providers: ${getAvailableLoginProviders(region)}');
        return debugRegionInfo;
      }

      // Try to get cached region info first
      final cachedInfo = await _getCachedRegionInfo();
      if (cachedInfo != null && cachedInfo.isCacheValid) {
        logger.i('Using cached region info: ${cachedInfo.countryCode}');
        return cachedInfo;
      }

      // Detect region using multiple methods
      RegionInfo? regionInfo;

      // Method 1: IP-based detection
      regionInfo = await _detectByIP();

      // Method 2: Fallback to device locale if IP detection fails
      regionInfo ??= _detectByDeviceLocale();

      // Method 3: Ultimate fallback
      regionInfo ??= const RegionInfo(
        region: UserRegion.other,
        countryCode: 'UNKNOWN',
        countryName: 'Unknown',
        detectedAt: null,
      );

      // Cache the result
      await _cacheRegionInfo(regionInfo);

      logger.i(
          'Region detected: ${regionInfo.countryCode} (${regionInfo.region.name})');
      return regionInfo;
    } catch (e, s) {
      logger.e('Error detecting region', error: e, stackTrace: s);

      // Return cached info even if expired, or fallback
      final cachedInfo = await _getCachedRegionInfo();
      if (cachedInfo != null) {
        logger.w('Using expired cached region info due to detection error');
        return cachedInfo;
      }

      // Ultimate fallback
      return const RegionInfo(
        region: UserRegion.other,
        countryCode: 'UNKNOWN',
        countryName: 'Unknown',
        detectedAt: null,
      );
    }
  }

  /// Detect region using IP geolocation
  static Future<RegionInfo?> _detectByIP() async {
    try {
      // Using ipinfo.io as primary service (free tier available)
      final response =
          await http.get(Uri.parse('https://ipinfo.io/json')).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['country'] as String?;
        final countryName =
            data['country'] as String?; // ipinfo.io returns code, not name

        if (countryCode != null) {
          final region = _chineseRegions.contains(countryCode.toUpperCase())
              ? UserRegion.china
              : UserRegion.other;

          return RegionInfo(
            region: region,
            countryCode: countryCode.toUpperCase(),
            countryName: countryName ?? countryCode,
            detectedAt: DateTime.now(),
          );
        }
      }

      // Fallback to alternative service
      return await _detectByIPFallback();
    } catch (e) {
      logger.w('IP detection failed: $e');
      return await _detectByIPFallback();
    }
  }

  /// Fallback IP detection using alternative service
  static Future<RegionInfo?> _detectByIPFallback() async {
    try {
      // Using ip-api.com as fallback (free tier available)
      final response =
          await http.get(Uri.parse('http://ip-api.com/json')).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['countryCode'] as String?;
        final countryName = data['country'] as String?;

        if (countryCode != null) {
          final region = _chineseRegions.contains(countryCode.toUpperCase())
              ? UserRegion.china
              : UserRegion.other;

          return RegionInfo(
            region: region,
            countryCode: countryCode.toUpperCase(),
            countryName: countryName ?? countryCode,
            detectedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      logger.w('Fallback IP detection failed: $e');
    }

    return null;
  }

  /// Detect region using device locale as fallback
  static RegionInfo? _detectByDeviceLocale() {
    try {
      if (kIsWeb) {
        // For web, we can't reliably get device locale
        return null;
      }

      final locale = Platform.localeName; // e.g., "zh_CN", "en_US"
      final parts = locale.split('_');

      if (parts.length >= 2) {
        final countryCode = parts[1].toUpperCase();
        final region = _chineseRegions.contains(countryCode)
            ? UserRegion.china
            : UserRegion.other;

        return RegionInfo(
          region: region,
          countryCode: countryCode,
          countryName: countryCode,
          detectedAt: DateTime.now(),
        );
      }
    } catch (e) {
      logger.w('Device locale detection failed: $e');
    }

    return null;
  }

  /// Cache region information
  static Future<void> _cacheRegionInfo(RegionInfo regionInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(regionInfo.toJson()));
    } catch (e) {
      logger.w('Failed to cache region info: $e');
    }
  }

  /// Get cached region information
  static Future<RegionInfo?> _getCachedRegionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        return RegionInfo.fromJson(json);
      }
    } catch (e) {
      logger.w('Failed to get cached region info: $e');
    }

    return null;
  }

  /// Clear cached region information (for testing or manual refresh)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      logger.i('Region cache cleared');
    } catch (e) {
      logger.w('Failed to clear region cache: $e');
    }
  }

  /// Get available login providers for a region
  static List<String> getAvailableLoginProviders(UserRegion region) {
    switch (region) {
      case UserRegion.china:
        return ['apple', 'wechat']; // Only Apple and WeChat for China
      case UserRegion.other:
        return [
          'apple',
          'google',
          'kakao',
          'wechat'
        ]; // All providers for other regions
    }
  }

  /// Check if a specific login provider is available in the current region
  static Future<bool> isLoginProviderAvailable(String provider) async {
    final regionInfo = await detectRegion();
    final availableProviders = getAvailableLoginProviders(regionInfo.region);
    return availableProviders.contains(provider.toLowerCase());
  }
}
