# 📱 Android Shorebird 릴리즈 설정 가이드

## 🎯 개요

Codemagic에서 Android Shorebird 릴리즈가 작동하도록 새로운 워크플로우를 추가했습니다. 이제 Android 앱도 iOS와 같이 즉시 패치를 배포할 수 있습니다.

## 🔧 추가된 워크플로우

### 1. `picnic-app-patch-android` (Android 패치 전용)
- **트리거**: `picnic-patch-*` 태그
- **용도**: Android 전용 Shorebird 패치 배포
- **소요 시간**: 30-60분
- **배포**: Shorebird 패치만

### 2. `picnic-app-android-with-shorebird` (통합 릴리즈)
- **트리거**: `picnic-android-v*` 태그  
- **용도**: Google Play + Shorebird 동시 릴리즈
- **소요 시간**: 60-120분
- **배포**: Google Play + Shorebird 릴리즈

### 3. `picnic-app-android` (기존 워크플로우 개선)
- **트리거**: `picnic-v*` 태그
- **용도**: 표준 Flutter 빌드 + 선택적 Shorebird 릴리즈
- **소요 시간**: 60-120분
- **배포**: Google Play + 선택적 Shorebird

## 🚀 사용법

### Android 패치 배포 (빠른 수정)
```bash
# 1. 코드 수정 후 커밋
git add .
git commit -m "fix: 버그 수정"

# 2. 패치 태그 생성
git tag picnic-patch-android-v1.1.42
git push origin picnic-patch-android-v1.1.42
```

### Android 전체 릴리즈 (새 버전)
```bash
# 1. 새 버전 코드 준비 후 태그 생성
git tag picnic-android-v1.2.0
git push origin picnic-android-v1.2.0
```

### 기존 방식으로 Android 릴리즈
```bash
# 기존 패턴 그대로 사용
git tag picnic-v1.2.0
git push origin picnic-v1.2.0
```

## ⚙️ 필수 설정

### CodeMagic 대시보드 설정

1. **Environment Variables 그룹 생성**:
   - `shorebird-config` 그룹에 `SHOREBIRD_TOKEN` 추가

2. **Android Signing 설정**:
   - `picnic_keystore` 키스토어 업로드
   - CM_KEYSTORE_PATH, CM_KEY_ALIAS 등 자동 설정됨

3. **Google Play 설정**:
   - `google_play` 그룹에 서비스 계정 설정

### Shorebird Token 발급
```bash
# 로컬에서 Shorebird 인증
shorebird login

# 토큰 생성 (CodeMagic용)
shorebird token create --expires-in 365d --name "codemagic-android"
```

## 🔍 문제 해결

### 1. "SHOREBIRD_TOKEN이 설정되지 않음"
- CodeMagic 대시보드에서 `shorebird-config` 그룹에 토큰 추가
- Environment Variables > Groups > shorebird-config

### 2. "기존 릴리즈가 없음" 에러
```bash
# 먼저 전체 릴리즈 실행 필요
git tag picnic-android-v1.1.0
git push origin picnic-android-v1.1.0

# 이후 패치 가능
git tag picnic-patch-android-v1.1.1
git push origin picnic-patch-android-v1.1.1
```

### 3. 키스토어 서명 오류
- CodeMagic > Settings > Code signing > Android
- `picnic_keystore` 업로드 확인
- 키 별칭과 비밀번호 정확성 확인

### 4. 네이티브 코드 변경으로 패치 실패
```
❌ Shorebird 패치는 Dart 코드만 지원합니다
✅ 해결: 전체 릴리즈 워크플로우 사용 필요
```

## 📊 워크플로우 비교

| 워크플로우 | 트리거 | Google Play | Shorebird | 소요시간 |
|------------|--------|-------------|-----------|----------|
| `picnic-app-android` | `picnic-v*` | ✅ | 선택적 | 60-120분 |
| `picnic-app-android-with-shorebird` | `picnic-android-v*` | ✅ | ✅ | 60-120분 |
| `picnic-app-patch-android` | `picnic-patch-*` | ❌ | ✅ | 30-60분 |

## 🎯 권장 워크플로우

### 일반 개발 사이클
1. **개발 완료**: `picnic-v*` (기존 방식)
2. **빠른 수정**: `picnic-patch-*` (패치만)
3. **Android 전용**: `picnic-android-v*` (새로운 통합)

### 예시 시나리오
```bash
# 1. 새 버전 릴리즈 (v1.2.0)
git tag picnic-v1.2.0
git push origin picnic-v1.2.0

# 2. 버그 발견 후 즉시 패치 (v1.2.1)  
git tag picnic-patch-android-v1.2.1
git push origin picnic-patch-android-v1.2.1

# 3. 또 다른 수정 (v1.2.2)
git tag picnic-patch-android-v1.2.2
git push origin picnic-patch-android-v1.2.2
```

## 📱 최종 결과

### Android 릴리즈 성공 시
- ✅ AAB 파일이 Google Play에 업로드됨
- ✅ Shorebird 릴리즈가 등록됨
- ✅ 향후 패치 배포 가능

### Android 패치 성공 시
- ✅ 사용자가 앱 재시작 시 자동 패치 적용
- ✅ 스토어 리뷰 없이 즉시 배포
- ✅ 30-60분 내 전 세계 배포 완료

## 🔗 관련 문서

- [BRANCH_WORKFLOW.md](./BRANCH_WORKFLOW.md) - 브랜치 관리 가이드
- [Shorebird 공식 문서](https://docs.shorebird.dev/)
- [CodeMagic Android 설정](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)

---

**이제 Android도 iOS와 동일하게 즉시 패치 배포가 가능합니다! 🎉** 