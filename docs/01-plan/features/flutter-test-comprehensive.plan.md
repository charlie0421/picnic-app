# Plan: Flutter Test Comprehensive

> picnic-app 테스트 전면 보완 계획

## 1. 현황 분석 (As-Is)

### 소스 코드 규모
| 영역 | 파일 수 | 비고 |
|------|---------|------|
| presentation/widgets | 130 | 가장 큰 영역 |
| presentation/pages | 59 | |
| presentation/common | 44 | |
| presentation/providers | 43 | Riverpod 프로바이더 |
| data/models | 43 | Freezed 모델 포함 |
| core/utils | 36 | 유틸리티 함수 |
| core/services | 21 | 서비스 레이어 |
| presentation/screens | 17 | |
| data/repositories | 4 | |
| data/storage | 5 | |
| **총 소스 파일** | **455** | 생성 파일 제외 |

### 현재 테스트 상태
| 항목 | 상태 | 수치 |
|------|------|------|
| 테스트 파일 수 | 14개 | 455개 소스 대비 3% |
| 테스트 케이스 수 | ~68개 | |
| 커버리지 측정 | 미구축 | |
| e2e/Integration 테스트 | 없음 | |
| CI/CD 테스트 단계 | 없음 | codemagic.yaml에 미포함 |
| 테스트 유틸리티/헬퍼 | 없음 | |
| Mock 인프라 | 최소 | mockito만 사용 |

### 테스트 존재 영역
- core/utils: 4개 (app_lifecycle, language, korean_search, main_initializer)
- core/services: 1개 (search_service)
- data/models: 1개 (vote_item_request)
- data/repositories: 1개 (빈 파일)
- presentation/widgets/ui: 4개 (loading_overlay 관련)
- performance: 2개 (image_loading, animation)
- app smoke test: 1개

## 2. 목표 (To-Be)

### 정량 목표
| 목표 | 수치 | 우선순위 |
|------|------|----------|
| 유닛 테스트 커버리지 | 60% 이상 (core, data 레이어) | P0 |
| 위젯 테스트 커버리지 | 40% 이상 (주요 위젯) | P1 |
| e2e 테스트 시나리오 | 핵심 플로우 5개 이상 | P2 |
| CI 테스트 자동화 | codemagic에 통합 | P0 |

### 정성 목표
- 테스트 작성이 쉬운 인프라 구축 (헬퍼, Mock, Fixture)
- 신규 코드 작성 시 테스트 동반 문화 기반 마련
- 성능 회귀 감지 체계 구축

## 3. 실행 계획 (Phases)

### Phase 1: 테스트 인프라 구축 (기반)
- [ ] 테스트 헬퍼/유틸리티 패키지 생성
  - `test/helpers/` 디렉토리 구조
  - 공통 Widget 테스트 래퍼 (ProviderScope, MaterialApp, 로케일 등)
  - Mock Supabase Client
  - Fake/Mock Provider 팩토리
- [ ] 커버리지 측정 스크립트 작성
  - `flutter test --coverage` 래퍼 스크립트
  - lcov 리포트 생성
  - 커버리지 임계값 검증 스크립트
- [ ] 테스트 Fixture 시스템
  - JSON fixture 로더
  - 모델 팩토리 (테스트용 더미 데이터 생성)

### Phase 2: Core/Data 레이어 유닛 테스트 (우선)
- [ ] core/utils/ 테스트 보완 (36개 파일)
  - deepl_translate_service, deeplink, device_fingerprint
  - math, network, pangle_ads, privacy_consent_manager
  - token_refresh_manager, common_utils
- [ ] core/services/ 테스트 보완 (21개 파일)
  - auth/social_login, network_connectivity_service
  - secure_storage_service, youtube_service
  - search_cache_service
- [ ] core/errors/ 테스트 (2개 파일)
  - auth_exception, vote_request_exceptions
- [ ] data/models/ 테스트 (43개 파일)
  - Freezed 모델 serialization/deserialization
  - equality, copyWith 동작 검증
- [ ] data/repositories/ 테스트 (4개 파일)
  - Supabase 쿼리 Mock 기반 테스트
- [ ] data/storage/ 테스트 (5개 파일)
  - local_storage, supabase_pkce_async_storage
- [ ] services/ 테스트
  - vote_status_validation_service

### Phase 3: Presentation 레이어 위젯 테스트
- [ ] 공통 위젯 테스트 (presentation/common/ 44개)
  - ads/banner_ad_widget
  - comment/comment_header, reply_button
  - common_search_box, custom_pagination
  - share_section, webview 관련
- [ ] 핵심 위젯 테스트 (presentation/widgets/ 130개 중 주요)
  - vote 관련 위젯 (핵심 비즈니스)
  - article 관련 위젯
  - community 관련 위젯
  - navigator 위젯
- [ ] Provider 테스트 (presentation/providers/ 43개)
  - Riverpod Provider 상태 변화 테스트
  - AsyncValue 상태 전환 검증

### Phase 4: e2e 테스트 아키텍처 구성
- [ ] integration_test/ 디렉토리 구조 설계
- [ ] Flutter integration_test 프레임워크 설정
  - `integration_test/app_test.dart` 진입점
  - test driver 설정
- [ ] 핵심 e2e 시나리오 작성
  1. 앱 시작 → 스플래시 → 메인 화면 진입
  2. 로그인 플로우 (소셜 로그인 Mock)
  3. 투표 플로우 (핵심 비즈니스)
  4. 검색 플로우
  5. 마이페이지 진입 및 기본 동작
- [ ] e2e 테스트용 Mock 서버/데이터 구성

### Phase 5: CI/CD 통합 및 자동화
- [ ] codemagic.yaml에 테스트 단계 추가
  - `flutter test` 실행
  - 커버리지 리포트 수집
  - 커버리지 임계값 미달 시 빌드 실패
- [ ] PR 기반 테스트 트리거 설정
- [ ] 테스트 결과 Slack/Discord 알림 (선택)

## 4. 우선순위 매트릭스

```
높은 영향 + 낮은 노력: Phase 1 (인프라), Phase 5 (CI 통합)
높은 영향 + 높은 노력: Phase 2 (Core/Data 테스트)
중간 영향 + 높은 노력: Phase 3 (위젯 테스트)
높은 영향 + 높은 노력: Phase 4 (e2e 아키텍처)
```

## 5. 제약 사항 및 리스크

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 네이티브 플러그인 Mock 어려움 | 중 | platform channel mock 활용 |
| Supabase 의존성 | 높 | Mock/Fake client 패턴 적용 |
| 생성 코드(.g.dart, .freezed.dart) | 낮 | 생성 코드는 테스트 제외 |
| CI 빌드 시간 증가 | 중 | 테스트 병렬 실행, 선택적 실행 |

## 6. 성공 기준

- [ ] `flutter test` 명령으로 전체 테스트 스위트 실행 가능
- [ ] 커버리지 60% 이상 달성 (core, data 레이어)
- [ ] e2e 테스트 5개 시나리오 작동
- [ ] CI에서 매 빌드마다 테스트 자동 실행
- [ ] 테스트 실패 시 빌드 중단

---

**생성일**: 2026-03-10
**대상 프로젝트**: picnic-app (Flutter)
**PDCA Phase**: Plan
