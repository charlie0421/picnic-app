# Design: Flutter Test Comprehensive

> picnic-app 테스트 전면 보완 상세 설계
> Plan 참조: `docs/01-plan/features/flutter-test-comprehensive.plan.md`

## 1. 테스트 디렉토리 구조 설계

```
picnic_lib/test/
├── helpers/                          # 공통 테스트 인프라
│   ├── test_app.dart                 # 테스트용 앱 래퍼 (ProviderScope + MaterialApp)
│   ├── mock_supabase.dart            # Mock SupabaseClient 팩토리
│   ├── fixtures/                     # JSON fixture 데이터
│   │   ├── fixture_loader.dart       # Fixture 로드 유틸리티
│   │   ├── vote_fixtures.json        # 투표 관련 fixture
│   │   ├── artist_fixtures.json      # 아티스트 fixture
│   │   └── user_fixtures.json        # 사용자 fixture
│   ├── factories/                    # 모델 팩토리 (테스트 객체 생성)
│   │   ├── vote_factory.dart         # VoteModel, VoteItemRequest 팩토리
│   │   ├── artist_factory.dart       # ArtistModel 팩토리
│   │   └── user_factory.dart         # UserProfilesModel 팩토리
│   └── mocks/                        # Mock 클래스 모음
│       ├── mock_services.dart        # AuthService, StorageService 등 Mock
│       ├── mock_repositories.dart    # Repository Mock
│       └── mock_providers.dart       # Riverpod Provider override 헬퍼
│
├── core/
│   ├── errors/                       # [신규] 예외 클래스 테스트
│   │   ├── auth_exception_test.dart
│   │   └── vote_request_exceptions_test.dart
│   ├── services/
│   │   ├── search_service_test.dart  # [기존]
│   │   ├── auth_service_test.dart    # [신규]
│   │   ├── network_connectivity_service_test.dart  # [신규]
│   │   ├── secure_storage_service_test.dart         # [신규]
│   │   ├── youtube_service_test.dart                # [신규]
│   │   └── search_cache_service_test.dart           # [신규]
│   └── utils/
│       ├── korean_search_utils_test.dart    # [기존]
│       ├── app_lifecycle_initializer_test.dart  # [기존]
│       ├── language_initializer_test.dart       # [기존]
│       ├── main_initializer_test.dart           # [기존]
│       ├── token_refresh_manager_test.dart      # [신규]
│       ├── deeplink_test.dart                   # [신규]
│       ├── math_test.dart                       # [신규]
│       ├── network_test.dart                    # [신규]
│       ├── common_utils_test.dart               # [신규]
│       └── privacy_consent_manager_test.dart    # [신규]
│
├── data/
│   ├── models/
│   │   ├── vote/
│   │   │   └── vote_item_request_test.dart  # [기존]
│   │   ├── vote_model_test.dart             # [신규] Freezed 모델 테스트
│   │   ├── artist_model_test.dart           # [신규]
│   │   ├── auth_token_info_test.dart        # [신규]
│   │   └── navigation_models_test.dart      # [신규]
│   ├── repositories/
│   │   ├── vote_item_request_repository_test.dart  # [기존 빈파일 → 구현]
│   │   ├── qa_repository_test.dart                 # [신규]
│   │   ├── qna_repository_test.dart                # [신규]
│   │   └── popup_repository_test.dart              # [신규]
│   └── storage/
│       ├── local_storage_test.dart                 # [신규]
│       └── supabase_pkce_storage_test.dart         # [신규]
│
├── services/
│   └── vote_status_validation_service_test.dart    # [신규]
│
├── presentation/
│   ├── providers/
│   │   ├── user_info_provider_test.dart            # [신규]
│   │   ├── popup_provider_test.dart                # [신규]
│   │   └── gallery_list_provider_test.dart         # [신규]
│   └── widgets/
│       ├── ui/
│       │   ├── loading_overlay_test.dart           # [기존]
│       │   ├── loading_overlay_advanced_test.dart  # [기존]
│       │   └── (기존 테스트 유지)
│       ├── vote/
│       │   ├── vote_card_skeleton_test.dart        # [신규]
│       │   └── vote_item_request_widgets_test.dart # [신규]
│       └── common/
│           ├── common_search_box_test.dart         # [신규]
│           └── custom_pagination_test.dart         # [신규]
│
├── performance/                       # [기존 유지]
│   ├── image_loading_performance_test.dart
│   └── loading_overlay_with_icon_performance_test.dart
│
picnic_app/
├── test/
│   └── widget_test.dart               # [기존 유지]
├── integration_test/                  # [신규] e2e 테스트
│   ├── app_test.dart                  # 메인 통합 테스트 진입점
│   ├── helpers/
│   │   ├── test_app_setup.dart        # 통합 테스트용 앱 초기화
│   │   └── mock_supabase_server.dart  # Mock Supabase 응답
│   ├── flows/
│   │   ├── app_launch_test.dart       # 앱 시작 → 메인 화면
│   │   ├── login_flow_test.dart       # 로그인 플로우
│   │   ├── vote_flow_test.dart        # 투표 플로우
│   │   ├── search_flow_test.dart      # 검색 플로우
│   │   └── mypage_flow_test.dart      # 마이페이지 플로우
│   └── robots/                        # Robot 패턴 (Page Object)
│       ├── login_robot.dart
│       ├── vote_robot.dart
│       └── search_robot.dart
```

