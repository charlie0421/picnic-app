# Supabase 클라이언트 사용 가이드

## 1. 현재 Supabase 클라이언트 사용 패턴

### 1.1. 클라이언트 초기화 패턴

현재 프로젝트에서는 다음과 같은 여러 방식으로 Supabase 클라이언트를 초기화하고 있습니다:

#### 레거시 방식

```typescript
// /lib/supabase.ts
import {createClient} from '@supabase/supabase-js';
export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

- **용도**: App Router 도입 이전의 코드 베이스에서 주로 사용
- **문제점**: SSR에 최적화되지 않았으며 서버/클라이언트 구분이 없음

#### 클라이언트 측 초기화

```typescript
// /utils/supabase-client.ts
'use client';
import {createBrowserClient} from '@supabase/ssr';
export const supabase = createBrowserClient(...);
```

- **용도**: 브라우저 환경에서 사용할 Supabase 클라이언트
- **특징**: 쿠키와 로컬 스토리지를 모두 사용하는 하이브리드 스토리지 구현

#### 서버 측 초기화

```typescript
// /utils/supabase-server-client.ts
import {createServerClient} from '@supabase/ssr';
export const createClient = async () => {...};
```

```typescript
// /app/[lang]/utils/supabase-server-client.ts
import {createServerClient} from '@supabase/ssr';
export async function createClient() {...};
```

- **용도**: 서버 컴포넌트/RSC에서 데이터 요청 시 사용
- **문제점**: 두 위치에 거의 동일한 코드가 중복 구현되어 있음

### 1.2. 자주 사용되는 API 패턴

#### 인증 관련

```typescript
// 세션 가져오기
const { data: { session } } = await supabase.auth.getSession();

// 로그인
const { error } = await supabase.auth.signInWithPassword({ email, password });

// 소셜 로그인
const { error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: { redirectTo: '...' }
});

// 로그아웃
const { error } = await supabase.auth.signOut();

// 인증 상태 변경 감지
const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
  // 상태 처리 로직
});
```

#### 데이터 쿼리

```typescript
// 단일 레코드 조회
const { data, error } = await supabase
  .from('vote')
  .select('*')
  .eq('id', id)
  .is('deleted_at', null)
  .single();

// 관계 데이터 포함 조회
const { data, error } = await supabase
  .from('vote')
  .select(`
    *,
    vote_item(
      *,
      artist(*)
    )
  `)
  .eq('id', id);
  
// 데이터 생성
const { data, error } = await supabase
  .from('user_profiles')
  .insert([{ id: userId, nickname, bio }]);

// 데이터 업데이트
const { data, error } = await supabase
  .from('user_profiles')
  .update({ nickname, bio })
  .eq('id', userId);
```

#### 스토리지 사용

```typescript
// 파일 업로드
const { data, error } = await supabase.storage
  .from('bucket')
  .upload(path, file);

// 공개 URL 가져오기
const url = supabase.storage.from('bucket').getPublicUrl(path).data.publicUrl;
```

### 1.3. 컨텍스트 및 훅 사용 패턴

#### Supabase Provider

```typescript
// /components/providers/SupabaseProvider.tsx
'use client';
import { supabase as supabaseClient } from '@/utils/supabase-client';

export const SupabaseProvider: React.FC<SupabaseProviderProps> = ({ children }) => {
  return (
    <SupabaseContext.Provider value={{ supabase: supabaseClient }}>
      {children}
    </SupabaseContext.Provider>
  );
};

// 사용 예
const { supabase } = useSupabase();
```

#### Auth Provider

```typescript
// /contexts/AuthContext.tsx
'use client';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // 인증 상태 관리 로직
  // supabase.auth.getSession(), onAuthStateChange() 등 사용
  
  return (
    <AuthContext.Provider value={{ authState, signIn, signOut, ... }}>
      {children}
    </AuthContext.Provider>
  );
};

// 사용 예
const { authState, signIn, signOut } = useAuth();
```

## 2. 데이터베이스 테이블 및 RLS 정책

현재 애플리케이션에서 자주 사용되는 주요 테이블:

| 테이블명 | 설명 | 주요 필드 |
|---------|------|----------|
| `user_profiles` | 사용자 추가 정보 | `id`, `email`, `nickname`, `avatar_url`, `is_admin`, `created_at` |
| `vote` | 투표 정보 | `id`, `title`, `start_at`, `stop_at`, `main_image`, `vote_category` |
| `vote_item` | 투표 항목 | `id`, `vote_id`, `artist_id`, `vote_total` |
| `artist` | 아티스트 정보 | `id`, `name`, `image`, `artist_group` |
| `reward` | 보상 정보 | `id`, `name`, `description`, `image`, `price` |
| `vote_reward` | 투표-보상 연결 | `vote_id`, `reward_id` |
| `media` | 미디어 콘텐츠 | `id`, `title`, `thumbnail_url`, `video_url`, `created_at` |

## 3. 데이터 변환 패턴

### 스네이크 케이스 → 카멜 케이스 변환

현재 프로젝트에서는 DB 필드명(스네이크 케이스)과 프론트엔드 객체 속성명(카멜 케이스) 간의 변환을 각 API 함수에서 수동으로 처리하고 있습니다. 예시:

```typescript
// 원본 데이터
// {
//   "id": 1,
//   "created_at": "2023-01-01T00:00:00Z",
//   "start_at": "2023-01-02T00:00:00Z",
//   "vote_category": "idol",
//   "main_image": "path/to/image.jpg"
// }

