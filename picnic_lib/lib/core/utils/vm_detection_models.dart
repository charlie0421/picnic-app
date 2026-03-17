// 가상머신 체크 설정 (오탐 방지용)
class VMDetectionConfig {
  // 개별 체크 비활성화 옵션
  static const bool enableBuildCheck = true;
  static const bool enableHardwareCheck = true;
  static const bool enableNetworkCheck = false; // 네트워크 체크는 오탐이 많아서 비활성화
  static const bool enableSamsungStrictCheck = false; // 삼성 기기 엄격 체크 비활성화
  static const bool enableSentryReport = true;

  // 디버그 모드 설정
  static const bool disableInDebugMode = true; // 디버그 모드에서 완전 비활성화

  // 환경변수로 전체 가상머신 체크 비활성화
  static bool get isVMCheckDisabled {
    const envDisabled = String.fromEnvironment('DISABLE_VM_CHECK');
    const envNoCheck = String.fromEnvironment('NO_VM_CHECK');
    const envSkipCheck = String.fromEnvironment('SKIP_VM_CHECK');

    return envDisabled == 'true' ||
        envNoCheck == 'true' ||
        envSkipCheck == 'true';
  }
}

// 클래스들을 파일 상단으로 이동
class KeywordMatch {
  final String keyword;
  final bool isMatch;

  KeywordMatch(this.keyword, this.isMatch);
}

class BuildCheckResults {
  final String deviceInfo;
  final List<String> vmKeywords;
  final List<String> bluestacksKeywords;
  final List<String> hardwareKeywords;
  final List<String> manufacturerKeywords;
  final List<KeywordMatch> vmMatches;
  final List<KeywordMatch> bluestacksMatches;
  final List<KeywordMatch> hardwareMatches;
  final List<KeywordMatch> manufacturerMatches;
  final Map<String, dynamic> checkResults;

  BuildCheckResults({
    required this.deviceInfo,
    required this.vmKeywords,
    required this.bluestacksKeywords,
    required this.hardwareKeywords,
    required this.manufacturerKeywords,
    required this.vmMatches,
    required this.bluestacksMatches,
    required this.hardwareMatches,
    required this.manufacturerMatches,
    required this.checkResults,
  });
}

class HardwareCheckResults {
  final List<String> cpuKeywords;
  final bool hasSensors;
  final Map<String, dynamic> checkResults;

  HardwareCheckResults({
    required this.cpuKeywords,
    required this.hasSensors,
    required this.checkResults,
  });
}
