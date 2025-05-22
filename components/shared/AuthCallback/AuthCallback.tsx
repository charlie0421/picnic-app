import { AuthCallbackClient } from './index';

interface AuthCallbackProps {
  provider: string;
}

/**
 * AuthCallback 공유 컴포넌트
 * 
 * 이 컴포넌트는 서버 컴포넌트와 클라이언트 컴포넌트 사이의 브릿지 역할을 합니다.
 * 서버에서는 provider 정보를 클라이언트로 전달하고, 
 * 클라이언트에서는 인증 로직을 처리합니다.
 */
export default function AuthCallback({ provider }: AuthCallbackProps) {
  return <AuthCallbackClient provider={provider} />;
} 