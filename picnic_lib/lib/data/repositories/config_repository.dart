import 'package:picnic_lib/data/repositories/base_repository.dart';

/// 설정 데이터 모델
class ConfigModel {
  final String key;
  final String value;
  final String? description;
  final DateTime? updatedAt;

  ConfigModel({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// 설정 데이터 접근을 위한 Repository
class ConfigRepository extends BaseCrudRepository<ConfigModel, String> {
  @override
  String get tableName => 'config';

  @override
  ConfigModel fromJson(Map<String, dynamic> json) => ConfigModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(ConfigModel model) => model.toJson();

  @override
  String getId(ConfigModel model) => model.key;

  /// 특정 키의 설정 값을 가져옵니다.
  Future<String?> getValue(String key) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('value')
          .eq('key', key)
          .maybeSingle();

      return response?['value'] as String?;
    } catch (e) {
      return handleError('getValue', Exception(e), null);
    }
  }

  /// 여러 키의 설정 값들을 한번에 가져옵니다.
  Future<Map<String, String>> getValues(List<String> keys) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('key, value')
          .inFilter('key', keys);

      final Map<String, String> result = {};
      for (final item in response) {
        result[item['key']] = item['value'];
      }
      
      return result;
    } catch (e) {
      return handleError('getValues', Exception(e), <String, String>{});
    }
  }

  /// 설정 값을 설정합니다. (관리자 권한 필요)
  Future<bool> setValue(String key, String value, {String? description}) async {
    try {
      requireAuth();
      
      await supabase.from(tableName).upsert({
        'key': key,
        'value': value,
        'description': description,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      return handleError('setValue', Exception(e), false);
    }
  }

  /// 여러 설정을 한번에 설정합니다.
  Future<bool> setValues(Map<String, String> configs) async {
    try {
      requireAuth();
      
      final now = DateTime.now().toUtc().toIso8601String();
      final data = configs.entries.map((entry) => {
        'key': entry.key,
        'value': entry.value,
        'updated_at': now,
      }).toList();

      await supabase.from(tableName).upsert(data);
      return true;
    } catch (e) {
      return handleError('setValues', Exception(e), false);
    }
  }

  /// 특정 키의 설정을 실시간으로 스트림합니다.
  Stream<String?> streamValue(String key) {
    try {
      return supabase
          .from(tableName)
          .stream(primaryKey: ['key'])
          .eq('key', key)
          .map((events) {
            if (events.isNotEmpty) {
              return events.first['value'] as String?;
            }
            return null;
          });
    } catch (e) {
      logger.e('Error streaming config value for key: $key', error: e);
      return Stream.value(null);
    }
  }

  /// 모든 설정을 실시간으로 스트림합니다.
  Stream<Map<String, String>> streamAllValues() {
    try {
      return supabase
          .from(tableName)
          .stream(primaryKey: ['key'])
          .map((events) {
            final Map<String, String> result = {};
            for (final event in events) {
              result[event['key']] = event['value'];
            }
            return result;
          });
    } catch (e) {
      logger.e('Error streaming all config values', error: e);
      return Stream.value(<String, String>{});
    }
  }

  /// 특정 접두사로 시작하는 설정들을 가져옵니다.
  Future<Map<String, String>> getValuesByPrefix(String prefix) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('key, value')
          .like('key', '$prefix%');

      final Map<String, String> result = {};
      for (final item in response) {
        result[item['key']] = item['value'];
      }
      
      return result;
    } catch (e) {
      return handleError('getValuesByPrefix', Exception(e), <String, String>{});
    }
  }

  /// 설정이 존재하는지 확인합니다.
  Future<bool> exists(String key) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('key')
          .eq('key', key)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return handleError('exists', Exception(e), false);
    }
  }

  /// Boolean 값으로 설정을 가져옵니다.
  Future<bool> getBoolValue(String key, {bool defaultValue = false}) async {
    try {
      final value = await getValue(key);
      if (value == null) return defaultValue;
      
      return value.toLowerCase() == 'true' || value == '1';
    } catch (e) {
      return handleError('getBoolValue', Exception(e), defaultValue);
    }
  }

  /// Integer 값으로 설정을 가져옵니다.
  Future<int> getIntValue(String key, {int defaultValue = 0}) async {
    try {
      final value = await getValue(key);
      if (value == null) return defaultValue;
      
      return int.tryParse(value) ?? defaultValue;
    } catch (e) {
      return handleError('getIntValue', Exception(e), defaultValue);
    }
  }

  /// Double 값으로 설정을 가져옵니다.
  Future<double> getDoubleValue(String key, {double defaultValue = 0.0}) async {
    try {
      final value = await getValue(key);
      if (value == null) return defaultValue;
      
      return double.tryParse(value) ?? defaultValue;
    } catch (e) {
      return handleError('getDoubleValue', Exception(e), defaultValue);
    }
  }

  /// JSON 값으로 설정을 가져옵니다.
  Future<Map<String, dynamic>?> getJsonValue(String key) async {
    try {
      final value = await getValue(key);
      if (value == null) return null;
      
      return Map<String, dynamic>.from(
        const JsonDecoder().convert(value) as Map
      );
    } catch (e) {
      return handleError('getJsonValue', Exception(e), null);
    }
  }
}

/// JSON 디코더 (dart:convert 대신 사용)
class JsonDecoder {
  const JsonDecoder();
  
  dynamic convert(String source) {
    // 실제 구현에서는 dart:convert의 jsonDecode를 사용
    throw UnimplementedError('JSON decoding not implemented');
  }
}