import { LoadingState } from '@/components/server';

/**
 * 투표 상세 페이지의 로딩 상태 컴포넌트
 * 
 * 투표 데이터를 불러오는 동안 표시될 로딩 인디케이터입니다.
 */
export default function VoteDetailLoading() {
  return <LoadingState message="투표 정보를 불러오는 중입니다..." fullPage size="large" />;
} 