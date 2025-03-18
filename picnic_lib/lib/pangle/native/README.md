# Pangle 네이티브 구현

이 디렉토리는 iOS 및 Android 플랫폼에서 Pangle SDK를 연동하기 위한 네이티브 코드를 포함하고 있습니다.

## 구조

- `pangle_native.dart` - Dart 측에서 네이티브 코드를 호출하기 위한 인터페이스
- `pangle_plugin.dart` - Flutter 플러그인 인터페이스
- `ios/` - iOS 네이티브 구현
  - `PangleNativeHandler.swift` - iOS 플랫폼 구현
- `android/` - Android 네이티브 구현
  - `PangleNativeHandler.kt` - Android 플랫폼 구현

## 네이티브 코드 통합 방법

### iOS 통합

1. `PangleNativeHandler.swift` 파일을 iOS 프로젝트의 Runner 폴더에 복사합니다.
2. Podfile에 Pangle SDK 의존성을 추가합니다:

```ruby
pod 'Ads-Global'
```

3. AppDelegate에서 플러그인을 등록합니다:

```swift
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

### Android 통합

1. `PangleNativeHandler.kt` 파일을 Android 프로젝트의 적절한 패키지 폴더에 복사합니다.
2. app/build.gradle에 Pangle SDK 의존성을 추가합니다:

```groovy
repositories {
    maven { url "https://artifact.bytedance.com/repository/pangle" }
}

dependencies {
    implementation 'com.pangle.global:ads-sdk:x.y.z' // 최신 버전 사용
}
```

3. MainActivity에서 플러그인을 등록합니다:

```kotlin
import io.iconcasting.picnic.lib.pangle.native.PangleNativeHandler

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // 플러그인 등록
    flutterEngine.plugins.add(PangleNativeHandler())
  }
}
```

## 주의사항

1. iOS와 Android 플랫폼 모두에서 Pangle SDK가 올바르게 초기화되었는지 확인하세요.
2. 광고 표시 전에 반드시 광고를 로드해야 합니다.
3. 네이티브 코드 디버깅 시 각 플랫폼의 로그를 확인하세요.
4. Pangle SDK 버전이 플랫폼 간에 호환되는지 확인하세요. 