## 2. 테스트 인프라 상세 설계

### 2.1 테스트 앱 래퍼 (`test/helpers/test_app.dart`)

```dart
/// 모든 위젯/프로바이더 테스트에서 사용할 공통 래퍼
///
/// 사용법:
///   await tester.pumpWidget(
///     TestApp(
///       overrides: [myProvider.overrideWithValue(mockValue)],
///       child: MyWidget(),
///     ),
///   );
class TestApp extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;
  final Locale locale;

  const TestApp({
    required this.child,
    this.overrides = const [],
    this.locale = const Locale('ko'),
  });

  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: [...],
        home: Scaffold(body: child),
      ),
    );
  }
}
```

### 2.2 Mock Supabase Client (`test/helpers/mock_supabase.dart`)

```dart
/// Supabase 쿼리 체인을 Mock하는 헬퍼
///
/// Repository 테스트에서 실제 DB 호출 없이 쿼리 결과를 제어
///
/// 설계 의도:
///   - PostgrestFilterBuilder 체인(.select().eq().order())을 시뮬레이션
///   - 각 테스트에서 원하는 응답 데이터를 주입 가능
///   - 에러 시나리오(네트워크 오류, 빈 결과 등) 테스트 지원
///
/// 사용법:
///   final mockClient = MockSupabaseClient();
///   when(mockClient.from('votes').select())
///       .thenAnswer((_) async => testVoteData);
///
///   final repo = VoteItemRequestRepository(supabase: mockClient);
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
```

### 2.3 모델 팩토리 패턴 (`test/helpers/factories/`)

```dart
/// Freezed 모델의 테스트 인스턴스를 간편하게 생성
///
/// 설계 의도:
///   - 각 테스트에서 반복되는 모델 생성 코드 제거
///   - copyWith()로 특정 필드만 변경하여 변형 생성
///   - 일관된 테스트 데이터 유지
///
/// 사용법:
///   final vote = VoteFactory.create();
///   final customVote = VoteFactory.create(title: {'ko': '커스텀'});
class VoteFactory {
  static VoteModel create({
    int id = 1,
    Map<String, dynamic>? title,
    String status = 'active',
    ...
  }) => VoteModel(
    id: id,
    title: title ?? {'ko': '테스트 투표', 'en': 'Test Vote'},
    status: status,
    ...
  );

  /// JSON fixture에서 생성
  static VoteModel fromFixture(String name) {
    final json = FixtureLoader.load('vote_fixtures.json', name);
    return VoteModel.fromJson(json);
  }
}
```

