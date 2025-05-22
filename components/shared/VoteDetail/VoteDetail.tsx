import { VoteDetailServer } from '@/components/server';

interface VoteDetailProps {
  id: string;
}

/**
 * VoteDetail 공유 컴포넌트
 * 
 * 이 컴포넌트는 서버 컴포넌트와 클라이언트 컴포넌트 사이의 브릿지 역할을 합니다.
 * 페이지에서는 이 컴포넌트를 사용하여 필요한 데이터를 서버에서 가져오고
 * 클라이언트 측 상호작용을 처리합니다.
 */
export default function VoteDetail({ id }: VoteDetailProps) {
  return <VoteDetailServer id={id} />;
} 