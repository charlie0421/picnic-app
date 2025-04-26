'use client';

import { AuthProvider } from '@/contexts/AuthContext';
import { useEffect } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase';

export default function AuthWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  useEffect(() => {
    createBrowserSupabaseClient();
  }, []);

  return <AuthProvider>{children}</AuthProvider>;
} 