### 2.4 Fixture 로더 (`test/helpers/fixtures/fixture_loader.dart`)

```dart
/// JSON 파일에서 테스트 데이터를 로드
///
/// 설계 의도:
///   - 실제 API 응답 형태의 테스트 데이터 관리
///   - 테스트 코드에서 대량의 JSON 리터럴 제거
///   - Supabase 응답 구조를 정확히 재현
class FixtureLoader {
  static Map<String, dynamic> load(String fileName, String key) {
    final file = File('test/helpers/fixtures/$fileName');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return data[key] as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> loadList(String fileName, String key) {
    final file = File('test/helpers/fixtures/$fileName');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return (data[key] as List).cast<Map<String, dynamic>>();
  }
}
```

## 3. 유닛 테스트 설계

### 3.1 테스트 우선순위 분류

| 우선도 | 대상 | 테스트 난이도 | 이유 |
|--------|------|--------------|------|
| **P0** | VoteStatusValidationService | 쉬움 | 순수 함수, 핵심 비즈니스 로직 |
| **P0** | Freezed 모델 (data/models/) | 쉬움 | fromJson/toJson, 계산 속성 |
| **P0** | core/errors/ | 쉬움 | 예외 생성/메시지 검증 |
| **P0** | core/utils/ (순수 함수) | 쉬움 | math, network, common_utils |
| **P1** | TokenRefreshManager | 중간 | AuthService Mock 필요 |
| **P1** | SecureStorageService | 중간 | FlutterSecureStorage Mock |
| **P1** | SearchCacheService | 중간 | 캐시 동작 검증 |
| **P2** | Repositories | 어려움 | SupabaseClient Mock 체인 |
| **P2** | AuthService | 어려움 | 다중 의존성, 복잡한 상태 |
| **P2** | Riverpod Providers | 어려움 | ProviderContainer + 비동기 |

### 3.2 레이어별 테스트 패턴

#### Freezed 모델 테스트 패턴
```dart
group('VoteModel', () {
  late Map<String, dynamic> testJson;

  setUp(() {
    testJson = FixtureLoader.load('vote_fixtures.json', 'basic');
  });

  test('fromJson이 올바르게 파싱한다', () {
    final model = VoteModel.fromJson(testJson);
    expect(model.id, equals(1));
    expect(model.title, containsPair('ko', '테스트'));
  });

  test('toJson이 원본 JSON과 일치한다', () {
    final model = VoteModel.fromJson(testJson);
    expect(model.toJson(), equals(testJson));
  });

  test('copyWith이 지정된 필드만 변경한다', () {
    final model = VoteFactory.create();
    final modified = model.copyWith(status: 'ended');
    expect(modified.status, equals('ended'));
    expect(modified.id, equals(model.id));
  });

  test('계산 속성이 올바르게 동작한다', () {
    // cardStatus, formattedName, isDeleted 등
    final deleted = VoteFactory.create(deletedAt: DateTime.now());
    expect(deleted.isDeleted, isTrue);
  });

  test('동일 데이터의 두 인스턴스가 같다', () {
    final a = VoteFactory.create();
    final b = VoteFactory.create();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
});
```

#### 순수 서비스 테스트 패턴 (VoteStatusValidationService)
```dart
group('VoteStatusValidationService', () {
  late VoteStatusValidationService service;

  setUp(() {
    service = VoteStatusValidationService();
  });

  group('validateVoteStatus', () {
    test('진행 중인 투표는 valid를 반환한다', () {
      final vote = VoteFactory.create(
        startAt: DateTime.now().subtract(Duration(hours: 1)),
        endAt: DateTime.now().add(Duration(hours: 1)),
      );
      final result = service.validateVoteStatus(
        vote,
        currentTime: DateTime.now(),
      );
      expect(result, isTrue);
    });

    test('종료된 투표는 invalid를 반환한다', () {
      // ...
    });
  });
});
```

