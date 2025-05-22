import React, { Suspense } from 'react';
import { LoadingState } from '@/components/server';
import { getById, getList, TABLES } from '@/lib/data-fetching/supabase-service';

/**
 * 중첩된 Suspense 경계를 활용한 계층적 데이터 로딩 패턴
 * 
 * 이 컴포넌트는 메인 데이터를 먼저 로드한 후, 관련된 상세 데이터를 로드하는
 * 계층적 데이터 로딩 패턴을 보여줍니다.
 */

// 투표 데이터 타입
interface Vote {
  id: number;
  title: string;
  description: string;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

// 투표 항목 데이터 타입
interface VoteItem {
  id: number;
  vote_id: number;
  title: string;
  image_url?: string;
  votes_count: number;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

/**
 * 투표 정보를 가져오는 컴포넌트
 */
async function VoteHeader({ id }: { id: string }) {
  // 투표 기본 정보 조회
  const vote = await getById<Vote>(TABLES.VOTE, id);
  
  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold">{vote.title}</h1>
      <p className="text-gray-600 mt-2">{vote.description}</p>
      <div className="text-xs text-gray-500 mt-1">
        생성일: {new Date(vote.created_at).toLocaleDateString()}
      </div>
    </div>
  );
}

/**
 * 투표 항목들을 가져오는 컴포넌트
 */
async function VoteItems({ voteId }: { voteId: string }) {
  // 투표 항목 조회
  const items = await getList<VoteItem>(TABLES.VOTE_ITEM, {
    filters: { vote_id: voteId },
    orderBy: { column: 'votes_count', ascending: false }
  });
  
  return (
    <div className="mt-4">
      <h2 className="text-xl font-semibold mb-4">투표 항목</h2>
      {items.length === 0 ? (
        <p className="text-gray-500">등록된 투표 항목이 없습니다.</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {items.map(item => (
            <div key={item.id} className="bg-white p-4 rounded-lg shadow">
              <h3 className="font-semibold">{item.title}</h3>
              {item.image_url && (
                <div className="mt-2 h-32 bg-gray-100 flex items-center justify-center rounded">
                  <span className="text-sm text-gray-500">이미지: {item.image_url}</span>
                </div>
              )}
              <div className="mt-2 flex justify-between items-center">
                <span className="text-sm">득표수</span>
                <span className="font-bold">{item.votes_count}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/**
 * 투표 결과 통계를 가져오는 컴포넌트
 */
async function VoteStats({ voteId }: { voteId: string }) {
  // 복잡한 집계 쿼리를 시뮬레이션
  // 실제로는 더 복잡한 데이터 처리나 집계 함수 호출이 있을 수 있음
  const items = await getList<VoteItem>(TABLES.VOTE_ITEM, {
    filters: { vote_id: voteId },
    orderBy: { column: 'votes_count', ascending: false }
  });
  
  const totalVotes = items.reduce((sum, item) => sum + item.votes_count, 0);
  const maxVotes = Math.max(...items.map(item => item.votes_count));
  const avgVotes = totalVotes / (items.length || 1);
  
  return (
    <div className="mt-8 bg-white p-4 rounded-lg shadow">
      <h2 className="text-xl font-semibold mb-4">투표 통계</h2>
      <div className="grid grid-cols-3 gap-4 text-center">
        <div className="p-3 bg-blue-50 rounded">
          <div className="text-sm text-gray-600">총 투표수</div>
          <div className="text-xl font-bold text-blue-600">{totalVotes}</div>
        </div>
        <div className="p-3 bg-green-50 rounded">
          <div className="text-sm text-gray-600">최다 득표</div>
          <div className="text-xl font-bold text-green-600">{maxVotes}</div>
        </div>
        <div className="p-3 bg-purple-50 rounded">
          <div className="text-sm text-gray-600">평균 득표</div>
          <div className="text-xl font-bold text-purple-600">{avgVotes.toFixed(1)}</div>
        </div>
      </div>
    </div>
  );
}

/**
 * 관련 투표 추천 컴포넌트
 */
async function RelatedVotes({ voteId }: { voteId: string }) {
  // 관련 투표 목록 조회 (현재 투표 제외)
  const votes = await getList<Vote>(TABLES.VOTE, {
    filters: { id: { neq: voteId } },
    orderBy: { column: 'created_at', ascending: false },
    limit: 3
  });
  
  if (votes.length === 0) {
    return null;
  }
  
  return (
    <div className="mt-8">
      <h2 className="text-xl font-semibold mb-4">관련 투표</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {votes.map(vote => (
          <div key={vote.id} className="bg-white p-4 rounded-lg shadow">
            <h3 className="font-semibold">{vote.title}</h3>
            <p className="text-sm text-gray-600 mt-1 line-clamp-2">{vote.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * 중첩된 Suspense를 사용한 투표 상세 페이지 컴포넌트
 * 
 * 이 컴포넌트는 중요한 정보부터 점진적으로 로드하는 패턴을 보여줍니다.
 * 1. 기본 투표 정보 (가장 중요함, 즉시 로드)
 * 2. 투표 항목 목록 (중요도 높음, 기본 정보 다음에 로드)
 * 3. 투표 통계 (중요도 중간, 기본 정보와 항목 로드 후 표시)
 * 4. 관련 투표 (중요도 낮음, 가장 마지막에 로드)
 */
export default function NestedDataFetching({ voteId = '1' }: { voteId?: string }) {
  return (
    <div className="container mx-auto p-4 max-w-4xl">
      {/* 가장 중요한 데이터: 기본 투표 정보 */}
      <Suspense fallback={<LoadingState message="투표 정보를 불러오는 중..." size="medium" />}>
        <VoteHeader id={voteId} />
        
        {/* 두 번째로 중요한 데이터: 투표 항목 */}
        <Suspense fallback={<LoadingState message="투표 항목을 불러오는 중..." size="small" />}>
          <VoteItems voteId={voteId} />
          
          {/* 세 번째로 중요한 데이터: 통계 */}
          <Suspense fallback={<LoadingState message="투표 통계를 계산하는 중..." size="small" />}>
            <VoteStats voteId={voteId} />
            
            {/* 가장 덜 중요한 데이터: 관련 투표 */}
            <Suspense fallback={<LoadingState message="관련 투표를 불러오는 중..." size="small" />}>
              <RelatedVotes voteId={voteId} />
            </Suspense>
          </Suspense>
        </Suspense>
      </Suspense>
    </div>
  );
} 