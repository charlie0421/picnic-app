# URL 파라메터 저장 기능 가이드

리스트 컴포넌트에서 필터링이나 검색 상태를 URL 파라메터로 저장하여 페이지 이동 후에도 상태를 유지할 수 있습니다.

## 기본 사용법

### 1. 필요한 Next.js Navigation 훅 가져오기

```tsx
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
```

### 2. 훅 설정 및 초기값 가져오기

```tsx
const searchParams = useSearchParams();
const pathname = usePathname();
const router = useRouter();

// URL에서 파라미터 가져오기
const urlSearch = searchParams.get('search') || '';
const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
```

### 3. URL 파라미터 업데이트 함수 추가

```tsx
const updateUrlParams = (search: string) => {
  const params = new URLSearchParams(searchParams.toString());
  
  if (!search) {
    params.delete('search');
  } else {
    params.set('search', search);
  }
  
  router.push(`${pathname}?${params.toString()}`);
};
```

### 4. 상태 변경 시 URL 업데이트

```tsx
const handleSearch = (value: string) => {
  setSearchTerm(value);
  updateUrlParams(value);
};
```

### 5. URL 상태 변경 시 컴포넌트 상태 업데이트

```tsx
useEffect(() => {
  if (urlSearch) {
    setSearchTerm(urlSearch);
  }
}, [urlSearch]);
```

## 여러 파라미터 사용 예시

여러 필터 파라미터를 사용할 경우 updateUrlParams 함수를 확장하여 사용할 수 있습니다:

```tsx
const updateUrlParams = (params: { search?: string; status?: string }) => {
  const urlParams = new URLSearchParams(searchParams.toString());
  
  // 검색어 업데이트
  if (params.search !== undefined) {
    if (!params.search) {
      urlParams.delete('search');
    } else {
      urlParams.set('search', params.search);
    }
  }
  
  // 상태 필터 업데이트
  if (params.status !== undefined) {
    if (params.status === 'all') {
      urlParams.delete('status');
    } else {
      urlParams.set('status', params.status);
    }
  }
  
  router.push(`${pathname}?${urlParams.toString()}`);
};
```

## 템플릿 컴포넌트

다음 템플릿 컴포넌트들이 URL 파라메터 저장 기능을 포함하고 있습니다:

1. `ResourceList.tsx` - 검색 기능이 있는 기본 리스트 컴포넌트
2. `ResourceListWithStatusFilter.tsx` - 검색과 상태 필터링이 있는 리스트 컴포넌트

이 템플릿들을 활용하여 새로운 리스트 컴포넌트를 작성하거나 기존 컴포넌트에 URL 파라메터 저장 기능을 추가할 수 있습니다. 