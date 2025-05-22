import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import RetryButton from '@/components/client/RetryButton';
import { useRouter } from 'next/navigation';

// Next.js 라우터 모킹
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
}));

describe('RetryButton', () => {
  const mockPush = jest.fn();
  
  beforeEach(() => {
    // 라우터 모킹 설정
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
    });
    
    // 테스트 사이 모킹 초기화
    jest.clearAllMocks();
  });
  
  it('기본 경로로 리디렉션합니다', () => {
    render(<RetryButton />);
    
    // 버튼이 렌더링되는지 확인
    const button = screen.getByRole('button', { name: '로그인으로 돌아가기' });
    expect(button).toBeInTheDocument();
    
    // 버튼 클릭 이벤트 발생
    fireEvent.click(button);
    
    // 기본 경로로 리디렉션 확인
    expect(mockPush).toHaveBeenCalledWith('/login');
  });
  
  it('지정된 경로로 리디렉션합니다', () => {
    const customPath = '/custom-login';
    render(<RetryButton redirectPath={customPath} />);
    
    // 버튼 클릭
    const button = screen.getByRole('button', { name: '로그인으로 돌아가기' });
    fireEvent.click(button);
    
    // 사용자 지정 경로로 리디렉션 확인
    expect(mockPush).toHaveBeenCalledWith(customPath);
  });
  
  it('적절한 스타일 클래스를 적용합니다', () => {
    render(<RetryButton />);
    
    const button = screen.getByRole('button', { name: '로그인으로 돌아가기' });
    expect(button).toHaveClass('bg-primary-500');
    expect(button).toHaveClass('text-white');
    expect(button).toHaveClass('rounded-lg');
    expect(button).toHaveClass('hover:bg-primary-600');
    expect(button).toHaveClass('transition-colors');
  });
}); 