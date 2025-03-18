# Pangle 라이브러리

Pangle SDK를 Flutter에서 사용하기 위한 라이브러리입니다.

## 설치 및 설정

### 1. 종속성 추가

`pubspec.yaml` 파일에 picnic_lib 종속성이 이미 추가되어 있어야 합니다.

### 2. 사용 방법

#### 초기화

앱 시작 시 Pangle SDK를 초기화해야 합니다:

```dart
import 'package:picnic_lib/picnic_lib.dart';

// 앱 시작 시 초기화
void initializeApp() async {
  // Pangle SDK 초기화 (앱 ID 필요)
  await PangleNative.initPangle('your_pangle_app_id');
}
```

#### 보상형 광고 로드 및 표시

```dart
import 'package:picnic_lib/picnic_lib.dart';

// 광고 로드
Future<void> loadAd() async {
  final bool isLoaded = await PangleNative.loadRewardedAd('your_placement_id');
  if (isLoaded) {
    print('광고 로드 성공');
  } else {
    print('광고 로드 실패');
  }
}

// 광고 표시
Future<void> showAd() async {
  final bool isRewarded = await PangleNative.showRewardedAd();
  if (isRewarded) {
    print('보상 지급 완료');
  } else {
    print('보상 지급 실패 또는 광고 시청 중단');
  }
}
```

## 주의사항

1. 실제 광고를 표시하기 전에 반드시 로드를 먼저 해야 합니다.
2. 네이티브 플랫폼(iOS/Android)별 설정이 추가로 필요할 수 있습니다. 