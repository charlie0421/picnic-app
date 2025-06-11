# 위챗 로그인 재활성화 가이드

> **중요**: 이 문서는 긴급 배포를 위해 임시로 비활성화된 위챗 로그인 기능을 다시 활성화하기 위한 가이드입니다.

## 📋 재활성화 체크리스트

### 1. 의존성 복구

#### `picnic_lib/pubspec.yaml`
```yaml
# 현재 (비활성화된 상태):
# fluwx: ^5.5.4  # TODO: 위챗 로그인 임시 비활성화 - CI 에러 해결

# 복구할 내용:
fluwx: ^5.5.4
```

**작업**: 주석을 제거하고 의존성을 다시 활성화

### 2. Dart 코드 복구

#### `picnic_lib/lib/core/config/environment.dart`
```dart
// 현재 (비활성화된 상태):
// TODO: 위챗 로그인 임시 비활성화 - CI 에러 해결
// static String get wechatAppId =>
//     _getValue(['auth', 'wechat', 'app_id']) as String;
// static String get wechatAppSecret =>
//     _getValue(['auth', 'wechat', 'app_secret']) as String;
// static String get wechatUniversalLink =>
//     _getValue(['auth', 'wechat', 'universal_link']) as String;

// 복구할 내용:
static String get wechatAppId =>
    _getValue(['auth', 'wechat', 'app_id']) as String;
static String get wechatAppSecret =>
    _getValue(['auth', 'wechat', 'app_secret']) as String;
static String get wechatUniversalLink =>
    _getValue(['auth', 'wechat', 'universal_link']) as String;
```

#### `picnic_lib/lib/core/services/auth/social_login/wechat_login.dart`
**작업**: 
1. 파일 상단의 주석 블록(`/*` ~ `*/`) 제거
2. 임시 더미 클래스 제거
3. 원본 위챗 로그인 클래스 복구

### 3. Android 설정 복구

#### `picnic_app/android/app/src/main/AndroidManifest.xml`

**WeChat Entry Activity 복구**:
```xml
<!-- 현재 (비활성화된 상태): -->
<!-- WeChat Entry Activity - TODO: 위챗 로그인 임시 비활성화 -->
<!--
<activity
    android:name="com.jarvan.fluwx.wxapi.WXEntryActivity"
    android:exported="true"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
-->

<!-- 복구할 내용: -->
<!-- WeChat Entry Activity -->
<activity
    android:name="com.jarvan.fluwx.wxapi.WXEntryActivity"
    android:exported="true"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

**WeChat 패키지 쿼리 복구**:
```xml
<!-- 현재 (비활성화된 상태): -->
<!-- WeChat - TODO: 위챗 로그인 임시 비활성화 -->
<!-- <package android:name="com.tencent.mm" /> -->

<!-- 복구할 내용: -->
<!-- WeChat -->
<package android:name="com.tencent.mm" />
```

### 4. iOS 설정 복구

#### `picnic_app/ios/Runner/Info.plist`

**위챗 URL 스킴 복구**:
```xml
<!-- 현재 (비활성화된 상태): -->
<!-- <string>wxa5eea7ab9b3894a8</string> TODO: 위챗 로그인 임시 비활성화 -->

<!-- 복구할 내용: -->
<string>wxa5eea7ab9b3894a8</string>
```

**위챗 앱 쿼리 스킴 복구**:
```xml
<!-- 현재 (비활성화된 상태): -->
<!-- <string>weixin</string> TODO: 위챗 로그인 임시 비활성화 -->
<!-- <string>weixinULAPI</string> TODO: 위챗 로그인 임시 비활성화 -->

<!-- 복구할 내용: -->
<string>weixin</string>
<string>weixinULAPI</string>
```

## 🔍 재활성화 후 검증 단계

### 1. 기본 빌드 검증
```bash
# 1. 의존성 업데이트
cd picnic_lib
flutter clean
flutter pub get

cd ../picnic_app
flutter clean
flutter pub get

# 2. 정적 분석
flutter analyze

# 3. 빌드 테스트
flutter build apk --debug --target-platform android-arm64
```

### 2. 위챗 관련 기능 테스트
- [ ] 위챗 앱 설치 확인 기능 작동
- [ ] 위챗 로그인 플로우 정상 작동
- [ ] 위챗 로그인 후 사용자 정보 수신 확인
- [ ] 위챗 로그아웃 기능 작동

### 3. CI/CD 검증
- [ ] CI 파이프라인에서 위챗 SDK 관련 에러 해결 확인
- [ ] Android 빌드 성공
- [ ] iOS 빌드 성공
- [ ] 테스트 케이스 통과

## ⚠️ 주의사항

### CI 에러 해결 확인
재활성화 전에 **반드시 원본 CI 에러의 근본 원인을 파악하고 해결**해야 합니다:

1. **fluwx 패키지 관련 이슈**:
   - 패키지 버전 호환성 문제
   - 네이티브 SDK 의존성 문제
   - 빌드 환경 설정 문제

2. **WeChat SDK 관련 이슈**:
   - Android: WeChat SDK 버전 충돌
   - iOS: WechatOpenSDK-XCFramework 관련 문제

3. **환경 설정 이슈**:
   - WeChat App ID/Secret 설정 확인
   - Universal Link 설정 확인

### 롤백 계획
재활성화 후 문제가 발생할 경우를 대비한 롤백 계획:

1. **즉시 롤백 방법**:
   ```bash
   git checkout HEAD -- picnic_lib/pubspec.yaml
   git checkout HEAD -- picnic_lib/lib/core/config/environment.dart
   git checkout HEAD -- picnic_lib/lib/core/services/auth/social_login/wechat_login.dart
   git checkout HEAD -- picnic_app/android/app/src/main/AndroidManifest.xml
   git checkout HEAD -- picnic_app/ios/Runner/Info.plist
   ```

2. **의존성 재정리**:
   ```bash
   cd picnic_lib && flutter clean && flutter pub get
   cd ../picnic_app && flutter clean && flutter pub get
   ```

## 📝 재활성화 작업 순서

1. **사전 확인**
   - [ ] CI 에러 근본 원인 파악 및 해결
   - [ ] WeChat 개발자 계정 설정 확인
   - [ ] 테스트 환경 준비

2. **코드 복구**
   - [ ] `pubspec.yaml` 의존성 복구
   - [ ] `environment.dart` 설정 복구
   - [ ] `wechat_login.dart` 클래스 복구

3. **플랫폼 설정 복구**
   - [ ] Android 매니페스트 복구
   - [ ] iOS Info.plist 복구

4. **검증 및 테스트**
   - [ ] 빌드 테스트
   - [ ] 기능 테스트
   - [ ] CI/CD 테스트

5. **배포**
   - [ ] 스테이징 환경 배포
   - [ ] 프로덕션 배포

## 🔗 관련 리소스

- **WeChat Open Platform**: https://developers.weixin.qq.com/
- **Fluwx 패키지 문서**: https://pub.dev/packages/fluwx
- **WeChat SDK Android 가이드**: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/Android.html
- **WeChat SDK iOS 가이드**: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html

---

**작성일**: 2024년
**최종 수정**: 재활성화 시점에 맞춰 업데이트 필요
**작성자**: 개발팀 