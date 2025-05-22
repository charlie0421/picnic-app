import AuthCallback from '@/components/shared/AuthCallback';

// 타입 정의 수정
type PageProps = {
  params: { provider: string };
};

/**
 * 소셜 로그인 콜백 페이지
 * 
 * 이 페이지는 서버 컴포넌트로 구현되고,
 * 필요한 인증 로직은 클라이언트 컴포넌트로 분리되어 있습니다.
 */
export default function AuthCallbackPage({ params }: PageProps) {
  return <AuthCallback provider={params.provider} />;
} 