/**
 * Supabase 클라이언트 및 서버 구현을 위한 중앙 인덱스 파일
 * 
 * 이 파일은 서버 및 클라이언트 측 Supabase 구현을 하나의 위치에서 내보냅니다.
 * 
 * 브라우저에서 사용할 때:
 * ```typescript
 * 'use client';
 * import { createBrowserSupabaseClient } from '@/lib/supabase';
 * ```
 * 
 * 서버 컴포넌트에서 사용할 때: 
 * ```typescript
 * import { createServerSupabaseClient } from '@/lib/supabase';
 * ```
 */

// 서버 측 Supabase 구현을 가져옵니다.
import {
  createServerSupabaseClient,
  getServerSession,
  getServerUser,
  withAuth
} from './server';

// 브라우저 측 Supabase 구현을 가져옵니다.
import {
  createBrowserSupabaseClient,
  getCurrentUser,
  getCurrentSession,
  signOut
} from './client';

// 서버 측 Supabase 구현을 내보냅니다.
export {
  createServerSupabaseClient,
  getServerSession,
  getServerUser,
  withAuth
};

// 브라우저 측 Supabase 구현을 내보냅니다.
export {
  createBrowserSupabaseClient,
  getCurrentUser,
  getCurrentSession,
  signOut
};

// 공통 타입 정의를 내보냅니다.
export type { Database } from '@/types/supabase';

// 편의성을 위해 별칭 제공
export const createClient = createBrowserSupabaseClient;
export const createServerClient = createServerSupabaseClient; 