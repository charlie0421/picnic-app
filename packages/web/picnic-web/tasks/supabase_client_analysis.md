# Supabase 클라이언트 구현 분석 보고서

## 1. 현재 Supabase 클라이언트 구현 현황

### 1.1. 발견된 Supabase 클라이언트 구현

현재 프로젝트에서는 다양한 방식으로 Supabase 클라이언트를 생성하고 사용하고 있습니다:

#### 1.1.1. 레거시 구현
- **/lib/supabase.ts**: 구 방식인 `createClient`를 사용한 단일 클라이언트 구현
  ```typescript
  import {createClient} from '@supabase/supabase-js';
  export const supabase = createClient(supabaseUrl, supabaseAnonKey);
  ```

#### 1.1.2. 클라이언트 구현
- **/utils/supabase-client.ts**: 최신 `createBrowserClient`를 사용한 브라우저 환경 클라이언트
  ```typescript
  'use client';
  import {createBrowserClient} from '@supabase/ssr';
  export const supabase = createBrowserClient(...);
  ```
  
#### 1.1.3. 서버 구현 (2가지 버전)
- **/utils/supabase-server-client.ts**: 최신 `createServerClient`를 사용한 서버 환경 클라이언트
  ```typescript
  import {createServerClient} from '@supabase/ssr';
  export const createClient = async () => {...};
  ```

- **/app/[lang]/utils/supabase-server-client.ts**: 서버 클라이언트의 별도 구현 버전 (경로 기반)
  ```typescript
  import {createServerClient} from '@supabase/ssr';
  export async function createClient() {...};
  ```

### 1.2. Context 및 Hook 구현

- **/components/providers/SupabaseProvider.tsx**: 클라이언트 컴포넌트에서 Supabase 클라이언트를 사용하기 위한 컨텍스트 및 훅 구현
  ```typescript
  'use client';
  export const SupabaseProvider: React.FC<SupabaseProviderProps> = ({ children }) => {...};
  export const useSupabase = (): SupabaseContextType => {...};
  ```

- **/contexts/AuthContext.tsx**: 인증 관련 사용자 상태 및 인증 함수를 제공하는 별도의 인증 컨텍스트
  ```typescript
  'use client';
  export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {...};
  export const useAuth = () => {...};
  ```

## 2. 현재 구현의 문제점

### 2.1. 일관성 없는 클라이언트 사용

- 여러 곳에서 다양한 방식으로 Supabase 클라이언트를 생성하고 있음
- 레거시 방식(`createClient`)과 최신 방식(`createBrowserClient`, `createServerClient`) 혼용
- 서버 클라이언트가 두 위치에 중복 구현됨 (/utils와 /app/[lang]/utils)

### 2.2. 서버/클라이언트 코드 분리 문제

- 몇몇 파일에서 'use client' 지시문이 올바르게 사용되고 있지만, 서버/클라이언트 컴포넌트 분리가 불완전함
- 서버 컴포넌트에서 클라이언트 클라이언트 사용, 또는 그 반대의 경우가
발생할 가능성 있음

### 2.3. 중복 컨텍스트 제공자

- `SupabaseProvider`와 `AuthContext`가 별도로 구현되어 있고, 일부 기능이 중복됨
- 두 컨텍스트 간의 상호작용이나 의존성이 명확하지 않음

### 2.4. 에러 처리의 일관성 부족

- 일부 구현에서는 에러를 throw하고, 다른 곳에서는 콘솔에 로깅만 하는 등 일관되지 않은 에러 처리
- 특히 `/utils/api/serverQueries.ts`와 `/utils/api/queries.ts`에서 에러 처리 방식이 다름

### 2.5. 타입 변환 중복

- API 응답을 변환하는 과정에서 중복 코드 발생 (스네이크 케이스 → 캐멀 케이스)
- 일관된 타입 변환 유틸리티 함수 부재

## 3. 인증 흐름 분석

### 3.1. 현재 인증 흐름

1. **초기 세션 확인**: `AuthProvider`에서 `supabase.auth.getSession()`으로 기존 세션 확인
2. **인증 상태 변경 감지**: `supabase.auth.onAuthStateChange`를 통해 인증 상태 변화 구독
3. **로그인 방법**: 이메일/비밀번호 로그인 및 소셜 로그인 지원
4. **사용자 정보 관리**: 로그인 성공 시 `user_profiles` 테이블에서 추가 정보 조회

### 3.2. 인증 관련 문제점

- 멀티 환경(브라우저, 서버) 인증 처리가 명확하게 분리되어 있지 않음
- 서버 인증 흐름에 대한 구현이 불완전함
- 클라이언트 측에서는 인증 상태를 기본적으로 로컬 스토리지와 쿠키에 중복 저장하고 있음

## 4. 성능 관련 이슈

### 4.1. 쿼리 패턴

- API 요청 시 관련 데이터를 함께 가져오기 위한 중첩 쿼리 사용 (`vote_item`, `artist` 등)
- `withRetry` 유틸리티를 사용하여 API 요청 재시도 메커니즘 구현

### 4.2. 잠재적 성능 문제

- 명시적인 캐싱 전략 부재
- 대량의 데이터를 한 번에 가져오는 쿼리 패턴 (페이징 미사용)
- SSR과 클라이언트 사이드 데이터 페칭의 중복 가능성

## 5. 개선 권장사항

### 5.1. 클라이언트 구조 개선

1. `/lib/supabase` 디렉토리를 생성하여 모든 Supabase 관련 코드 중앙화
2. `/lib/supabase/server.ts`와 `/lib/supabase/client.ts`로 서버/클라이언트 코드 명확히 분리
3. 레거시 코드를 점진적으로 마이그레이션

### 5.2. 타입 시스템 강화

1. Supabase 데이터베이스 스키마에 기반한 완전한 타입 정의
2. 데이터 변환을 위한 공통 유틸리티 함수 구현
3. 중첩 쿼리 응답에 대한 타입 안전성 확보

### 5.3. 최신 SSR 패턴 도입

1. React Server Component에 맞는 데이터 페칭 패턴 구현
2. 서버 컴포넌트에서의 데이터 페칭과 클라이언트 컴포넌트에서의 상태 관리 분리
3. 인증 상태에 대한 서버/클라이언트 간의 일관된 접근 구현

### 5.4. 성능 최적화

1. React Query 또는 SWR을 활용한 클라이언트 측 캐싱 전략 도입
2. 페이징 및 무한 스크롤 구현으로 대량 데이터 로딩 최적화
3. 실시간 업데이트가 필요한 부분에 한해 Supabase Realtime 기능 활용

## 6. 결론

현재 Supabase 클라이언트 구현은 기능적으로는 작동하지만, 일관성과 구조적 측면에서 개선이 필요합니다. 주요 문제점은 다양한 클라이언트 구현의 혼재, 불명확한 서버/클라이언트 분리, 중복 컨텍스트 및 타입 변환 등입니다. 이러한 문제점을 해결하기 위해 클라이언트 구조 개선, 타입 시스템 강화, 최신 SSR 패턴 도입, 성능 최적화 등의 방안을 제안합니다. 