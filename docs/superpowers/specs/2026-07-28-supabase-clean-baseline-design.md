# Supabase Clean Baseline Design

## 목적

Production 서비스, 스키마, 데이터, JWT/API 키를 변경하지 않고 재현 가능한 Supabase 개발 브랜치용 migration baseline을 만든다.

## 확인된 문제

- 기존 최초 migration은 migration 외부에서 만들어진 `public.admin_user_roles`에 의존한다.
- `20260425161337_baseline_squash`에는 PostgreSQL 17 전용 `SET transaction_timeout = 0`이 있으나 production과 branch는 PostgreSQL 15다.
- 기존 baseline은 플랫폼 관리 `supabase_functions` 객체에 의존한다.
- 기존 baseline의 webhook trigger SQL에는 production URL과 JWT가 하드코딩되어 있다.
- 기존 migration을 부분적으로 수정하는 방식은 독립된 실패를 연속으로 드러냈으므로 안전한 복구 전략이 아니다.

## 안전 경계

- Production database에는 read-only query만 실행한다.
- Production migration history를 수정하지 않는다.
- Production JWT/API key를 회전하지 않는다.
- Production Edge Function, Auth, Storage, Realtime 설정을 변경하지 않는다.
- Production 데이터를 개발 branch 또는 로컬 환경으로 복제하지 않는다.
- 검증이 끝난 baseline을 production migration history에 반영하는 작업은 이 설계의 범위 밖이며 별도 승인 대상이다.
- 로그, 파일, 커밋에 secret 전체 또는 일부를 남기지 않는다.

## 접근 방식

### 1. 읽기 전용 schema snapshot

Production schema를 읽기 전용으로 추출한다. 대상은 애플리케이션이 소유하는 schema/object definition이며 테이블 데이터는 포함하지 않는다. Auth, Storage, Realtime 등 Supabase 관리 schema는 baseline 생성 대상에서 제외한다.

### 2. 결정적 sanitizer

원본 snapshot을 직접 수동 편집하지 않고 재실행 가능한 sanitizer로 변환한다. Sanitizer는 다음 항목을 거부하거나 제거한다.

- JWT, API key, Authorization header
- production project ref 및 production URL
- `supabase_functions` 등 플랫폼 관리 schema의 객체와 의존 trigger
- PostgreSQL 15에서 지원하지 않는 session setting
- owner, tablespace, ACL처럼 branch마다 달라질 수 있는 dump metadata
- 데이터 삽입문과 sequence current value

Sanitizer는 secret 패턴이나 production ref가 하나라도 남으면 결과 파일을 생성하지 않고 실패해야 한다.

### 3. 독립 baseline과 후속 migration

정제된 snapshot을 하나의 새 baseline migration으로 만든다. 기존 baseline 이후의 migration은 timestamp 순서를 유지한 채 적용한다. 기존 production migration history는 이 단계에서 변경하지 않는다.

### 4. 격리 검증

검증은 두 단계로 수행한다.

1. 빈 로컬 Supabase/PostgreSQL 15 환경에서 `db reset`으로 baseline과 후속 migration을 전부 적용한다.
2. 데이터 없는 임시 Supabase branch에 동일 migration 집합을 적용한다.

임시 branch는 검증 후 삭제하며 persistent 상태로 방치하지 않는다.

### 5. Schema 비교

Production과 검증 환경의 애플리케이션 소유 schema를 읽기 전용으로 비교한다. 다음 차이는 허용한다.

- Supabase 플랫폼 관리 객체
- branch별 URL, secret, webhook endpoint
- 데이터와 sequence current value
- migration bookkeeping

그 밖의 테이블, 컬럼, constraint, index, RLS policy, application function 차이는 실패로 처리한다.

## 보안 처리

- 기존 JWT는 이번 작업에서 회전하지 않는다.
- 새 baseline에는 production URL/JWT 기반 webhook trigger를 포함하지 않는다.
- 필요한 webhook은 이후 Vault 기반 migration 또는 branch별 secret/configuration으로 별도 설계한다.
- 생성물 검사에서 JWT 형태, `Bearer `, production ref, `service_role`, secret key 패턴을 탐지한다.
- 검사 결과에는 발견 위치와 규칙 이름만 표시하고 일치한 secret 값은 표시하지 않는다.

## 산출물

- 재실행 가능한 schema snapshot/sanitizer 스크립트
- sanitizer 자동 테스트
- secret과 플랫폼 객체가 제거된 baseline migration
- PostgreSQL 15 로컬 재생 검증
- 임시 Supabase branch 재생 검증 결과
- 허용 차이를 명시한 schema diff 결과

레포에 커밋되는 문서는 기존 정책에 따라 Markdown을 사용한다.

## 성공 조건

1. Production에 write query가 실행되지 않는다.
2. 빈 PostgreSQL 15 환경에서 baseline과 모든 후속 migration이 성공한다.
3. 데이터 없는 임시 Supabase branch가 `ACTIVE_HEALTHY`와 migration 성공 상태가 된다.
4. baseline과 관련 로그에 secret 또는 production endpoint가 없다.
5. 핵심 application table, constraint, index, RLS policy, function이 production과 일치한다.
6. 임시 branch가 검증 후 삭제된다.
7. Production migration history 변경은 별도 승인 전까지 수행되지 않는다.

## 실패 및 복구

- snapshot 또는 sanitizer가 실패하면 production에는 변화가 없으며 생성 중인 임시 파일만 폐기한다.
- 로컬 재생이 실패하면 remote branch를 만들지 않는다.
- remote 검증이 실패하면 로그를 수집한 뒤 branch를 삭제한다.
- 세 번의 독립된 baseline 수정 실패가 발생하면 패치를 중단하고 snapshot 생성 경로와 제외 규칙을 재검토한다.
