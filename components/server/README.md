# 서버 컴포넌트

이 디렉토리는 Next.js의 React Server Components를 위한 것입니다.

## 서버 컴포넌트 정의

서버 컴포넌트는 서버에서만 실행되고 클라이언트로 전송되지 않는 컴포넌트입니다. 이를 통해 다음과 같은 이점을 얻을 수 있습니다:

- 클라이언트 번들 크기 감소
- 초기 페이지 로드 속도 향상
- 서버 측 리소스에 직접 접근 가능
- 민감한 정보(API 키, 토큰 등)를 클라이언트에 노출하지 않음

## 사용 지침

서버 컴포넌트에서는 다음을 사용할 수 없습니다:

- 이벤트 핸들러 (`onClick`, `onChange` 등)
- React 훅 (`useState`, `useEffect`, `useContext` 등)
- 브라우저 전용 API (localStorage, navigator 등)

서버 컴포넌트에서는 다음을 할 수 있습니다:

- 데이터베이스나 API에 직접 접근
- 파일 시스템 접근
- 민감한 정보에 안전하게 접근
- 비동기 데이터 페칭 (`async/await` 사용)

## 네이밍 규칙

- `xxxServer.tsx`: 서버 컴포넌트의 주요 기능을 담당하는 파일
- `xxxSkeleton.tsx`: 로딩 상태를 위한 스켈레톤 UI 컴포넌트
- `LoadingState.tsx`: 재사용 가능한 로딩 표시 컴포넌트
- `ErrorState.tsx`: 재사용 가능한 오류 표시 컴포넌트

## 서버 컴포넌트 작성 예시

```tsx
// Good - 서버 컴포넌트 예시
export default async function ProductList() {
  const products = await getProducts();
  
  return (
    <div>
      <h1>제품 목록</h1>
      <ul>
        {products.map((product) => (
          <li key={product.id}>
            <ProductItem product={product} />
          </li>
        ))}
      </ul>
    </div>
  );
}

// Bad - 서버 컴포넌트에서 클라이언트 기능 사용 시도
export default function Counter() {
  // 오류: 서버 컴포넌트에서 useState를 사용할 수 없습니다
  const [count, setCount] = useState(0);
  
  // 오류: 서버 컴포넌트에서 이벤트 핸들러를 사용할 수 없습니다
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

## 컴포넌트 인덱스

모든 서버 컴포넌트는 `index.ts` 파일에서 내보내야 합니다. 새로운 컴포넌트를 만들 때는 이 파일에도 추가하세요.

## 데이터 페칭

서버 컴포넌트에서 데이터 페칭은 async/await를 직접 사용하거나 React Suspense와 함께 사용할 수 있습니다:

```tsx
// 직접 데이터 페칭
export default async function UserProfile({ userId }) {
  const user = await fetchUser(userId);
  return <div>{user.name}</div>;
}

// Suspense 사용
export default function UserProfile({ userId }) {
  return (
    <Suspense fallback={<LoadingState />}>
      <UserProfileData userId={userId} />
    </Suspense>
  );
}

async function UserProfileData({ userId }) {
  const user = await fetchUser(userId);
  return <div>{user.name}</div>;
}
``` 