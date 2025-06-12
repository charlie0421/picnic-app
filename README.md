# Picnic App

## 개발 설정

### 가상머신 체크 비활성화

개발 중에 가상머신 체크로 인한 문제가 발생할 경우, 다음 방법들로 비활성화할 수 있습니다:

#### 1. 환경변수 사용 (권장)
```bash
# Flutter 실행 시 환경변수 설정
flutter run --dart-define=DISABLE_VM_CHECK=true

# 또는
flutter run --dart-define=NO_VM_CHECK=true

# 또는  
flutter run --dart-define=SKIP_VM_CHECK=true
```

#### 2. 디버그 모드에서 자동 비활성화
- 디버그 모드에서는 기본적으로 가상머신 체크가 비활성화됩니다.

#### 3. 개별 체크 비활성화
`picnic_lib/lib/core/utils/virtual_machine_detector.dart` 파일의 `VMDetectionConfig` 클래스에서 개별 체크를 비활성화할 수 있습니다:

```dart
class VMDetectionConfig {
  static const bool enableBuildCheck = false;        // 빌드 정보 체크 비활성화
  static const bool enableHardwareCheck = false;     // 하드웨어 체크 비활성화
  static const bool enableNetworkCheck = false;      // 네트워크 체크 비활성화 (기본값)
  static const bool enableSamsungStrictCheck = false; // 삼성 기기 엄격 체크 비활성화 (기본값)
  static const bool enableSentryReport = false;      // Sentry 리포트 비활성화
}
```

#### 가상머신 체크 항목
현재 다음 항목들을 체크합니다:

1. **Build 정보 체크** (기본 활성화)
   - 가상머신 관련 키워드 검사
   - 블루스택스 관련 키워드 검사  
   - 의심스러운 하드웨어/제조사 키워드 검사

2. **하드웨어 체크** (기본 활성화)
   - CPU 정보에서 가상화 관련 키워드 검사
   - 센서 존재 여부 확인

3. **네트워크 체크** (기본 비활성화 - 오탐 많음)
   - TTL 값 검사
   - MAC 주소 패턴 검사

4. **삼성 기기 엄격 체크** (기본 비활성화 - 오탐 많음)
   - Knox 보안 기능 확인
   - 부트로더 정보 확인

#### 문제 해결
- 정상 기기가 가상머신으로 잘못 감지되는 경우, `enableNetworkCheck`와 `enableSamsungStrictCheck`를 `false`로 설정하세요.
- 개발 중에는 환경변수를 사용한 전체 비활성화를 권장합니다. 