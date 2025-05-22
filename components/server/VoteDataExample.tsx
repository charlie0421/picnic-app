import React from 'react';
import { notFound } from 'next/navigation';
import { getByIdOrNotFound, TABLES } from '@/lib/data-fetching/supabase-service';
import { AsyncBoundary, ErrorState, LoadingState } from '@/components/server';
import { AppError, ErrorCode } from '@/lib/supabase/error';

interface VoteDataProps {
  id: string;
}

// 투표 데이터 타입 정의
interface Vote {
  id: number;
  title: string;
  description: string;
  created_at: string;
  updated_at: string;
  [key: string]: any; // 추가 필드가 있을 수 있음
}

/**
 * 투표 데이터를 가져오는 서버 컴포넌트
 * 
 * 이 컴포넌트는 서버 컴포넌트에서 데이터 페칭과 오류 처리를 구현하는 패턴을 보여줍니다.
 */
async function VoteData({ id }: VoteDataProps) {
  try {
    // 404 처리가 포함된 데이터 조회 함수 사용
    // 데이터가 없으면 자동으로 notFound()가 호출됨
    const vote = await getByIdOrNotFound<Vote>(TABLES.VOTE, id);
    
    return (
      <div className="p-4 bg-white rounded-lg shadow">
        <h2 className="text-xl font-bold">{vote.title}</h2>
        <p className="mt-2 text-gray-600">{vote.description}</p>
        {/* 추가 투표 데이터 표시 */}
      </div>
    );
  } catch (error) {
    // AppError가 아닌 오류는 모두 UNKNOWN으로 처리
    if (!(error instanceof AppError)) {
      console.error('투표 데이터 조회 오류:', error);
      
      throw new AppError(
        '투표 데이터를 불러올 수 없습니다',
        ErrorCode.UNKNOWN,
        error,
        500
      );
    }
    
    // ErrorCode.NOT_FOUND 에러는 notFound()로 처리
    if (error.code === ErrorCode.NOT_FOUND) {
      notFound();
    }
    
    // 그 외 에러는 다시 throw하여 상위 컴포넌트의 error boundary에서 처리
    throw error;
  }
}

/**
 * 투표 데이터를 표시하는 예제 컴포넌트
 * 
 * AsyncBoundary를 사용하여 로딩 상태와 오류 상태를 처리합니다.
 */
export default function VoteDataExample({ id }: VoteDataProps) {
  return (
    <AsyncBoundary
      fallback={<LoadingState message="투표 데이터를 불러오는 중..." size="medium" />}
      errorFallback={(error) => (
        <ErrorState
          message={error.toFriendlyMessage()}
          code={error.status || 500}
          retryLink={`/vote/${id}`}
          retryLabel="다시 시도"
        />
      )}
    >
      <VoteData id={id} />
    </AsyncBoundary>
  );
} 