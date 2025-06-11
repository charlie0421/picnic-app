# 위챗 로그인 재활성화 체크리스트

## ✅ 사전 확인
- [ ] CI 에러 근본 원인 해결 완료
- [ ] WeChat 개발자 계정 설정 확인

## 🔧 코드 복구 작업

### 의존성 복구
- [ ] `picnic_lib/pubspec.yaml` - `fluwx: ^5.5.4` 주석 제거

### Dart 코드 복구
- [ ] `picnic_lib/lib/core/config/environment.dart` - WeChat 설정 주석 제거
- [ ] `picnic_lib/lib/core/services/auth/social_login/wechat_login.dart` - 원본 클래스 복구

### Android 설정 복구
- [ ] `picnic_app/android/app/src/main/AndroidManifest.xml`
  - [ ] WeChat Entry Activity 주석 제거
  - [ ] WeChat 패키지 쿼리 주석 제거

### iOS 설정 복구
- [ ] `picnic_app/ios/Runner/Info.plist`
  - [ ] 위챗 URL 스킴 주석 제거 (`wxa5eea7ab9b3894a8`)
  - [ ] 위챗 앱 쿼리 스킴 주석 제거 (`weixin`, `weixinULAPI`)

## 🧪 검증 단계

### 빌드 테스트
- [ ] `cd picnic_lib && flutter clean && flutter pub get`
- [ ] `cd picnic_app && flutter clean && flutter pub get`
- [ ] `flutter analyze` - 에러 없음 확인
- [ ] `flutter build apk --debug` - 빌드 성공 확인

### 기능 테스트
- [ ] 위챗 앱 설치 확인 기능 작동
- [ ] 위챗 로그인 플로우 정상 작동
- [ ] 위챗 로그인 후 사용자 정보 수신 확인
- [ ] 위챗 로그아웃 기능 작동

### CI/CD 검증
- [ ] CI 파이프라인 통과
- [ ] Android 빌드 성공
- [ ] iOS 빌드 성공

## 🚨 롤백 명령어 (문제 발생시)
```bash
git checkout HEAD -- picnic_lib/pubspec.yaml
git checkout HEAD -- picnic_lib/lib/core/config/environment.dart
git checkout HEAD -- picnic_lib/lib/core/services/auth/social_login/wechat_login.dart
git checkout HEAD -- picnic_app/android/app/src/main/AndroidManifest.xml
git checkout HEAD -- picnic_app/ios/Runner/Info.plist
cd picnic_lib && flutter clean && flutter pub get
cd ../picnic_app && flutter clean && flutter pub get
```

---
**재활성화 작업자**: ________________  
**작업 일시**: ________________  
**검증 완료**: ________________ 