// 변환 코드
return {
  ...voteData,
  createdAt: voteData.created_at,
  startAt: voteData.start_at,
  voteCategory: voteData.vote_category,
  mainImage: voteData.main_image
};
```

## 4. 에러 처리 패턴

현재 프로젝트에서는 두 가지 주요 에러 처리 패턴이 공존합니다:

### 에러 throw 패턴

```typescript
// /utils/api/auth.ts
export const getUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', userId)
    .single()

  if (error) throw error
  return data
}
```

### 에러 로깅 패턴

```typescript
// /utils/api/queries.ts
const _getVotes = async (
  sortBy: "votes" | "recent" = "votes",
): Promise<Vote[]> => {
  try {
    // 쿼리 로직...
  } catch (error) {
    logRequestError(error, 'getVotes');
    return [];
  }
};
```

## 5. 모범 사례와 권장 패턴

### 5.1. 클라이언트 초기화 통합

```typescript
// /lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createServerSupabaseClient() {
  const cookieStore = cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name) {
          return cookieStore.get(name)?.value;
        },
        set(name, value, options) {
          cookieStore.set({ name, value, ...options });
        },
        remove(name, options) {
          cookieStore.set({ name, value: '', ...options });
        },
      },
    }
  );
}

// /lib/supabase/client.ts
'use client';

import { createBrowserClient } from '@supabase/ssr';

export function createBrowserSupabaseClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### 5.2. 데이터 변환 유틸리티

```typescript
// /utils/transform.ts
type SnakeToCamelCase<S extends string> = S extends `${infer T}_${infer U}`
  ? `${T}${Capitalize<SnakeToCamelCase<U>>}`
  : S;

type SnakeToCamel<T> = {
  [K in keyof T as SnakeToCamelCase<K & string>]: T[K] extends object
    ? SnakeToCamel<T[K]>
    : T[K];
};

export function snakeToCamel<T>(obj: T): SnakeToCamel<T> {
  if (Array.isArray(obj)) {
    return obj.map(snakeToCamel) as any;
  }

  if (obj !== null && typeof obj === 'object') {
    return Object.fromEntries(
      Object.entries(obj).map(([key, value]) => [
        key.replace(/_([a-z])/g, (_, p1) => p1.toUpperCase()),
        snakeToCamel(value)
      ])
    ) as any;
  }

  return obj as any;
}
```

### 5.3. 일관된 에러 처리

```typescript
// /lib/supabase/error.ts
import { PostgrestError } from '@supabase/supabase-js';

export enum ErrorCode {
  NOT_FOUND = 'not_found',
  UNAUTHORIZED = 'unauthorized',
  FORBIDDEN = 'forbidden',
  CONFLICT = 'conflict',
  VALIDATION = 'validation',
  SERVER_ERROR = 'server_error',
  UNKNOWN = 'unknown',
}

export class AppError extends Error {
  code: ErrorCode;
  details?: any;

  constructor(message: string, code: ErrorCode, details?: any) {
    super(message);
    this.code = code;
    this.details = details;
    this.name = 'AppError';
  }
}

export function handleSupabaseError(error: PostgrestError): AppError {
  // PostgreSQL 에러 코드에 따라 적절한 에러 객체 반환
  const { code, message, details } = error;
  
  // 에러 코드 매핑 (PostgreSQL 에러 코드 기준)
  if (code === '42P01' || code === '22P02' || code === '23503') {
    return new AppError('요청한 데이터를 찾을 수 없습니다', ErrorCode.NOT_FOUND, details);
  } else if (code === '42501' || code === '28000') {
    return new AppError('권한이 없습니다', ErrorCode.FORBIDDEN, details);
  } else if (code === '23505') {
    return new AppError('중복된 데이터가 존재합니다', ErrorCode.CONFLICT, details);
  } else if (code?.startsWith('22') || code?.startsWith('23')) {
    return new AppError('데이터 유효성 검사 실패', ErrorCode.VALIDATION, details);
  }
  
  // 기본 서버 에러
  return new AppError(message || '서버 에러가 발생했습니다', ErrorCode.SERVER_ERROR, details);
}
```

### 5.4. 서버 컴포넌트에서의 데이터 페칭

```typescript
// app/[lang]/(main)/votes/page.tsx
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { snakeToCamel } from '@/utils/transform';
import { handleSupabaseError } from '@/lib/supabase/error';

export default async function VotesPage() {
  try {
    const supabase = await createServerSupabaseClient();
    const { data, error } = await supabase
      .from('vote')
      .select(`
        *,
        vote_item(*,
          artist(*)
        )
      `)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });
      
    if (error) throw handleSupabaseError(error);
    
    // 스네이크 케이스를 카멜 케이스로 변환
    const votes = snakeToCamel(data);
    
    return (
      <VoteList votes={votes} />
    );
  } catch (error) {
    // 에러 처리 UI
    return <ErrorComponent error={error} />;
  }
}
```

## 6. 결론

Supabase 클라이언트 사용을 개선하기 위해 다음 사항을 권장합니다:

1. **코드 중앙화**: `/lib/supabase` 디렉토리에 서버/클라이언트 구현을 통합
2. **타입 강화**: 일관된 타입 변환 유틸리티를 통해 타입 안전성 확보
3. **에러 처리 표준화**: 애플리케이션 전반에 걸쳐 일관된 에러 처리 패턴 적용
4. **RSC 패턴 도입**: Next.js App Router에 최적화된 데이터 페칭 패턴 구현 