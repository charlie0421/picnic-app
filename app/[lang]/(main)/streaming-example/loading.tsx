import { LoadingState } from '@/components/server';

/**
 * 스트리밍 데이터 로딩 예제 페이지의 로딩 상태 컴포넌트
 */
export default function StreamingExampleLoading() {
  return <LoadingState message="페이지를 준비하는 중입니다..." fullPage size="large" />;
} 