'use client';

import React from 'react';
import { AuthProvider } from '@/contexts/AuthContext';
import Footer from '@/components/layouts/Footer';

export default function MainLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <div className='min-h-screen flex flex-col'>
        <main className='flex-grow'>
          {children}
        </main>
        <Footer />
      </div>
    </AuthProvider>
  );
} 