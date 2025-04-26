'use client';

import { AuthProvider } from '@/contexts/AuthContext';

export default function DashboardTemplate({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AuthProvider>{children}</AuthProvider>;
}