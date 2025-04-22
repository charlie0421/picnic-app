'use client';

import { useRouter } from 'next/navigation';

export default function ErrorPage() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg">
        <div className="text-center">
          <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
            로그인 오류
          </h2>
          <p className="mt-2 text-sm text-gray-600">
            로그인 과정에서 오류가 발생했습니다. 다시 시도해주세요.
          </p>
        </div>
        <div className="mt-8">
          <button
            onClick={() => router.push('/auth/login')}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            다시 시도하기
          </button>
        </div>
      </div>
    </div>
  );
} 