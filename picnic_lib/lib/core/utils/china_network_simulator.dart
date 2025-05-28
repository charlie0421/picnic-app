import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// Simulates Chinese network conditions for testing WeChat login
/// and other China-specific features
class ChinaNetworkSimulator {
  static const Duration _baseLatency = Duration(milliseconds: 200);
  static const Duration _maxLatency = Duration(milliseconds: 2000);
  static const double _packetLossRate = 0.05; // 5% packet loss
  static const double _connectionFailureRate = 0.1; // 10% connection failure

  static bool _isEnabled = false;
  static bool _isGfwBlocked = false;
  static final Random _random = Random();

  /// Enable China network simulation
  static void enable({bool simulateGfw = false}) {
    _isEnabled = true;
    _isGfwBlocked = simulateGfw;
    logger.i('China network simulation enabled (GFW: $simulateGfw)');
  }

  /// Disable China network simulation
  static void disable() {
    _isEnabled = false;
    _isGfwBlocked = false;
    logger.i('China network simulation disabled');
  }

  /// Check if simulation is enabled
  static bool get isEnabled => _isEnabled;

  /// Check if GFW blocking is simulated
  static bool get isGfwBlocked => _isGfwBlocked;

  /// Simulate network delay typical in China
  static Future<void> simulateNetworkDelay() async {
    if (!_isEnabled) return;

    final latency = _baseLatency +
        Duration(
            milliseconds: _random.nextInt(
                _maxLatency.inMilliseconds - _baseLatency.inMilliseconds));

    logger.d('Simulating China network delay: ${latency.inMilliseconds}ms');
    await Future.delayed(latency);
  }

  /// Simulate packet loss
  static bool simulatePacketLoss() {
    if (!_isEnabled) return false;

    final isLost = _random.nextDouble() < _packetLossRate;
    if (isLost) {
      logger.d('Simulating packet loss');
    }
    return isLost;
  }

  /// Simulate connection failure
  static bool simulateConnectionFailure() {
    if (!_isEnabled) return false;

    final isFailed = _random.nextDouble() < _connectionFailureRate;
    if (isFailed) {
      logger.d('Simulating connection failure');
    }
    return isFailed;
  }

  /// Simulate Great Firewall blocking for non-Chinese services
  static bool isServiceBlocked(String service) {
    if (!_isEnabled || !_isGfwBlocked) return false;

    final blockedServices = [
      'google',
      'facebook',
      'twitter',
      'youtube',
      'instagram',
      'whatsapp',
      'telegram',
      'discord',
      'reddit',
      'pinterest',
      'snapchat',
      'tiktok', // International version
      'github', // Sometimes blocked
    ];

    final isBlocked = blockedServices
        .any((blocked) => service.toLowerCase().contains(blocked));

    if (isBlocked) {
      logger.w('GFW simulation: Service $service is blocked');
    }

    return isBlocked;
  }

  /// Simulate Chinese mobile network characteristics
  static Future<T> simulateChinaMobileNetwork<T>(
      Future<T> Function() operation) async {
    if (!_isEnabled) return await operation();

    // Simulate connection failure
    if (simulateConnectionFailure()) {
      throw Exception('China network simulation: Connection failed');
    }

    // Simulate packet loss (retry mechanism)
    if (simulatePacketLoss()) {
      logger.d('Packet lost, retrying...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Second attempt
      if (simulatePacketLoss()) {
        throw Exception(
            'China network simulation: Packet loss - operation failed');
      }
    }

    // Add network delay
    await simulateNetworkDelay();

    // Execute the actual operation
    return await operation();
  }

  /// Get simulated device characteristics for popular Chinese devices
  static Map<String, dynamic> getChineseDeviceCharacteristics() {
    final devices = [
      {
        'brand': 'Huawei',
        'model': 'P50 Pro',
        'os': 'HarmonyOS',
        'characteristics': {
          'hasGoogleServices': false,
          'hasHuaweiServices': true,
          'networkOptimization': 'china_mobile',
          'wechatIntegration': 'deep',
        }
      },
      {
        'brand': 'Xiaomi',
        'model': 'Mi 13',
        'os': 'MIUI 14',
        'characteristics': {
          'hasGoogleServices': true,
          'hasXiaomiServices': true,
          'networkOptimization': 'china_unicom',
          'wechatIntegration': 'standard',
        }
      },
      {
        'brand': 'Oppo',
        'model': 'Find X6',
        'os': 'ColorOS 13',
        'characteristics': {
          'hasGoogleServices': true,
          'hasOppoServices': true,
          'networkOptimization': 'china_telecom',
          'wechatIntegration': 'standard',
        }
      },
      {
        'brand': 'Vivo',
        'model': 'X90 Pro',
        'os': 'OriginOS 3',
        'characteristics': {
          'hasGoogleServices': true,
          'hasVivoServices': true,
          'networkOptimization': 'china_mobile',
          'wechatIntegration': 'standard',
        }
      },
      {
        'brand': 'Apple',
        'model': 'iPhone 14 Pro',
        'os': 'iOS 16',
        'characteristics': {
          'hasGoogleServices': false,
          'hasAppleServices': true,
          'networkOptimization': 'standard',
          'wechatIntegration': 'standard',
        }
      },
    ];

    return devices[_random.nextInt(devices.length)];
  }

  /// Test WeChat connectivity specifically
  static Future<bool> testWeChatConnectivity() async {
    if (!_isEnabled) return true;

    logger.i('Testing WeChat connectivity in China network simulation...');

    try {
      // WeChat should always work in China
      await simulateNetworkDelay();

      // Simulate occasional WeChat server issues (rare)
      if (_random.nextDouble() < 0.02) {
        // 2% chance
        logger.w('WeChat server temporarily unavailable');
        return false;
      }

      logger.i('WeChat connectivity test passed');
      return true;
    } catch (e) {
      logger.e('WeChat connectivity test failed: $e');
      return false;
    }
  }

  /// Generate test report for China network conditions
  static Map<String, dynamic> generateTestReport() {
    return {
      'simulationEnabled': _isEnabled,
      'gfwSimulation': _isGfwBlocked,
      'networkCharacteristics': {
        'baseLatency': '${_baseLatency.inMilliseconds}ms',
        'maxLatency': '${_maxLatency.inMilliseconds}ms',
        'packetLossRate': '${(_packetLossRate * 100).toStringAsFixed(1)}%',
        'connectionFailureRate':
            '${(_connectionFailureRate * 100).toStringAsFixed(1)}%',
      },
      'testEnvironment': kDebugMode ? 'development' : 'production',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
