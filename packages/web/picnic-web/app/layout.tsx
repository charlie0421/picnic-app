import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { AuthProvider } from '../contexts/AuthContext'
import { NavigationProvider } from '../contexts/NavigationContext'
import { LanguageProvider } from '../contexts/LanguageContext'
import Portal from '@/components/features/Portal'
import { redirect } from 'next/navigation'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Picnic Web',
  description: 'Picnic 웹 애플리케이션',
}

export default function RootLayout({
  children,
  params: { lang = 'ko' }
}: {
  children: React.ReactNode
  params: { lang?: string }
}) {
  // 홈 경로로 접근할 경우 투표 홈으로 리디렉션
  if (typeof window !== 'undefined' && window.location.pathname === '/') {
    redirect('/vote');
  }

  return (
    <html lang={lang}>
      <body className={inter.className}>
        <LanguageProvider>
          <AuthProvider>
            <NavigationProvider>
              <Portal>{children}</Portal>
            </NavigationProvider>
          </AuthProvider>
        </LanguageProvider>
      </body>
    </html>
  )
} 