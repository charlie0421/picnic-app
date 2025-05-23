ㅣl# 앱 초기화 및 공통 유틸리티 클래스

이 디렉토리에는 `picnic_app`과 `ttja_app` 간의 코드 중복을 제거하기 위한 공통 유틸리티 클래스들이 포함되어 있습니다.

## 주요 유틸리티 클래스

### 1. MainInitializer

`main.dart` 파일의 공통 초기화 로직을 통합한 클래스입니다.

#### 사용 방법:

```dart
// main.dart 파일에서 사용 예시
import 'package:picnic_lib/core/utils/main_initializer.dart';

void main() async {
  await MainInitializer.initializeApp(
    environment: 'prod',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appBuilder: () => const App(),
    loadGeneratedTranslations: S.load,
    reflectableInitializer: initializeReflectable,
    enableMemoryProfiler: kDebugMode,
  );
}
```

### 2. LanguageInitializer

언어 초기화 및 변경 관련 로직을 통합한 클래스입니다.

#### 사용 방법:

```dart
// 언어 초기화 (앱 시작 시)
await MainInitializer.initializeLanguageAsync(
  ref,
  context,
  S.load,
  (success, language) {
    // 초기화 완료 후 처리
    setState(() {
      _isLanguageInitialized = success;
      _currentLanguage = language;
    });
  },
);

// 언어 변경 (사용자 요청 시)
final success = await LanguageInitializer.changeLanguage(
  ref,
  'ko', // 변경할 언어 코드
  S.load,
);
```

### 3. AppLifecycleInitializer

앱 생명주기 관리 및 초기화 로직을 통합한 클래스입니다.

#### 사용 방법:

```dart
// initState 내부에서 사용
@override
void initState() {
  super.initState();
  
  // 앱 초기화 및 리스너 설정
  AppLifecycleInitializer.setupAppInitializers(ref, context);
  
  // 라우트 설정
  AppLifecycleInitializer.setupAppRoutes(ref, _routes);
  
  // 초기화 완료 표시
  AppLifecycleInitializer.markAppInitialized(ref);
}

// dispose 내부에서 사용
@override
void dispose() {
  // 리스너 정리
  AppLifecycleInitializer.disposeAppListeners(_authSubscription, _appLinksSubscription);
  super.dispose();
}
```

## 마이그레이션 가이드

### 기존 앱 코드 변경 방법

1. `main.dart` 파일의 초기화 로직을 `MainInitializer` 사용으로 대체
2. 언어 관련 로직을 `LanguageInitializer` 사용으로 대체
3. 앱 생명주기 관리 로직을 `AppLifecycleInitializer` 사용으로 대체

### 예시:

**변경 전:**
```dart
// main.dart
void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // ... 기존 초기화 코드
    runApp(
      ProviderScope(
        observers: [LoggingObserver()],
        child: const App(),
      ),
    );
  }, (error, stack) async {
    // ... 오류 처리
  });
}
```

**변경 후:**
```dart
// main.dart
void main() async {
  await MainInitializer.initializeApp(
    environment: 'prod',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appBuilder: () => const App(),
    loadGeneratedTranslations: S.load,
    reflectableInitializer: initializeReflectable,
  );
}
```

## 참고사항

- 기본 언어는 한국어(`ko`)로 설정되어 있습니다.
- 복잡한 초기화 로직은 각 클래스 내부에 캡슐화되어 있습니다.
- 각 클래스에는 상세한 주석과 로그가 포함되어 있어 디버깅이 용이합니다.
- 모든 유틸리티 클래스는 테스트되어 안정성이 검증되었습니다.
