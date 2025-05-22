# 서버 컴포넌트 데이터 페칭 가이드

이 문서는 Picnic 웹 프로젝트의 서버 컴포넌트 데이터 페칭 패턴과 최적화 방법을 설명합니다.

## 목차

1. [데이터 페칭 유틸리티](#데이터-페칭-유틸리티)
2. [캐싱과 재검증](#캐싱과-재검증)
3. [병렬 데이터 로딩](#병렬-데이터-로딩)
4. [중첩된 데이터 로딩](#중첩된-데이터-로딩)
5. [서버-클라이언트 데이터 전달](#서버-클라이언트-데이터-전달)
6. [프리페칭](#프리페칭)
7. [성능 최적화 팁](#성능-최적화-팁)
8. [에러 처리](#에러-처리)

## 데이터 페칭 유틸리티

`lib/data-fetching/supabase-service.ts` 파일에는 서버 컴포넌트에서 데이터를 가져오기 위한 유틸리티 함수들이 포함되어 있습니다.

### 주요 함수

```typescript
// 단일 레코드 조회 (ID로)
const data = await getById(TABLES.VOTE, '123');

// 레코드 목록 조회 (필터링, 정렬, 페이지네이션 지원)
const votes = await getList(TABLES.VOTE, {
  filters: { 
    deleted_at: { is: null },
    vote_category: 'kpop'
  },
  orderBy: { column: 'created_at', ascending: false },
  limit: 10,
  offset: 0
});

// 커스텀 쿼리 실행
const data = await executeCustomQuery(async (supabase) => {
  const { data, error } = await supabase
    .from('vote')
    .select(`
      *,
      vote_item!vote_id (
        id,
        vote_id,
        artist_id,
        artist (*)
      )
    `)
    .eq('id', id);
    
  return { data, error };
});

// RPC 함수 호출
const userVote = await callRpc('get_user_vote', { 
  p_vote_id: '123', 
  p_user_id: userId 
});
```

### 데이터 변경 함수

```typescript
// 레코드 생성
const newVote = await createRecord(TABLES.VOTE, voteData, '/votes');

// 레코드 업데이트
const updatedVote = await updateRecord(TABLES.VOTE, '123', updateData, '/votes/123');

// 레코드 삭제
await deleteRecord(TABLES.VOTE, '123', '/votes');
```

## 캐싱과 재검증

Next.js 서버 컴포넌트는 데이터 페칭 결과를 자동으로 캐싱합니다. 이 프로젝트에서는 다음과 같은 캐싱 전략을 사용합니다:

1. **React.cache**: 동일한 렌더링 패스 내에서 중복 요청 방지
2. **unstable_cache**: 요청 간 캐싱, 세부적인 캐시 제어 가능
3. **revalidatePath**: 데이터 변경 시 특정 경로의 캐시 무효화

```typescript
// React.cache를 사용한 데이터 페칭 함수
export const getById = cache(async function getById<T>(
  table: string,
  id: string | number
): Promise<T | null> {
  // ...
});

// unstable_cache로 캐시 태그와 재검증 주기 설정
return unstable_cache(
  async () => {
    // 데이터 페칭 로직
  },
  [`${table}_${id}`],
  {
    tags: [`table:${table}`, `${table}:${id}`],
    revalidate: 60, // 1분 후 캐시 만료
  }
)();

// 데이터 변경 시 캐시 무효화
export async function updateRecord<T>(
  table: string,
  id: string | number,
  data: Partial<T>,
  pathToRevalidate?: string
): Promise<T> {
  // 업데이트 로직
  
  // 캐시 무효화
  if (pathToRevalidate) {
    revalidatePath(pathToRevalidate);
  }
  
  return updatedRecord as T;
}
```

### 캐시 태그

데이터는 다음과 같은 태그를 사용하여 캐싱됩니다:

- `table:{테이블명}`: 특정 테이블의 모든 데이터
- `{테이블명}:{id}`: 특정 레코드
- `{테이블명}:filters:{필터키}`: 특정 필터를 적용한 쿼리
- `rpc:{함수명}`: 특정 RPC 함수 호출

## 병렬 데이터 로딩

서버 컴포넌트에서 여러 데이터를 병렬로 로딩하는 패턴입니다:

```tsx
// ParallelDataFetching.tsx
export default function ParallelDataFetchingPage() {
  return (
    <div>
      <Suspense fallback={<LoadingState message="투표 로딩 중..." />}>
        <VoteListSection />
      </Suspense>
      
      <Suspense fallback={<LoadingState message="미디어 로딩 중..." />}>
        <MediaListSection />
      </Suspense>
      
      <Suspense fallback={<LoadingState message="보상 로딩 중..." />}>
        <RewardListSection />
      </Suspense>
    </div>
  );
}
```

이 패턴은 한 섹션의 데이터 로딩이 다른 섹션을 차단하지 않도록 합니다. 각 Suspense 경계가 독립적으로 데이터를 로드하고 자체 로딩 상태를 보여줍니다.

## 중첩된 데이터 로딩

중첩된 Suspense 경계를 사용하여 계층적 데이터를 로드하는 패턴입니다:

```tsx
// NestedDataFetching.tsx
export default function VoteDetailPage({ id }: { id: string }) {
  return (
    <div className="vote-detail">
      <Suspense fallback={<LoadingState message="기본 정보 로딩 중..." />}>
        <VoteHeader id={id} />
        
        <Suspense fallback={<LoadingState message="투표 항목 로딩 중..." />}>
          <VoteItems voteId={id} />
          
          <Suspense fallback={<LoadingState message="보상 정보 로딩 중..." />}>
            <VoteRewards voteId={id} />
          </Suspense>
        </Suspense>
      </Suspense>
    </div>
  );
}
```

이 패턴은 주요 데이터가 먼저 로드되고 화면에 표시되며, 상세 데이터는 이후에 로드됩니다. 사용자는 전체 페이지가 로드될 때까지 기다리지 않고 점진적으로 콘텐츠를 볼 수 있습니다.

## 서버-클라이언트 데이터 전달

서버 컴포넌트에서 클라이언트 컴포넌트로 데이터를 전달하는 패턴입니다:

```tsx
// ServerClientBoundary.tsx
async function VoteDataProvider() {
  // 서버에서 데이터 가져오기
  const votes = await getList<Vote>(TABLES.VOTE, {
    orderBy: { column: 'created_at', ascending: false },
    limit: 5
  });
  
  // 데이터를 클라이언트 컴포넌트로 전달
  return <VoteClientComponent votes={votes} />;
}
```

이 패턴은 다음과 같은 이점이 있습니다:

1. 데이터 페칭은 서버에서 발생하므로 클라이언트 번들 크기 감소
2. 서버-클라이언트 컴포넌트 경계가 명확하게 분리됨
3. 클라이언트 컴포넌트는 상호작용만 담당하고 데이터 페칭 로직 없음

## 프리페칭

사용자가 방문할 가능성이 높은 페이지의 데이터를 미리 가져와 캐시에 저장하는 기능입니다:

```tsx
import { prefetchRecord, prefetchList } from '@/lib/data-fetching/supabase-service';

// 링크 호버 시 데이터 프리페치
<Link 
  href={`/vote/${vote.id}`}
  onMouseEnter={() => prefetchRecord(TABLES.VOTE, vote.id)}
>
  {vote.title}
</Link>

// 목록 데이터 프리페치
useEffect(() => {
  prefetchList(TABLES.VOTE, {
    filters: { status: 'active' },
    limit: 10
  });
}, []);
```

프리페칭은 사용자 경험을 크게 향상시킬 수 있습니다. 사용자가 링크를 클릭하거나 페이지를 방문할 때 이미 데이터가 캐시되어 있으므로 로딩 시간이 감소합니다.

## 성능 최적화 팁

1. **적절한 Suspense 경계 설정**
   - 너무 많은 Suspense 경계는 오버헤드를 발생시킴
   - 너무 적은 Suspense 경계는 워터폴 효과 발생
   - 관련 데이터 그룹에 대해 Suspense 경계 설정

2. **워터폴 방지**
   - 부모 컴포넌트에서 자식 컴포넌트가 필요한 데이터를 미리 로드
   - Promise.all을 사용하여 여러 데이터를 병렬로 로드

   ```tsx
   async function VoteWithItems({ id }: { id: string }) {
     // 워터폴 방지를 위해 병렬로 데이터 로드
     const [vote, voteItems] = await Promise.all([
       getById(TABLES.VOTE, id),
       getList(TABLES.VOTE_ITEM, { filters: { vote_id: id } })
     ]);
     
     return (
       <div>
         <VoteHeader vote={vote} />
         <VoteItemsList items={voteItems} />
       </div>
     );
   }
   ```

3. **적절한 캐시 무효화**
   - 불필요한 revalidatePath 호출 방지
   - 구체적인 경로 패턴 사용 (전체 앱 대신 특정 페이지 무효화)

4. **데이터 과도 페칭 방지**
   - 필요한 필드만 선택 (select 쿼리 최적화)
   - 페이지네이션 사용 (limit/offset)
   - 필터링은 서버에서 수행 (클라이언트에서 필터링하지 않음)

5. **정적 렌더링 활용**
   - 자주 변경되지 않는 데이터는 빌드 시점에 생성
   - generateStaticParams 활용

## 에러 처리

서버 컴포넌트에서 에러 처리는 다음과 같은 방법으로 구현됩니다:

1. **error.tsx 파일**: 라우트 세그먼트의 에러 처리
2. **not-found.tsx 파일**: 데이터가 없을 때 404 페이지 표시
3. **AsyncBoundary 컴포넌트**: 데이터 로딩과 에러 처리를 결합한 래퍼 컴포넌트

```tsx
// AsyncBoundary 사용 예시
<AsyncBoundary
  errorFallback={<ErrorState message="투표 데이터를 불러오는 중 오류가 발생했습니다." />}
  notFoundFallback={<NotFoundState message="요청한 투표를 찾을 수 없습니다." />}
  loadingFallback={<LoadingState message="투표 데이터를 불러오는 중..." />}
>
  <VoteDetail id={id} />
</AsyncBoundary>
```

## 결론

이 문서에서 설명한 패턴과 최적화 기법을 따르면 서버 컴포넌트를 사용하여 효율적이고 성능이 좋은 데이터 페칭을 구현할 수 있습니다. 서버 컴포넌트는 데이터 페칭, 캐싱, 점진적 로딩을 위한 강력한 도구를 제공하며, 이를 통해 사용자 경험을 크게 향상시킬 수 있습니다. 