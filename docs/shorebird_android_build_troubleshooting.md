# Shorebird Android 빌드 트러블슈팅

> 2026-01-29 작성 | Codemagic CI/CD + Shorebird OTA

## 개요

Codemagic에서 `shorebird release android` 실행 시 발생한 일련의 빌드 오류와 해결 과정을 기록합니다.

---

## 오류 1: AGP 8.11.1 다운로드 실패

### 증상

```
> Task :gradle:compileKotlin FAILED
Could not download gradle-8.11.1.jar (com.android.tools.build:gradle:8.11.1)
Could not download builder-8.11.1.jar (com.android.tools.build:builder:8.11.1)
BUILD FAILED in 7m 45s
```

### 원인

- `codemagic.yaml`의 Codemagic 환경 Flutter 버전(`3.38.5`)과 Shorebird `--flutter-version`(`3.38.4`)이 불일치
- Flutter SDK 내부 Gradle 플러그인(`flutter_tools/gradle`)이 AGP 8.11.1을 요구했으나, 해당 버전이 Google Maven에 미게시

### 해결

`codemagic.yaml`의 모든 Flutter 버전을 `3.38.8`로 통일 (커밋: `427b337b`)

### 변경 파일

- `codemagic.yaml`: `environment.flutter`, `FLUTTER_VERSION`, `--flutter-version` 총 10곳 수정

---

## 오류 2: Shorebird Flutter 3.38.8 미지원

### 증상

```
Version 3.38.8 not found.
Use `shorebird flutter versions list` to list available versions.
```

### 원인

Shorebird 1.6.78이 지원하는 최신 Flutter 버전은 `3.38.7`이었으나, `--flutter-version=3.38.8`을 지정함

### 해결

Shorebird의 `--flutter-version`만 `3.38.7`로 변경 (커밋: `de77823a`)

Codemagic 환경 Flutter(`3.38.8`)와 Shorebird Flutter(`3.38.7`)는 분리 가능. `--flutter-version`은 Shorebird가 지원하는 버전만 사용해야 함.

### 변경 파일

- `codemagic.yaml`: `shorebird release ios --flutter-version=3.38.7`, `shorebird release android --flutter-version=3.38.7`

### 참고: Shorebird 지원 버전 확인 방법

```bash
shorebird flutter versions list
```

---

## 오류 3: flutter_app_badger namespace 미지정

### 증상

```
Namespace not specified. Specify a namespace in the module's build file:
/Users/builder/.pub-cache/hosted/pub.dev/flutter_app_badger-1.5.0/android/build.gradle
```

### 원인

- AGP 8+에서는 모든 Android 모듈에 `namespace` 선언 필수
- `flutter_app_badger` 1.5.0은 2022년 마지막 업데이트로, namespace를 지원하지 않음
- 패키지 최신 버전이 이미 1.5.0이라 업그레이드 불가

### 해결

`android/build.gradle`에 `subprojects` 블록 추가 (커밋: `b75aef03`)

```groovy
// AGP 8+ namespace 미지원 플러그인 호환성 처리
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            def android = project.android
            if (android.namespace == null || android.namespace.isEmpty()) {
                def manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    def pkg = new groovy.util.XmlSlurper()
                        .parse(manifest)
                        .@package.toString()
                    if (pkg) {
                        android.namespace = pkg
                    }
                }
            }
        }
    }
}
```

이 코드는 namespace가 없는 서브프로젝트에서 `AndroidManifest.xml`의 `package` 속성을 읽어 자동 주입합니다. `flutter_app_badger` 외 다른 레거시 플러그인에서도 동일 문제 발생 시 자동 처리됩니다.

### 변경 파일

- `picnic_app/android/build.gradle`

---

## 오류 4: Shorebird 릴리즈 Flutter 리비전 충돌

### 증상

```
A release with version 1.2.22+122202 already exists but was built using a different Flutter revision.

  Existing release built with: 3.38.4 (9b27542c6b)
  Current release built with: 3.38.7 (1102488790)

All platforms for a given release must be built using the same Flutter revision.
```

### 원인

- 이전에 iOS 릴리즈가 Flutter 3.38.4로 Shorebird에 등록됨
- Android 릴리즈를 Flutter 3.38.7로 시도하니, 동일 버전의 릴리즈에서 플랫폼 간 Flutter 리비전이 다르므로 거부됨

### 해결 방법 (택 1)

1. **Shorebird Console에서 기존 릴리즈 삭제 후 재빌드** (선택됨)
   - [console.shorebird.dev](https://console.shorebird.dev) 접속
   - 앱 ID: `571d432c-155d-4f6e-b74f-2ecef3e6f680`
   - 버전 `1.2.22+122202` 릴리즈 삭제
   - iOS/Android 모두 3.38.7로 재빌드

2. 기존 iOS 릴리즈에 맞춰 `--flutter-version=3.38.4` 사용

3. `pubspec.yaml` 버전 번호를 올려서 새 릴리즈 생성

### 주의사항

- Shorebird는 동일 앱 버전의 모든 플랫폼을 같은 Flutter 리비전으로 빌드해야 함
- iOS와 Android 빌드를 동시에 트리거하거나, 같은 `--flutter-version`을 사용해야 함

---

## 버전 관리 요약

| 설정 | 값 | 비고 |
|------|-----|------|
| Codemagic Flutter 환경 | `3.38.8` | Codemagic이 설치하는 Flutter |
| Shorebird `--flutter-version` | `3.38.7` | Shorebird가 지원하는 최신 버전 |
| AGP (settings.gradle) | `8.9.1` | Android Gradle Plugin |
| Kotlin | `2.1.0` | |
| Shorebird CLI | `1.6.78` | |

### Codemagic vs Shorebird Flutter 버전이 다른 이유

- Codemagic `environment.flutter`는 Flutter CLI 도구 및 fallback 빌드에 사용
- `shorebird release --flutter-version`은 Shorebird 내부에서 별도의 Flutter를 사용
- Shorebird는 자체 포크된 Flutter를 사용하므로, 지원 버전 목록이 공식 Flutter와 다를 수 있음
- `shorebird flutter versions list`로 지원 버전 확인 필수