#### Repository 테스트 패턴 (Mock Supabase)
```dart
group('VoteItemRequestRepository', () {
  late MockSupabaseClient mockClient;
  late VoteItemRequestRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    repo = VoteItemRequestRepository(supabase: mockClient);
  });

  test('fetchRequests가 올바른 테이블을 쿼리한다', () async {
    // Arrange: Mock Supabase 쿼리 체인 설정
    final mockQuery = MockSupabaseQueryBuilder();
    when(mockClient.from('vote_item_requests')).thenReturn(mockQuery);
    when(mockQuery.select(any)).thenAnswer((_) async => [testJson]);

    // Act
    final result = await repo.fetchRequests(voteId: 1);

    // Assert
    verify(mockClient.from('vote_item_requests')).called(1);
    expect(result, isNotEmpty);
  });

  test('에러 시 VoteRequestException을 던진다', () async {
    when(mockClient.from(any)).thenThrow(PostgrestException(message: 'error'));
    expect(() => repo.fetchRequests(voteId: 1), throwsA(isA<VoteRequestException>()));
  });
});
```

## 4. e2e 테스트 아키텍처 설계

### 4.1 프레임워크 선택

**Flutter `integration_test` 패키지 (기본)**
- Flutter SDK 기본 제공, 추가 의존성 최소
- `WidgetTester` API와 동일하여 학습 비용 없음
- CI에서 headless 실행 가능

### 4.2 Robot 패턴 (Page Object)

```dart
/// 각 화면의 조작을 캡슐화하는 Robot 클래스
///
/// 설계 의도:
///   - 테스트 코드에서 UI 구조 상세 분리
///   - UI 변경 시 Robot만 수정하면 됨
///   - 테스트 가독성 향상
///
/// 사용법:
///   final loginRobot = LoginRobot(tester);
///   await loginRobot.tapKakaoLogin();
///   await loginRobot.verifyMainScreenVisible();
class LoginRobot {
  final WidgetTester tester;
  LoginRobot(this.tester);

  Future<void> tapKakaoLogin() async {
    await tester.tap(find.byKey(Key('kakao_login_button')));
    await tester.pumpAndSettle();
  }

  Future<void> verifyMainScreenVisible() async {
    expect(find.byType(MainPortalScreen), findsOneWidget);
  }
}
```

### 4.3 e2e 테스트 환경 구성

```dart
/// 통합 테스트 앱 셋업
///
/// 실제 Supabase 대신 Mock 응답을 사용하여
/// 네트워크 의존 없이 e2e 테스트 가능
class TestAppSetup {
  static Future<void> initialize() async {
    // Mock Supabase 초기화 (실제 서버 호출 차단)
    // 테스트 계정/데이터 설정
    // 네이티브 플러그인 Mock (카메라, 갤러리 등)
  }

  static Widget createTestApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        // Supabase client를 Mock으로 교체
        ...overrides,
      ],
      child: const App(),
    );
  }
}
```

### 4.4 핵심 e2e 시나리오

| # | 시나리오 | 검증 포인트 | Mock 범위 |
|---|---------|------------|-----------|
| 1 | 앱 시작 → 메인 화면 | 스플래시 표시, 초기화 완료, 포탈 전환 | Supabase auth, 설정 |
| 2 | 로그인 플로우 | 소셜 로그인 버튼, 인증 콜백, 세션 저장 | SocialLogin providers |
| 3 | 투표 플로우 | 투표 목록 로드, 투표 실행, 결과 표시 | 투표 API 응답 |
| 4 | 검색 플로우 | 검색창 입력, 결과 표시, 한글 초성 검색 | 검색 API 응답 |
| 5 | 마이페이지 | 프로필 표시, 설정 변경 | 사용자 프로필 API |

## 5. 커버리지 측정 설계

### 5.1 커버리지 스크립트 (`scripts/run_tests.sh`)

