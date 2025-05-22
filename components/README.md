# 컴포넌트 구조

이 프로젝트는 Next.js 13+ App Router를 사용하며, 효율적인 서버 컴포넌트와 클라이언트 컴포넌트 아키텍처를 위해 다음과 같은 디렉토리 구조를 가집니다.

## 디렉토리 구조

```
components/
├── client/      # 클라이언트 컴포넌트 (상호작용, 상태 관리 필요)
├── server/      # 서버 컴포넌트 (정적 UI, 데이터 페칭)
├── shared/      # 서버와 클라이언트 로직을 모두 포함하는 복합 컴포넌트
├── ui/          # 스타일링 위주의 순수한 UI 컴포넌트
├── features/    # 도메인별 기능 컴포넌트 (점진적으로 shared로 이동 예정)
└── providers/   # 컨텍스트 프로바이더 컴포넌트
```

## 컴포넌트 분류 원칙

### 서버 컴포넌트 (`server/`)

- **사용 사례**: 
  - 정적 UI 요소
  - 데이터 페칭 로직
  - SEO 중요 컨텐츠
  - 로딩 상태 UI (스켈레톤, 로딩 스피너 등)

- **특징**:
  - 클라이언트 번들 크기에 포함되지 않음
  - 인터랙션 없음 (onClick, onChange 등 사용 불가)
  - useState, useEffect 등 React 훅 사용 불가
  - 빠른 초기 로드 속도

### 클라이언트 컴포넌트 (`client/`)

- **사용 사례**:
  - 인터랙션이 필요한 UI (버튼, 폼 등)
  - 브라우저 API 사용 (localStorage, navigator 등)
  - 상태 관리가 필요한 UI
  - 이벤트 핸들러가 필요한 요소

- **특징**:
  - 파일 상단에 'use client' 지시어 필수
  - 모든 React 훅 사용 가능
  - 클라이언트 번들 사이즈에 영향

### 공유 컴포넌트 (`shared/`)

- **사용 사례**:
  - 서버와 클라이언트 로직을 모두 포함해야 하는 복잡한 기능
  - 서버에서 데이터를 가져오고 클라이언트에서 인터랙션 제공

- **구조**:
  - `ComponentName/` 디렉토리
  - `ComponentName.tsx` - 진입점 (서버 컴포넌트)
  - `ComponentNameClient.tsx` - 클라이언트 컴포넌트
  - `index.ts` - 내보내기 집합

- **예시**: 투표 상세 페이지
  - 서버에서 초기 데이터 로드
  - 클라이언트에서 인터랙션 처리

## 컴포넌트 작성 가이드라인

### 서버 컴포넌트 최적화

1. **가능한 많은 컴포넌트를 서버 컴포넌트로 유지하세요**:
   - 클라이언트 번들 크기 최소화
   - 페이지 로드 속도 향상

2. **데이터 페칭은 서버 컴포넌트에서 수행하세요**:
   - 클라이언트에 민감한 API 토큰 노출 방지
   - 데이터 로딩 성능 향상

3. **인터랙티브 로직은 최대한 작게 분리하세요**:
   - 큰 컴포넌트는 서버 컴포넌트로 유지
   - 인터랙티브 부분만 클라이언트 컴포넌트로 분리

### 클라이언트 컴포넌트 관리

1. **컴포넌트 경계를 명확히 하세요**:
   - 서버/클라이언트 로직 명확히 분리
   - props를 통한 데이터 전달 구조 유지

2. **지나친 중첩은 피하세요**:
   - 클라이언트 컴포넌트 내부에 서버 컴포넌트 배치 불가능
   - 서버 컴포넌트 내부에 클라이언트 컴포넌트 배치는 가능

3. **파일 크기를 관리하세요**:
   - 역할별로 파일 분리
   - 큰 컴포넌트는 더 작은 단위로 분할

## 컴포넌트 인덱스 파일 관리

각 디렉토리는 `index.ts` 파일을 통해 내보내기를 관리합니다. 새 컴포넌트를 추가할 때는 해당 인덱스 파일에도 추가해야 합니다.

```typescript
// 예: components/server/index.ts
export { default as LoadingState } from './LoadingState';
export { default as ErrorState } from './ErrorState';
export { default as VoteListServer } from './VoteListServer';
// ...추가 컴포넌트
```

## 마이그레이션 가이드

기존의 `features/` 디렉토리 내 컴포넌트들은 점진적으로 `shared/`, `server/`, `client/` 디렉토리로 이동할 예정입니다. 마이그레이션 시 다음 단계를 따르세요:

1. 컴포넌트의 성격 분석 (데이터 페칭? 인터랙션?)
2. 적절한 디렉토리 선택
3. 필요시 서버/클라이언트 로직 분리
4. 인덱스 파일 업데이트
5. 임포트 경로 수정

## 사용 예시

### 서버 컴포넌트 예시

```tsx
// components/server/VoteDetailServer.tsx
import { createServerSupabaseClient } from '@/lib/supabase/server';

export default async function VoteDetailServer({ id }) {
  const supabase = createServerSupabaseClient();
  const { data } = await supabase.from('votes').select().eq('id', id);
  
  return <VoteDetailClient initialData={data} />;
}
```

### 클라이언트 컴포넌트 예시

```tsx
// components/client/VoteButton.tsx
'use client';

import { useState } from 'react';

export default function VoteButton({ itemId, onVote }) {
  const [loading, setLoading] = useState(false);
  
  const handleClick = async () => {
    setLoading(true);
    await onVote(itemId);
    setLoading(false);
  };
  
  return (
    <button onClick={handleClick} disabled={loading}>
      {loading ? '투표 중...' : '투표하기'}
    </button>
  );
}
```

### 공유 컴포넌트 예시

```tsx
// components/shared/VoteDetail/VoteDetail.tsx
import { VoteDetailServer } from '@/components/server';

export default function VoteDetail({ id }) {
  return <VoteDetailServer id={id} />;
}

// components/shared/VoteDetail/VoteDetailClient.tsx
'use client';

export default function VoteDetailClient({ initialData }) {
  // 클라이언트 상태, 이벤트 핸들러 등
}

// components/shared/VoteDetail/index.ts
export { default } from './VoteDetail';
export { default as VoteDetailClient } from './VoteDetailClient';
``` 