# Clean Architecture 구현 가이드

## 개요

이 문서는 Picnic App에서 구현된 Clean Architecture의 구조와 사용법을 설명합니다. Clean Architecture는 관심사의 분리, 테스트 가능성, 그리고 코드의 유지보수성을 향상시키기 위해 도입되었습니다.

## 아키텍처 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                      │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │    Widgets      │     BLoCs       │     Providers       │ │
│  │   (UI Layer)    │  (State Mgmt)   │   (Riverpod)        │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                        │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │   Use Cases     │   Use Case      │     Common          │ │
│  │  (Business      │    Results      │   Interfaces       │ │
│  │   Logic)        │                 │                     │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                            │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │   Entities      │  Value Objects  │   Repository        │ │
│  │  (Core Models)  │ (Domain Types)  │   Interfaces        │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                             │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │  Repositories   │  Data Sources   │     Models          │ │
│  │ (Implementations)│(API, Database) │  (Data Transfer)    │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────────────────────────┐
│                 Infrastructure Layer                       │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │    Services     │    External     │   Dependency        │ │
│  │   (Network,     │   Libraries     │   Injection         │ │
│  │   Storage)      │ (Supabase, etc) │   (get_it)          │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 1. Domain Layer (도메인 레이어)

### 1.1 Entities (엔티티)

비즈니스 로직이 포함된 핵심 모델입니다.

#### UserEntity
```dart
// lib/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String nickname;
  final Email email;
  final StarCandy starCandy;
  // ...

  // 비즈니스 로직 메서드들
  bool get isActive => deletedAt == null;
  bool get isProfileComplete => /* validation logic */;
  bool canAfford(StarCandy amount) => starCandy.amount >= amount.amount;
}
```

#### ArtistEntity
```dart
// lib/domain/entities/artist_entity.dart
class ArtistEntity {
  final int id;
  final Content name;
  final int totalVotes;
  // ...

  // 비즈니스 로직
  bool get isPopular => totalVotes >= 1000;
  ArtistPopularityTier get popularityTier => /* tier calculation */;
  bool canReceiveVotes() => isActive && canParticipateInVotes;
}
```

### 1.2 Value Objects (값 객체)

불변 객체로 도메인의 개념을 표현합니다.

#### Email
```dart
// lib/domain/value_objects/email.dart
class Email {
  final String value;
  
  factory Email(String value) {
    if (!_isValidEmail(value)) {
      throw EmailValidationException('Invalid email format');
    }
    return Email._(value.toLowerCase().trim());
  }
  
  String get masked => /* masking logic */;
  bool get isCommonProvider => /* provider detection */;
}
```

#### StarCandy
```dart
// lib/domain/value_objects/star_candy.dart
class StarCandy {
  final int amount;
  
  StarCandy operator +(StarCandy other) => /* addition logic */;
  StarCandy operator -(StarCandy other) => /* subtraction logic */;
  String get formatted => /* formatting logic */;
}
```

### 1.3 Repository Interfaces (리포지토리 인터페이스)

데이터 접근을 위한 추상 인터페이스입니다.

```dart
// lib/domain/interfaces/user_repository_interface.dart
abstract class IUserRepository {
  Future<UserEntity?> getUserById(String userId);
  Future<UserEntity> updateUserProfile({required String userId, ...});
  Future<UserEntity> addStarCandy({required String userId, ...});
  // ...
}
```

## 2. Application Layer (애플리케이션 레이어)

### 2.1 Use Cases (사용 사례)

비즈니스 규칙을 구현하고 도메인 객체를 조율합니다.

```dart
// lib/application/use_cases/user/get_user_profile_use_case.dart
class GetUserProfileUseCase implements UseCase<GetUserProfileParams, UserEntity?> {
  final IUserRepository _userRepository;

  @override
  Future<UseCaseResult<UserEntity?>> execute(GetUserProfileParams params) async {
    // 입력 검증
    if (params.userId.isEmpty) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('User ID cannot be empty')
      );
    }

    // 비즈니스 로직 실행
    final user = await _userRepository.getUserById(params.userId);
    
    // 비즈니스 규칙 적용
    if (params.requireCompleteProfile && !user.isProfileComplete) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule('User profile is incomplete')
      );
    }

    return UseCaseResult.success(user);
  }
}
```

