import React, { Suspense } from 'react';
import { getList, TABLES } from '@/lib/data-fetching/supabase-service';
import { LoadingState } from '@/components/server';
import VoteClientComponent from '@/components/client/VoteClientComponent';

/**
 * 서버-클라이언트 컴포넌트 경계 패턴
 * 
 * 이 패턴은 서버 컴포넌트에서 데이터를 가져오고
 * 클라이언트 컴포넌트로 props를 통해 전달하는 방법을 보여줍니다.
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

/**
 * 투표 데이터를 가져오고 클라이언트 컴포넌트로 전달하는 서버 컴포넌트
 */
async function VoteDataProvider() {
  // 서버에서 데이터 가져오기
  const votes = await getList<Vote>(TABLES.VOTE, {
    orderBy: { column: 'created_at', ascending: false },
    limit: 5
  });
  
  // 데이터를 클라이언트 컴포넌트로 직렬화 가능한 형태로 전달
  return <VoteClientComponent votes={votes} />;
}

/**
 * 서버-클라이언트 컴포넌트 경계 컴포넌트
 * 
 * 이 컴포넌트는 서버에서 데이터를 가져와서 클라이언트 컴포넌트로 전달하는
 * 패턴을 보여줍니다. Suspense를 사용하여 데이터 로딩 상태를 처리합니다.
 */
export default function ServerClientBoundary() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-6">서버-클라이언트 컴포넌트 경계 예제</h1>
      
      <Suspense fallback={<LoadingState message="투표 데이터를 불러오는 중..." size="medium" />}>
        <VoteDataProvider />
      </Suspense>
    </div>
  );
} 