import React from 'react';
import Link from 'next/link';

/**
 * 서버 컴포넌트 데모 페이지 레이아웃
 */
export default function ServerComponentsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow">
        <div className="container mx-auto p-4">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold">서버 컴포넌트 데모</h1>
            <nav>
              <ul className="flex gap-6">
                <li>
                  <Link href="/" className="text-gray-600 hover:text-primary">
                    홈
                  </Link>
                </li>
                <li>
                  <Link href="/server-components" className="text-gray-600 hover:text-primary">
                    데모 홈
                  </Link>
                </li>
                <li>
                  <Link href="/streaming-example" className="text-gray-600 hover:text-primary">
                    스트리밍 예제
                  </Link>
                </li>
              </ul>
            </nav>
          </div>
        </div>
      </div>
      {children}
    </div>
  );
} 