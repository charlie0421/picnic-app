# Pangle 커스텀 플러그인

Pangle SDK를 Flutter에서 사용하기 위한 커스텀 플러그인입니다.

## 설치 및 설정

### 1. 종속성 추가

`pubspec.yaml` 파일에 pangle_custom_plugin 종속성을 추가합니다:

```yaml
dependencies:
  pangle_custom_plugin:
    path: ../lib/pangle_custom_plugin
```

### 2. 네이티브 설정

#### iOS 설정

1. iOS 프로젝트에 Pangle SDK를 추가합니다. Podfile에 다음을 추가:

```ruby
# Pangle SDK source
source 'https://github.com/CocoaPods/Specs.git'

# Pangle SDK
pod 'Ads-Global'
```

2. Info.plist에 필요한 권한 설정 추가:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>광고 식별을 위해 앱 추적 권한이 필요합니다.</string>
```

3. 플러그인 등록을 위해 AppDelegate에 다음 코드를 추가:

```swift
import UIKit
import Flutter
import pangle_custom_plugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 플러그인 등록
    PangleNativeHandler.register(with: self.registrar(forPlugin: "PangleNativeHandler"))
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Android 설정

1. Android 프로젝트의 build.gradle에 다음을 추가:

```groovy
repositories {
    google()
    mavenCentral()
    maven {
        url "https://artifact.bytedance.com/repository/pangle"
    }
}

dependencies {
    implementation 'com.pangle.global:ads-sdk:x.y.z' // 최신 버전 사용
}
```

2. AndroidManifest.xml에 필요한 권한 추가:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

3. 플러그인 등록을 위해 MainActivity에 코드 추가:

```kotlin
package your.package.name

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import pangle.native.PangleNativeHandler

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // 플러그인 등록
    flutterEngine.plugins.add(PangleNativeHandler())
  }
}
```

### 3. 사용 방법

#### 초기화

앱 시작 시 Pangle SDK를 초기화해야 합니다:

```dart
import 'package:pangle_custom_plugin/pangle_custom_plugin.dart';

// 앱 시작 시 초기화
void initializeApp() async {
  // Pangle SDK 초기화 (앱 ID 필요)
  await PanglePlugin.initPangle('your_pangle_app_id');
}
```

#### 보상형 광고 로드 및 표시

```dart
import 'package:pangle_custom_plugin/pangle_custom_plugin.dart';

// 광고 로드
Future<void> loadAd() async {
  final bool isLoaded = await PanglePlugin.loadRewardedAd('your_placement_id');
  if (isLoaded) {
    print('광고 로드 성공');
  } else {
    print('광고 로드 실패');
  }
}

// 광고 표시
Future<void> showAd() async {
  final bool isRewarded = await PanglePlugin.showRewardedAd();
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
3. 프로덕션 환경에서는 실제 앱 ID와 광고 유닛 ID를 사용해야 합니다.

## 알려진 문제 해결

### 네이티브 코드의 Linter 오류

네이티브 코드를 통합할 때 다음과 같은 Linter 오류가 발생할 수 있습니다:

#### iOS (PangleNativeHandler.swift)
- `No such module 'UIKit'` 및 `No such module 'Flutter'` 오류

해결 방법: 이 코드는 Flutter 플러그인으로 동작하는 것이 의도된 것이므로, 실제 iOS 앱 프로젝트에 통합할 때는 Runner 타겟 내부에 파일을 추가해야 합니다. 독립 라이브러리에서는 참조용 코드로만 사용됩니다.

#### Android (PangleNativeHandler.kt)
- `Unresolved reference: bytedance`, `Unresolved reference: embedding` 등의 오류

해결 방법: Android Studio에서 해당 파일을 올바른 패키지 구조에 배치하고, 프로젝트의 build.gradle에 필요한 의존성(Pangle SDK)을 추가해야 합니다. 이 코드 역시 참조용으로, 실제 프로젝트에 통합할 때 올바른 패키지 경로에 배치해야 합니다. 