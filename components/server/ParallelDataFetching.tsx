import React, { Suspense } from 'react';
import { LoadingState } from '@/components/server';
import { getList, TABLES } from '@/lib/data-fetching/supabase-service';

/**
 * 병렬 데이터 페칭 패턴
 * 
 * 서버 컴포넌트에서 여러 데이터를 병렬로 가져오는 패턴을 보여주는 컴포넌트입니다.
 * React Suspense를 사용하여 각 데이터 로딩 상태를 독립적으로 처리합니다.
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

// 미디어 데이터 타입
interface Media {
  id: number;
  title: string;
  url: string;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

// 보상 데이터 타입
interface Reward {
  id: number;
  title: string;
  description: string;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

/**
 * 투표 데이터를 가져오는 컴포넌트
 */
async function VoteListSection() {
  // 투표 데이터 조회 (느린 네트워크 시뮬레이션)
  const votes = await getList<Vote>(TABLES.VOTE, {
    orderBy: { column: 'created_at', ascending: false },
    limit: 5
  });
  
  return (
    <div className="mb-8 bg-white p-4 rounded-lg shadow">
      <h2 className="text-xl font-bold mb-4">최근 투표</h2>
      {votes.length === 0 ? (
        <p className="text-gray-500">표시할 투표가 없습니다.</p>
      ) : (
        <ul className="space-y-2">
          {votes.map(vote => (
            <li key={vote.id} className="border-b pb-2">
              <h3 className="font-semibold">{vote.title}</h3>
              <p className="text-sm text-gray-600">{vote.description}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/**
 * 미디어 데이터를 가져오는 컴포넌트
 */
async function MediaSection() {
  // 미디어 데이터 조회
  const media = await getList<Media>(TABLES.MEDIA, {
    orderBy: { column: 'created_at', ascending: false },
    limit: 5
  });
  
  return (
    <div className="mb-8 bg-white p-4 rounded-lg shadow">
      <h2 className="text-xl font-bold mb-4">최근 미디어</h2>
      {media.length === 0 ? (
        <p className="text-gray-500">표시할 미디어가 없습니다.</p>
      ) : (
        <div className="grid grid-cols-2 gap-4">
          {media.map(item => (
            <div key={item.id} className="bg-gray-100 p-2 rounded">
              <h3 className="font-semibold">{item.title}</h3>
              <p className="text-xs text-gray-600 truncate">{item.url}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/**
 * 보상 데이터를 가져오는 컴포넌트
 */
async function RewardSection() {
  // 보상 데이터 조회
  const rewards = await getList<Reward>(TABLES.REWARD, {
    orderBy: { column: 'created_at', ascending: false },
    limit: 5
  });
  
  return (
    <div className="mb-8 bg-white p-4 rounded-lg shadow">
      <h2 className="text-xl font-bold mb-4">최근 보상</h2>
      {rewards.length === 0 ? (
        <p className="text-gray-500">표시할 보상이 없습니다.</p>
      ) : (
        <ul className="space-y-2">
          {rewards.map(reward => (
            <li key={reward.id} className="border-b pb-2">
              <h3 className="font-semibold">{reward.title}</h3>
              <p className="text-sm text-gray-600">{reward.description}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/**
 * 병렬 데이터 페칭 예제 컴포넌트
 * 
 * 이 컴포넌트는 여러 독립적인 데이터 소스를 동시에 가져오는 방법을 보여줍니다.
 * 각 섹션은 별도의 Suspense 경계로 감싸져 있어 하나의 데이터 로딩이 지연되더라도
 * 다른 섹션은 정상적으로 표시됩니다.
 */
export default function ParallelDataFetching() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-6">대시보드</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* 투표 섹션 - 독립적인 Suspense 경계 */}
        <Suspense fallback={<LoadingState message="투표 데이터 로딩 중..." size="small" />}>
          <VoteListSection />
        </Suspense>
        
        {/* 미디어 섹션 - 독립적인 Suspense 경계 */}
        <Suspense fallback={<LoadingState message="미디어 데이터 로딩 중..." size="small" />}>
          <MediaSection />
        </Suspense>
      </div>
      
      {/* 보상 섹션 - 독립적인 Suspense 경계 */}
      <Suspense fallback={<LoadingState message="보상 데이터 로딩 중..." size="small" />}>
        <RewardSection />
      </Suspense>
    </div>
  );
} 