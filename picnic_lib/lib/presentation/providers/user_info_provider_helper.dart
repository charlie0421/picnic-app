import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

/// Pure helper functions extracted from user_info_provider for testability.
@visibleForTesting
class UserInfoProviderHelper {
  const UserInfoProviderHelper._();

  /// Normalizes a language code for storage.
  ///
  /// Rules:
  /// - `zh_CN` or `zh` -> `zh`
  /// - `zh_TW` -> `zh-TW`
  /// - `bn_BD` or `bn` -> `bn`
  /// - Others: extract the part before `_` (e.g. `ko_KR` -> `ko`)
  @visibleForTesting
  static String normalizeLanguageCode(String languageCode) {
    String normalized = languageCode;
    if (normalized.startsWith('zh_CN') || normalized == 'zh') {
      return 'zh';
    } else if (normalized.startsWith('zh_TW')) {
      return 'zh-TW';
    } else if (normalized.startsWith('bn_BD') || normalized == 'bn') {
      return 'bn';
    } else {
      final parts = normalized.split('_');
      return parts[0];
    }
  }

  /// Builds the update map for a profile update request.
  /// Only includes non-null parameters.
  @visibleForTesting
  static Map<String, dynamic> buildProfileUpdateMap({
    String? gender,
    DateTime? birthDate,
    String? birthTime,
    required DateTime updatedAt,
  }) {
    return {
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate.toIso8601String(),
      if (birthTime != null) 'birth_time': birthTime,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Parses the nickname update edge-function response.
  /// Returns the updated [UserProfilesModel] on success, or null if the
  /// response status is not 200.
  @visibleForTesting
  static UserProfilesModel? parseNicknameResponse({
    required int status,
    required dynamic data,
  }) {
    if (status != 200) {
      return null;
    }
    final decoded = data is String ? jsonDecode(data) : data;
    return UserProfilesModel.fromJson(decoded['data']);
  }

  /// Parses the expire-bonus edge-function response into a list of maps.
  /// Returns null when the format is unexpected.
  @visibleForTesting
  static List<Map<String, dynamic>>? parseExpireBonusResponse(dynamic parsed) {
    if (parsed is List) {
      return List<Map<String, dynamic>>.from(parsed);
    }
    if (parsed is Map && parsed['data'] is List) {
      return List<Map<String, dynamic>>.from(parsed['data'] as List);
    }
    return null;
  }
}