```bash
#!/bin/bash
# picnic_lib 테스트 실행 및 커버리지 측정

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$PROJECT_DIR/picnic_lib"

echo "=== Running picnic_lib tests with coverage ==="
cd "$LIB_DIR"

# 테스트 실행 + 커버리지
flutter test --coverage

# 생성 파일 제외 (lcov)
lcov --remove coverage/lcov.info \
  '**/*.g.dart' \
  '**/*.freezed.dart' \
  '**/generated/**' \
  -o coverage/lcov_filtered.info

# 커버리지 리포트 출력
lcov --list coverage/lcov_filtered.info

# HTML 리포트 생성 (선택)
if command -v genhtml &> /dev/null; then
  genhtml coverage/lcov_filtered.info -o coverage/html
  echo "HTML report: coverage/html/index.html"
fi

# 임계값 검증
COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
THRESHOLD=60
echo "Coverage: ${COVERAGE}% (threshold: ${THRESHOLD}%)"

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "ERROR: Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%"
  exit 1
fi

echo "=== Tests passed with ${COVERAGE}% coverage ==="
```

### 5.2 codemagic.yaml 테스트 단계 추가

```yaml
# 기존 빌드 스크립트에 추가할 테스트 단계
scripts:
  - name: Run tests
    script: |
      cd picnic_lib
      flutter test --coverage
      # 커버리지 아티팩트 수집
    test_report: picnic_lib/build/test-results/**/*.xml
```

## 6. 구현 순서 (Implementation Order)

```
Phase 1: 인프라 (먼저)
  1. test/helpers/test_app.dart
  2. test/helpers/fixtures/fixture_loader.dart + JSON fixtures
  3. test/helpers/factories/ (VoteFactory 등)
  4. test/helpers/mocks/mock_supabase.dart
  5. scripts/run_tests.sh (커버리지)

Phase 2: Core/Data 유닛 테스트 (동시 진행 가능 - 팀 에이전트 활용)
  Team A: data/models/ 테스트 (Freezed 모델) — 가장 쉬움
  Team B: core/utils/ 테스트 (순수 함수)
  Team C: core/services/ + services/ 테스트
  Team D: data/repositories/ 테스트 (Mock Supabase 의존)

Phase 3: 위젯/프로바이더 테스트
  주요 비즈니스 위젯 위주 선별 테스트

Phase 4: e2e 아키텍처
  integration_test/ 구조 + Robot 패턴 + 5대 시나리오

Phase 5: CI 통합
  codemagic.yaml 수정 + 커버리지 게이트
```

## 7. 필요한 추가 패키지

```yaml
# picnic_lib/pubspec.yaml dev_dependencies에 추가
dev_dependencies:
  # 기존 유지
  flutter_test:
    sdk: flutter
  test: ^1.25.15
  mockito: ^5.4.5

  # 신규 추가
  build_runner: ^2.4.14     # mockito 코드 생성용 (이미 있음)
  mockito:                   # @GenerateMocks 어노테이션 활용

# picnic_app/pubspec.yaml에 추가
dev_dependencies:
  integration_test:
    sdk: flutter
```

## 8. 의사결정 사항 (사용자 입력 필요)

| # | 의사결정 | 선택지 | 권장 |
|---|---------|--------|------|
| D1 | Mock 라이브러리 | mockito (현재) vs mocktail | **mockito 유지** (이미 사용중) |
| D2 | e2e 프레임워크 | integration_test vs patrol | **integration_test** (기본, 충분) |
| D3 | 커버리지 임계값 | 50% / 60% / 70% | **60%** (core/data 기준) |
| D4 | CI 테스트 실행 시점 | 매 빌드 / PR만 / 태그 빌드만 | **매 빌드** |

---

**생성일**: 2026-03-10
**대상 프로젝트**: picnic-app (Flutter)
**PDCA Phase**: Design
**참조 Plan**: `flutter-test-comprehensive.plan.md`
