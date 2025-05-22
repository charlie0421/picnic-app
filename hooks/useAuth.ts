'use client';

// 통합된 AuthProvider에서 내보내는 useAuth 훅을 다시 내보냅니다.
export { useAuth } from '@/lib/supabase/auth-provider';

// 이 파일은 뒤 호환성을 위해 사용됩니다.
// VoteDetailContent.tsx와 같은 컴포넌트가 이 경로에서 useAuth를 가져오기 때문에 보존합니다.
