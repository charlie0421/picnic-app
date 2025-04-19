import { Gender } from '../utils/enums';
import { Database } from './supabase';

// Supabase users 테이블의 행 타입
export type User = Database['public']['Tables']['users']['Row'];

export interface UserInfo {
  id: string;
  email?: string | null;
  username?: string | null;
  displayName?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  gender?: Gender;
  isAdmin?: boolean | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

// Supabase users 행을 UserInfo로 변환하는 함수
export function mapUserFromSupabase(user: User): UserInfo {
  return {
    id: user.id,
    email: user.email,
    username: user.username,
    displayName: user.display_name,
    avatarUrl: user.avatar_url,
    bio: user.bio,
    isAdmin: user.is_admin,
    createdAt: user.created_at,
    updatedAt: user.updated_at,
  };
}

export interface AuthState {
  isAuthenticated: boolean;
  user: UserInfo | null;
  loading: boolean;
  error?: string | null;
} 