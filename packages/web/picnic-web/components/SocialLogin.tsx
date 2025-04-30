'use client';

import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import Image from 'next/image';

interface SocialLoginProps {
  className?: string;
}

const SocialLogin: React.FC<SocialLoginProps> = ({ className = '' }) => {
  const { signInWithSocial } = useAuth();

  const handleGoogleLogin = async () => {
    await signInWithSocial('google');
  };

  const handleAppleLogin = async () => {
    await signInWithSocial('apple');
  };

  const handleKakaoLogin = async () => {
    await signInWithSocial('kakao');
  };

  const handleWechatLogin = async () => {
    await signInWithSocial('wechat');
  };

  return (
    <div className={`flex flex-col space-y-3 ${className}`}>
      <button
        type="button"
        onClick={handleGoogleLogin}
        className="flex items-center justify-center w-full px-4 py-2.5 border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
      >
        <div className="relative w-5 h-5 mr-3">
          <Image
            src="/images/google-logo.svg"
            alt="Google"
            fill
            sizes="20px"
          />
        </div>
        <span>Google로 계속하기</span>
      </button>

      <button
        type="button"
        onClick={handleAppleLogin}
        className="flex items-center justify-center w-full px-4 py-2.5 bg-black text-white rounded-md hover:bg-gray-800 transition-colors"
      >
        <div className="relative w-5 h-5 mr-3">
          <Image
            src="/images/apple-logo.svg"
            alt="Apple"
            fill
            sizes="20px"
          />
        </div>
        <span>Apple로 계속하기</span>
      </button>

      <button
        type="button"
        onClick={handleKakaoLogin}
        className="flex items-center justify-center w-full px-4 py-2.5 bg-[#FEE500] text-[#191919] rounded-md hover:bg-[#F4DC00] transition-colors"
      >
        <div className="relative w-5 h-5 mr-3">
          <Image
            src="/images/kakao-logo.svg"
            alt="Kakao"
            fill
            sizes="20px"
          />
        </div>
        <span>카카오로 계속하기</span>
      </button>

      <button
        type="button"
        onClick={handleWechatLogin}
        className="flex items-center justify-center w-full px-4 py-2.5 bg-[#07C160] text-white rounded-md hover:bg-[#06AD56] transition-colors"
      >
        <div className="relative w-5 h-5 mr-3">
          <Image
            src="/images/wechat-logo.svg"
            alt="WeChat"
            fill
            sizes="20px"
          />
        </div>
        <span>위챗으로 계속하기</span>
      </button>
    </div>
  );
};

export default SocialLogin; 