import React from 'react';
import { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { Toaster } from '@/components/ui/toaster';
import { ThemeProvider } from '@/components/features/theme-provider';
import { AuthProvider } from '@/contexts/auth-context';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/header';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: '관리자 시스템',
  description: '관리자 시스템',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang='ko' suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider
          attribute='class'
          defaultTheme='system'
          enableSystem
          disableTransitionOnChange
        >
          <AuthProvider>
            <div className='flex min-h-screen'>
              <Sidebar />
              <div className='flex-1'>
                <Header />
                <main className='p-8'>{children}</main>
              </div>
            </div>
            <Toaster />
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
