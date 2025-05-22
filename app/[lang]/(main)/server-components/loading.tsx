import { LoadingState } from '@/components/server';

/**
 * 서버 컴포넌트 데모 페이지의 로딩 상태 컴포넌트
 */
export default function ServerComponentsLoading() {
  return <LoadingState message="데모 페이지를 준비하는 중입니다..." fullPage size="large" />;
} 