### 2.2 Use Case Results (결과 패턴)

일관된 결과 처리를 위한 패턴입니다.

```dart
// lib/application/common/use_case_result.dart
sealed class UseCaseResult<T> {
  factory UseCaseResult.success(T data) = UseCaseSuccess<T>;
  factory UseCaseResult.failure(UseCaseFailure failure) = UseCaseFailureResult<T>;
  
  // Functional programming methods
  UseCaseResult<R> map<R>(R Function(T data) transform);
  UseCaseResult<R> flatMap<R>(UseCaseResult<R> Function(T data) transform);
  UseCaseResult<T> onSuccess(void Function(T data) callback);
  UseCaseResult<T> onFailure(void Function(UseCaseFailure failure) callback);
}
```

## 3. Data Layer (데이터 레이어)

### 3.1 Repository Implementations (리포지토리 구현)

```dart
// lib/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements IUserRepository {
  final SupabaseClient _supabaseClient;
  final OfflineDatabaseService _offlineDatabase;
  final SimpleCacheManager _cacheManager;

  @override
  Future<UserEntity?> getUserById(String userId) async {
    // 캐시 -> 로컬 DB -> 원격 순서로 데이터 조회
    final cacheKey = 'user_$userId';
    final cachedData = await _cacheManager.get(cacheKey);
    if (cachedData != null) return _mapToEntity(cachedData);
    
    // ... 로컬 DB 및 원격 조회 로직
    
    return _mapToEntity(response);
  }
}
```

## 4. Presentation Layer (프레젠테이션 레이어)

### 4.1 BLoC Pattern (상태 관리)

```dart
// lib/presentation/blocs/user_profile/user_profile_bloc.dart
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  
  UserProfileBloc({required GetUserProfileUseCase getUserProfileUseCase})
      : _getUserProfileUseCase = getUserProfileUseCase,
        super(const UserProfileState.initial()) {
    on<UserProfileEvent>((event, emit) async {
      await event.when(
        loadUserProfile: (userId, requirements) => 
            _onLoadUserProfile(emit, userId, requirements),
        // ... 다른 이벤트 핸들러들
      );
    });
  }
}
```

### 4.2 Freezed States and Events

```dart
@freezed
class UserProfileState with _$UserProfileState {
  const factory UserProfileState.initial() = UserProfileInitial;
  const factory UserProfileState.loading({UserEntity? user}) = UserProfileLoading;
  const factory UserProfileState.loaded({required UserEntity user}) = UserProfileLoaded;
  const factory UserProfileState.error({required String message, UserEntity? user}) = UserProfileError;
}
```

## 5. Dependency Injection (의존성 주입)

### 5.1 Service Locator 설정

```dart
// lib/core/di/service_locator.dart
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;
  
  static Future<void> init() async {
    await _registerCore();
    await _registerServices();
    await _registerRepositories();
    await _registerUseCases();
  }
  
  static Future<void> _registerUseCases() async {
    _getIt.registerFactory<GetUserProfileUseCase>(
      () => GetUserProfileUseCase(_getIt<IUserRepository>()),
    );
  }
}
```

### 5.2 BLoC Provider 통합

```dart
// lib/core/di/bloc_providers.dart
class BlocProviders {
  static Widget provideBlocs({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserProfileBloc>(
          create: (context) => UserProfileBloc(
            getUserProfileUseCase: ServiceLocator.get<GetUserProfileUseCase>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
```

## 6. 사용법

