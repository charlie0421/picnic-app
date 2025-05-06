import Image from 'next/image';
import { SocialProvider } from '../types/auth';

interface LoginFormProps {
  error: string | null;
  loading: boolean;
  t: (key: string) => string;
  onLogin: (provider: SocialProvider) => void;
}

export default function LoginForm({ error, loading, t, onLogin }: LoginFormProps) {
  if (loading) {
    return (
      <div className='flex flex-col items-center justify-center py-8'>
        <div className='animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary-500 mb-4'></div>
        <p className='text-gray-600'>로그인 처리 중...</p>
      </div>
    );
  }

  return (
    <div className='mt-8 space-y-4'>
      <button
        onClick={() => onLogin('google')}
        disabled={loading}
        className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed'
      >
        <Image
          src='/images/auth/google-logo.svg'
          alt={`Google ${t('button_login')}`}
          width={20}
          height={20}
          className='mr-2'
        />
        Google {t('button_continue_with')}
      </button>

      <button
        onClick={() => onLogin('apple')}
        disabled={loading}
        className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-black border border-gray-300 rounded-md hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed'
        aria-label='Apple 계정으로 계속하기'
      >
        <Image
          src='/images/auth/apple-logo.svg'
          alt={`Apple ${t('button_login')}`}
          width={20}
          height={20}
          className='mr-2'
        />
        Apple {t('button_continue_with')}
      </button>

      <button
        onClick={() => onLogin('kakao')}
        disabled={loading}
        className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-[#191919] bg-[#FEE500] rounded-md hover:bg-[#F4DC00] disabled:opacity-50 disabled:cursor-not-allowed'
      >
        <Image
          src='/images/auth/kakao-logo.svg'
          alt={`Kakao ${t('button_login')}`}
          width={20}
          height={20}
          className='mr-2'
        />
        Kakao {t('button_continue_with')}
      </button>

      <button
        onClick={() => onLogin('wechat')}
        disabled={loading}
        className='flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-white bg-[#07C160] rounded-md hover:bg-[#06AD56] disabled:opacity-50 disabled:cursor-not-allowed'
      >
        <Image
          src='/images/auth/wechat-logo.svg'
          alt={`WeChat ${t('button_login')}`}
          width={20}
          height={20}
          className='mr-2'
        />
        WeChat {t('button_continue_with')}
      </button>
    </div>
  );
} 