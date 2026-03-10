import 'dart:convert';
import 'dart:io';

/// JSON 파일에서 테스트 데이터를 로드하는 유틸리티
///
/// 사용법:
///   final json = FixtureLoader.load('vote_fixtures.json', 'basic_vote');
///   final list = FixtureLoader.loadList('vote_fixtures.json', 'vote_list');
class FixtureLoader {
  static String get _fixturesPath {
    // flutter test는 프로젝트 루트에서 실행됨
    return 'test/helpers/fixtures';
  }

  /// 단일 JSON 객체 로드
  static Map<String, dynamic> load(String fileName, String key) {
    final file = File('$_fixturesPath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName');
    }
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (!data.containsKey(key)) {
      throw ArgumentError('Key "$key" not found in $fileName');
    }
    return data[key] as Map<String, dynamic>;
  }

  /// JSON 배열 로드
  static List<Map<String, dynamic>> loadList(String fileName, String key) {
    final file = File('$_fixturesPath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName');
    }
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (!data.containsKey(key)) {
      throw ArgumentError('Key "$key" not found in $fileName');
    }
    return (data[key] as List).cast<Map<String, dynamic>>();
  }

  /// Raw JSON 문자열 로드
  static String loadRaw(String fileName) {
    final file = File('$_fixturesPath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName');
    }
    return file.readAsStringSync();
  }
}