### 6.1 앱 초기화

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 의존성 주입 초기화
  await ServiceLocator.init();
  
  runApp(
    BlocProviders.provideBlocs(
      child: MyApp(),
    ),
  );
}
```

### 6.2 Widget에서 BLoC 사용

```dart
class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        return state.when(
          initial: () => const CircularProgressIndicator(),
          loading: (user) => LoadingWidget(previousUser: user),
          loaded: (user) => UserProfileWidget(user: user),
          error: (message, user) => ErrorWidget(
            message: message,
            previousUser: user,
          ),
        );
      },
    );
  }
}
```

### 6.3 이벤트 발생

```dart
// 사용자 프로필 로드
context.read<UserProfileBloc>().add(
  UserProfileEvent.loadUserProfile(userId: 'user123'),
);

// 프로필 업데이트
context.read<UserProfileBloc>().add(
  UserProfileEvent.updateProfile(
    userId: 'user123',
    nickname: 'newNickname',
  ),
);
```

## 7. 테스트 전략

### 7.1 Unit Tests

```dart
// test/application/use_cases/get_user_profile_use_case_test.dart
void main() {
  group('GetUserProfileUseCase', () {
    late MockIUserRepository mockRepository;
    late GetUserProfileUseCase useCase;

    setUp(() {
      mockRepository = MockIUserRepository();
      useCase = GetUserProfileUseCase(mockRepository);
    });

    test('should return user when found', () async {
      // Arrange
      final user = UserEntity(/* test data */);
      when(mockRepository.getUserById(any)).thenAnswer((_) async => user);

      // Act
      final result = await useCase.execute(GetUserProfileParams(userId: 'test'));

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, user);
    });
  });
}
```

### 7.2 BLoC Tests

```dart
void main() {
  group('UserProfileBloc', () {
    late MockGetUserProfileUseCase mockUseCase;
    late UserProfileBloc bloc;

    setUp(() {
      mockUseCase = MockGetUserProfileUseCase();
      bloc = UserProfileBloc(getUserProfileUseCase: mockUseCase);
    });

    blocTest<UserProfileBloc, UserProfileState>(
      'emits loaded state when load user profile succeeds',
      build: () {
        when(mockUseCase.execute(any)).thenAnswer(
          (_) async => UseCaseResult.success(testUser),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        UserProfileEvent.loadUserProfile(userId: 'test'),
      ),
      expect: () => [
        const UserProfileState.loading(),
        UserProfileState.loaded(user: testUser),
      ],
    );
  });
}
```

## 8. 모범 사례

### 8.1 Domain Layer
- 엔티티는 비즈니스 로직만 포함
- Value Objects는 불변성 보장
- Repository 인터페이스는 도메인 개념으로 정의

### 8.2 Application Layer
- Use Cases는 단일 책임 원칙 준수
- 모든 입력 검증 및 비즈니스 규칙 적용
- 일관된 결과 패턴 사용

### 8.3 Data Layer
- 캐시 → 로컬 DB → 원격 순서의 데이터 접근
- 오프라인 우선 아키텍처 구현
- 적절한 에러 처리 및 재시도 로직

### 8.4 Presentation Layer
- BLoC 이벤트는 명확한 의도 표현
- State는 UI에 필요한 모든 정보 포함
- Extension으로 편의 기능 제공

## 9. 마이그레이션 가이드

기존 Riverpod 기반 코드를 Clean Architecture로 마이그레이션하는 단계:

1. **도메인 모델 정의**: 기존 데이터 모델을 도메인 엔티티로 변환
2. **Use Case 구현**: 기존 Provider 로직을 Use Case로 추출
3. **Repository 구현**: 데이터 접근 로직을 Repository로 분리
4. **BLoC 도입**: Provider를 BLoC으로 단계적 교체
5. **의존성 주입**: 기존 수동 주입을 ServiceLocator로 변경

## 10. 성능 고려사항

- **Lazy Loading**: Use Cases는 팩토리로 등록하여 필요시에만 생성
- **캐싱**: 다층 캐싱으로 성능 최적화
- **메모리 관리**: BLoC의 적절한 생명주기 관리
- **오프라인 지원**: 로컬 우선 데이터 접근으로 응답성 향상

이 Clean Architecture 구현은 코드의 테스트 가능성, 유지보수성, 그리고 확장성을 크게 향상시킵니다.