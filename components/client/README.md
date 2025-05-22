# 클라이언트 컴포넌트

이 디렉토리는 Next.js의 클라이언트 컴포넌트를 위한 것입니다.

## 클라이언트 컴포넌트 정의

클라이언트 컴포넌트는 브라우저에서 실행되며 인터랙티브 기능을 제공합니다. 파일 상단에 `'use client'` 지시어를 반드시 포함해야 합니다.

## 사용 지침

클라이언트 컴포넌트는 다음과 같은 경우에 사용합니다:

- 사용자 이벤트 처리가 필요한 경우 (`onClick`, `onChange` 등)
- React 훅을 사용해야 하는 경우 (`useState`, `useEffect`, `useReducer` 등)
- 브라우저 전용 API를 사용해야 하는 경우 (localStorage, navigator 등)
- 클라이언트 측 라이브러리를 사용해야 하는 경우

## 주의사항

- 클라이언트 컴포넌트는 번들 크기에 영향을 미칩니다
- 서버 컴포넌트를 클라이언트 컴포넌트 내부에 중첩할 수 없습니다
- 데이터 페칭은 가능하면 서버 컴포넌트에서 처리하고, 초기 데이터를 props로 전달받는 것이 좋습니다

## 클라이언트 컴포넌트 작성 예시

```tsx
'use client'; // 반드시 파일 최상단에 배치

import { useState, useEffect } from 'react';

// Good - 클라이언트 컴포넌트 예시
export default function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);
  
  useEffect(() => {
    // 브라우저 API 사용
    document.title = `카운트: ${count}`;
  }, [count]);
  
  return (
    <div>
      <p>현재 카운트: {count}</p>
      <button onClick={() => setCount(count - 1)}>감소</button>
      <button onClick={() => setCount(count + 1)}>증가</button>
    </div>
  );
}

// Bad - 클라이언트 컴포넌트에서 서버 컴포넌트 가져오기 시도
import ServerComponent from '../server/ServerComponent';

export default function ClientWrapper() {
  // 오류: 클라이언트 컴포넌트 내에서 서버 컴포넌트를 직접 가져올 수 없습니다
  return (
    <div>
      <ServerComponent />
    </div>
  );
}
```

## 성능 최적화

클라이언트 컴포넌트는 번들 크기에 영향을 미치므로 다음과 같은 최적화를 고려하세요:

1. **코드 분할**
   ```tsx
   import dynamic from 'next/dynamic';
   
   // 동적 임포트로 코드 분할
   const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
     loading: () => <p>로딩 중...</p>
   });
   ```

2. **번들 크기 최소화**
   - 필요한 기능만 임포트
   - 큰 라이브러리는 부분적으로 임포트
   - 불필요한 의존성 제거

3. **메모이제이션**
   ```tsx
   import { memo, useMemo, useCallback } from 'react';
   
   // 컴포넌트 메모이제이션
   const MemoizedComponent = memo(MyComponent);
   
   // 계산 결과 메모이제이션
   const result = useMemo(() => expensiveCalculation(a, b), [a, b]);
   
   // 함수 메모이제이션
   const handleClick = useCallback(() => {
     // 핸들러 로직
   }, [dependency]);
   ```

## 컴포넌트 인덱스

모든 클라이언트 컴포넌트는 `index.ts` 파일에서 내보내야 합니다. 새로운 컴포넌트를 만들 때는 이 파일에도 추가하세요. 