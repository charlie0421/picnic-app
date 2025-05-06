import { Suspense } from 'react';
import LoginContentInner from './LoginContentInner';

interface LoginContentProps {
  sdkScriptLoaded: boolean;
}

export default function LoginContent({ sdkScriptLoaded }: LoginContentProps) {
  return (
    <Suspense fallback={
      <div className='min-h-screen flex items-center justify-center bg-gray-50'>
        <div className='max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow-lg'>
          <div className='flex flex-col items-center justify-center py-8'>
            <div className='animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary-500 mb-4'></div>
            <p className='text-gray-600'>로딩 중...</p>
          </div>
        </div>
      </div>
    }>
      <LoginContentInner sdkScriptLoaded={sdkScriptLoaded} />
    </Suspense>
  );
} 