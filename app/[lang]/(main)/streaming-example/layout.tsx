import React from 'react';
import Link from 'next/link';

/**
 * 스트리밍 데이터 로딩 예제 페이지 레이아웃
 */
export default function StreamingExampleLayout({
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
                  <Link href="/streaming-example" className="text-gray-600 hover:text-primary">
                    스트리밍 데이터
                  </Link>
                </li>
                <li>
                  <Link href="/vote" className="text-gray-600 hover:text-primary">
                    투표 목록
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