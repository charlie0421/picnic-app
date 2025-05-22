import React, { Suspense } from 'react';
import { getVotes } from '@/lib/data-fetching/vote-service';
import { LoadingState } from './index';
import { VoteListClient } from '@/components/client';

interface VoteListServerProps {
  status?: string;
  area?: string;
}

// 실제 데이터를 페칭하는 컴포넌트
async function VoteListContent({ status, area }: VoteListServerProps) {
  // 서버에서 데이터 페칭 (캐싱됨)
  const votes = await getVotes(status, area);
  
  // 클라이언트 컴포넌트에 데이터 전달
  return <VoteListClient initialVotes={votes} initialStatus={status || 'ongoing'} initialArea={area || 'kpop'} />;
}

// 외부에서 사용하는 메인 컴포넌트 (Suspense 포함)
export default function VoteListServer({ status, area }: VoteListServerProps) {
  return (
    <Suspense fallback={<LoadingState message="투표 목록을 불러오는 중..." />}>
      <VoteListContent status={status} area={area} />
    </Suspense>
  );
} 