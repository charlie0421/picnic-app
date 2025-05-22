import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { AuthCallbackClient } from '@/components/shared/AuthCallback';
import { useRouter, useSearchParams } from 'next/navigation';
import { getSocialAuthService } from '@/lib/supabase/social';
import { SocialAuthService } from '@/lib/supabase/social/service';

// getSocialAuthService 모킹
jest.mock('@/lib/supabase/social', () => ({
  getSocialAuthService: jest.fn()
}));

// Next.js hooks 모킹
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  useSearchParams: jest.fn()
}));

describe('AuthCallbackClient 컴포넌트', () => {
  // 모킹된 객체들
  const mockPush = jest.fn();
  const mockRouter = { push: mockPush };
  const mockHandleCallback = jest.fn();
  const mockSocialAuthService = {
    handleCallback: mockHandleCallback
  };
  
  // localStorage 모킹 설정
  const mockLocalStorage = {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn()
  };
  
  beforeEach(() => {
    jest.clearAllMocks();
    
    // localStorage 모킹
    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage,
      writable: true
    });
    
    // 콘솔 에러 모킹 (오류 테스트 시 출력을 막기 위함)
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });
  
  it('인증 성공 시 홈으로 리디렉션합니다', async () => {
    // 모킹된 SearchParams 설정
    const mockParams = new Map();
    (useSearchParams as jest.Mock).mockReturnValue({
      get: (key: string) => mockParams.get(key),
      forEach: (callback: Function) => mockParams.forEach((value, key) => callback(value, key))
    });
    
    // 라우터 모킹 설정
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
    
    // 성공 응답 설정
    mockHandleCallback.mockResolvedValue({
      success: true,
      provider: 'google'
    });
    
    // getSocialAuthService 모킹
    (getSocialAuthService as jest.Mock).mockReturnValue(mockSocialAuthService);
    
    // 컴포넌트 렌더링
    render(<AuthCallbackClient provider="google" />);
    
    // 처리 중 상태 확인
    expect(screen.getByText(/처리 중입니다/)).toBeInTheDocument();
    
    // 인증 처리 확인
    expect(mockHandleCallback).toHaveBeenCalledWith('google', {});
    
    // 홈으로 리디렉션 확인
    await waitFor(() => {
      expect(mockPush).toHaveBeenCalledWith('/');
    });
  });
  
  it('인증 오류 시 오류 메시지를 표시합니다', async () => {
    // 모킹된 SearchParams 설정
    const mockParams = new Map();
    (useSearchParams as jest.Mock).mockReturnValue({
      get: (key: string) => mockParams.get(key),
      forEach: (callback: Function) => mockParams.forEach((value, key) => callback(value, key))
    });
    
    // 라우터 모킹 설정
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
    
    // 오류 응답 설정
    mockHandleCallback.mockResolvedValue({
      success: false,
      provider: 'google',
      error: { message: '인증 오류 발생' }
    });
    
    // getSocialAuthService 모킹
    (getSocialAuthService as jest.Mock).mockReturnValue(mockSocialAuthService);
    
    // 컴포넌트 렌더링
    render(<AuthCallbackClient provider="google" />);
    
    // 오류 메시지 표시 확인
    await waitFor(() => {
      expect(screen.getByText(/인증 오류: 인증 오류 발생/)).toBeInTheDocument();
    });
  });
  
  it('URL에 오류 코드가 있을 경우 오류 메시지를 표시합니다', async () => {
    // 모킹된 SearchParams 설정
    const mockParams = new Map();
    mockParams.set('error', 'access_denied');
    (useSearchParams as jest.Mock).mockReturnValue({
      get: (key: string) => mockParams.get(key),
      forEach: (callback: Function) => mockParams.forEach((value, key) => callback(value, key))
    });
    
    // 라우터 모킹 설정
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
    
    // getSocialAuthService 모킹
    (getSocialAuthService as jest.Mock).mockReturnValue(mockSocialAuthService);
    
    // 컴포넌트 렌더링
    render(<AuthCallbackClient provider="google" />);
    
    // 오류 메시지 표시 확인
    await waitFor(() => {
      expect(screen.getByText(/인증 오류: access_denied/)).toBeInTheDocument();
    });
    
    // 콜백 함수가 호출되지 않았는지 확인
    expect(mockHandleCallback).not.toHaveBeenCalled();
  });
  
  it('저장된 리디렉션 URL이 있으면 해당 URL로 이동합니다', async () => {
    // 이 테스트는 이전 테스트의 상태 문제로 인해 실패할 수 있음
    // mockSearchParams가 "error" 키를 가지고 있어서 오류 메시지를 표시하고 
    // 리디렉션이 발생하지 않는 문제 해결

    // 테스트 스킵 (또는 수정 후 다시 활성화)
    // test.skip('저장된 리디렉션 URL이 있으면 해당 URL로 이동합니다', async () => {

    // Mock setup for localStorage
    mockLocalStorage.getItem.mockReturnValue('/dashboard');
    
    // 성공적인 콜백 모킹
    mockHandleCallback.mockResolvedValue({
      success: true,
      provider: 'google'
    });
    
    // 다른 테스트와 독립적으로 모킹 값을 설정
    const localMockParams = new Map(); // error 키가 없는 빈 Map
    const localMockSearchParams = {
      get: (key: string) => localMockParams.get(key),
      forEach: (callback: Function) => localMockParams.forEach((value, key) => callback(value, key))
    };
    
    // 이 테스트에서만 사용할 모킹 설정
    (useRouter as jest.Mock).mockReturnValue({ push: mockPush });
    (useSearchParams as jest.Mock).mockReturnValue(localMockSearchParams);
    (getSocialAuthService as jest.Mock).mockReturnValue({
      handleCallback: mockHandleCallback
    });
    
    render(<AuthCallbackClient provider="google" />);
    
    // 처리 중 상태 확인
    expect(screen.getByText(/처리 중입니다/)).toBeInTheDocument();
    
    // 인증 처리 확인
    expect(mockHandleCallback).toHaveBeenCalledWith('google', {});
    
    // 리디렉션 URL로 이동 확인
    await waitFor(() => {
      expect(mockPush).toHaveBeenCalledWith('/dashboard');
    });
    
    // localStorage에서 URL이 제거되었는지 확인
    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_return_url');
  });
}); 