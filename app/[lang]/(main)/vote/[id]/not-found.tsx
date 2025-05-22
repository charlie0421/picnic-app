import { NotFoundState } from '@/components/server';

/**
 * 투표 상세 페이지의 Not Found 컴포넌트
 * 
 * 투표 데이터를 찾을 수 없을 때 사용자에게 친절한 메시지를 표시합니다.
 */
export default function VoteNotFound() {
  return (
    <NotFoundState 
      title="투표를 찾을 수 없습니다"
      message="요청하신 투표가 존재하지 않거나 삭제되었습니다."
      backLink="/vote"
      backLabel="투표 목록으로 돌아가기"
    />
  );
} 