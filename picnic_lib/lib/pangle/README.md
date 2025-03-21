# Pangle 라이브러리

Pangle SDK를 Flutter에서 사용하기 위한 라이브러리입니다.

## 설치 및 설정

### 1. 종속성 추가

`pubspec.yaml` 파일에 picnic_lib 종속성이 이미 추가되어 있어야 합니다.

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
import picnic_lib

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
import io.iconcasting.picnic.lib.pangle.native.PangleNativeHandler

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
import 'package:picnic_lib/picnic_lib.dart';

// 앱 시작 시 초기화
void initializeApp() async {
  // Pangle SDK 초기화 (앱 ID 필요)
  await PanglePlugin.initPangle('your_pangle_app_id');
}
```

#### 보상형 광고 로드 및 표시

```dart
import 'package:picnic_lib/picnic_lib.dart';

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