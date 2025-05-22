# 공유 컴포넌트 디렉토리

이 디렉토리는 서버 컴포넌트와 클라이언트 컴포넌트를 함께 사용하는 복합 컴포넌트를 포함합니다.

## 공유 컴포넌트 구조

각 공유 컴포넌트는 다음과 같은 구조를 가집니다:

```
ComponentName/
├── ComponentName.tsx      # 메인 진입점 (서버 컴포넌트)
├── ComponentNameClient.tsx # 클라이언트 기능 (클라이언트 컴포넌트)
└── index.ts               # 내보내기 모음
```

## 사용 목적

공유 컴포넌트는 다음과 같은 경우에 사용합니다:

1. 컴포넌트가 서버 측 데이터 페칭과 클라이언트 측 인터랙션을 모두 필요로 할 때
2. 성능을 최적화하기 위해 서버와 클라이언트 부분을 분리하고 싶을 때
3. 하나의 기능을 서버/클라이언트 컴포넌트로 명확하게 분리하고 싶을 때

## 작성 패턴

### 1. 서버 컴포넌트 진입점

```tsx
// ComponentName/ComponentName.tsx
import { ComponentNameClient } from './index';

// 이 컴포넌트는 서버 컴포넌트로 작동 ('use client' 지시어 없음)
export default async function ComponentName(props) {
  // 서버에서 데이터 페칭
  const data = await fetchData();
  
  // 데이터를 클라이언트 컴포넌트로 전달
  return <ComponentNameClient initialData={data} {...props} />;
}
```

### 2. 클라이언트 컴포넌트

```tsx
// ComponentName/ComponentNameClient.tsx
'use client';

import { useState, useEffect } from 'react';

export default function ComponentNameClient({ initialData, ...props }) {
  // 클라이언트 상태 및 이벤트 처리
  const [data, setData] = useState(initialData);
  
  // 클라이언트 측 로직...
  
  return (
    <div>
      {/* 인터랙티브 UI */}
    </div>
  );
}
```

### 3. 인덱스 파일

```tsx
// ComponentName/index.ts
export { default } from './ComponentName';
export { default as ComponentNameClient } from './ComponentNameClient';
```

## 주의사항

1. 서버 컴포넌트는 클라이언트 컴포넌트를 가져와서 렌더링할 수 있지만, 그 반대는 불가능합니다.
2. 데이터 페칭은 가능한 한 서버 컴포넌트에서 수행하세요.
3. 클라이언트 컴포넌트는 필요한 최소한의 기능만 포함하도록 하세요.
4. 공유 컴포넌트를 중첩해서 사용할 때는 데이터 흐름 방향에 주의하세요.

## 예시 컴포넌트

현재 공유 컴포넌트 예시:

- `VoteDetail`: 투표 상세 정보를 보여주는 컴포넌트
- `VoteList`: 투표 목록을 보여주는 컴포넌트
- `AuthCallback`: 소셜 로그인 콜백 처리 컴포넌트

각 컴포넌트의 사용법과 세부 구현은 해당 컴포넌트 디렉토리의 파일을 참조하세요. 