import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure helper functions extracted from [VirtualMachineDetector].
///
/// All methods are static, side-effect-free, and require no device access,
/// making them straightforward to unit-test.
@visibleForTesting
class VirtualMachineDetectorHelper {
  VirtualMachineDetectorHelper._();

  // ---------------------------------------------------------------------------
  // Keyword parsing
  // ---------------------------------------------------------------------------

  /// Splits a comma-separated config string into a list of non-empty keywords.
  static List<String> sanitizeKeywords(String? config) {
    if (config == null || config.isEmpty) return [];
    return config.split(',').where((k) => k.isNotEmpty).toList();
  }

  // ---------------------------------------------------------------------------
  // String matching
  // ---------------------------------------------------------------------------

  /// Returns `true` when [keyword] appears in [text] as a whole token
  /// (bounded by non-alphanumeric / non-underscore characters).
  static bool containsWholeToken(String text, String keyword) {
    if (keyword.isEmpty) return false;
    final pattern = RegExp(
      '(?<![A-Za-z0-9_])${RegExp.escape(keyword)}(?![A-Za-z0-9_])',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Returns the list of keywords (from [keywords]) that match as whole tokens
  /// inside [text].
  static List<String> findMatchingKeywords(
    String text,
    List<String> keywords,
  ) {
    return keywords
        .where((keyword) => containsWholeToken(text, keyword))
        .toList();
  }

  /// Returns the list of keywords (from [keywords]) that appear as substrings
  /// inside [text] (case-insensitive).
  static List<String> findContainedKeywords(
    String text,
    List<String> keywords,
  ) {
    final lower = text.toLowerCase();
    return keywords
        .where((keyword) => lower.contains(keyword.toLowerCase()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Build-value checks
  // ---------------------------------------------------------------------------

  /// Evaluates whether a device info blob (already lowercased) matches any of
  /// the provided keyword lists.
  ///
  /// Returns a map with:
  /// - `has_vm_keywords` (bool)
  /// - `has_bluestacks_keywords` (bool)
  /// - `suspicious_hardware` (bool)
  /// - `suspicious_manufacturer` (bool)
  static Map<String, bool> evaluateBuildKeywords({
    required String deviceInfoLower,
    required String hardwareLower,
    required String manufacturerLower,
    required List<String> vmKeywords,
    required List<String> bluestacksKeywords,
    required List<String> hardwareKeywords,
    required List<String> manufacturerKeywords,
  }) {
    final vmMatches = findMatchingKeywords(deviceInfoLower, vmKeywords);
    final bsMatches = findMatchingKeywords(deviceInfoLower, bluestacksKeywords);
    final hwMatches = findContainedKeywords(hardwareLower, hardwareKeywords);
    final mfMatches =
        findContainedKeywords(manufacturerLower, manufacturerKeywords);

    final suspiciousHardware = hardwareLower.isEmpty || hwMatches.isNotEmpty;

    return {
      'has_vm_keywords': vmMatches.isNotEmpty,
      'has_bluestacks_keywords': bsMatches.isNotEmpty,
      'suspicious_hardware': suspiciousHardware,
      'suspicious_manufacturer': mfMatches.isNotEmpty,
    };
  }

  /// Returns `true` when any flag in [buildResults] is `true`.
  static bool isBuildSuspicious(Map<String, bool> buildResults) {
    return buildResults.values.any((v) => v);
  }

  // ---------------------------------------------------------------------------
  // Samsung strict-mode check
  // ---------------------------------------------------------------------------

  /// Returns a list of suspicious reasons for a Samsung device.
  /// An empty list means no issues found.
  static List<String> checkSamsungSuspiciousPatterns({
    required String manufacturerLower,
    required String modelLower,
    required String bootloaderLower,
    required List<String> systemFeatures,
  }) {
    if (manufacturerLower != 'samsung' || !modelLower.startsWith('sm-')) {
      return [];
    }

    final reasons = <String>[];

    if (bootloaderLower == 'unknown') {
      reasons.add('unknown_bootloader');
    }

    if (modelLower.contains('galaxy') &&
        !systemFeatures.any((f) => f.contains('knox'))) {
      reasons.add('missing_knox');
    }

    return reasons;
  }

  // ---------------------------------------------------------------------------
  // Hardware checks
  // ---------------------------------------------------------------------------

  /// Returns `true` when the CPU info or sensor state is suspicious.
  static bool checkHardware({
    required String cpuInfoLower,
    required bool hasSensors,
    required List<String> cpuKeywords,
  }) {
    final suspiciousCpu = cpuKeywords.any(
          (keyword) => cpuInfoLower.contains(keyword.toLowerCase()),
        ) ||
        cpuInfoLower.contains('hypervisor') ||
        cpuInfoLower.contains('virtual') ||
        cpuInfoLower.contains('qemu');

    return suspiciousCpu || !hasSensors;
  }

  /// Counts `processor` lines in raw `/proc/cpuinfo` text.
  static int countProcessorsFromCpuInfo(String cpuInfoText) {
    return cpuInfoText
        .split('\n')
        .where((line) => line.trim().toLowerCase().startsWith('processor'))
        .length;
  }

  // ---------------------------------------------------------------------------
  // Network checks
  // ---------------------------------------------------------------------------

  /// Parses the TTL value out of a typical `ping` command's stdout.
  static int? parseTTLFromPingOutput(String output) {
    final match = RegExp(r'ttl=(\d+)').firstMatch(output);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  /// Returns `true` when TTL or MAC address look suspicious.
  static bool checkNetwork({
    required int? ttl,
    required String? macAddress,
    required String? ttlRangeConfig,
    required String? macKeywordsConfig,
  }) {
    final ttlRange = sanitizeKeywords(ttlRangeConfig);
    final macKeywords = sanitizeKeywords(macKeywordsConfig);

    final suspiciousTtl = ttlRange.length == 2 &&
        ttl != null &&
        int.tryParse(ttlRange[0]) != null &&
        int.tryParse(ttlRange[1]) != null &&
        ttl >= int.parse(ttlRange[0]) &&
        ttl <= int.parse(ttlRange[1]);

    final suspiciousMac = macAddress != null &&
        macKeywords.any(
          (keyword) => keyword.isNotEmpty && macAddress.startsWith(keyword),
        );

    return suspiciousTtl || suspiciousMac;
  }

  // ---------------------------------------------------------------------------
  // Sensor feature check
  // ---------------------------------------------------------------------------

  /// The well-known sensor features used for physical-device heuristics.
  static const List<String> sensorFeatures = [
    'android.hardware.sensor.accelerometer',
    'android.hardware.sensor.gyroscope',
    'android.hardware.sensor.compass',
    'android.hardware.touchscreen',
  ];

  /// Returns `true` when at least [threshold] sensor features are present in
  /// [systemFeatures].
  static bool hasSufficientSensors(
    List<String> systemFeatures, {
    int threshold = 2,
  }) {
    final count =
        sensorFeatures.where((f) => systemFeatures.contains(f)).length;
    return count >= threshold;
  }

  // ---------------------------------------------------------------------------
  // Overall scoring
  // ---------------------------------------------------------------------------

  /// Combines the three detection pillars into a single boolean.
  static bool isVirtualMachine({
    required bool buildSuspicious,
    required bool hardwareSuspicious,
    required bool networkSuspicious,
    bool buildCheckEnabled = true,
    bool hardwareCheckEnabled = true,
    bool networkCheckEnabled = true,
  }) {
    final build = buildCheckEnabled && buildSuspicious;
    final hardware = hardwareCheckEnabled && hardwareSuspicious;
    final network = networkCheckEnabled && networkSuspicious;
    return build || hardware || network;
  }
}
