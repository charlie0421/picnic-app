import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { SupabaseProvider, useSupabase } from '@/components/providers/SupabaseProvider';
import { mockSupabaseClient } from '@/__tests__/utils/supabase-mocks';

// useSupabase 훅을 테스트하기 위한 컴포넌트
const TestComponent = () => {
  const { supabase, transformers } = useSupabase();
  return (
    <div>
      <div data-testid="client-exists">{supabase ? 'true' : 'false'}</div>
      <div data-testid="transformers-exists">{transformers ? 'true' : 'false'}</div>
    </div>
  );
};

// Supabase 클라이언트 모킹
jest.mock('@/lib/supabase/client', () => ({
  createBrowserSupabaseClient: jest.fn(() => mockSupabaseClient({
    authenticated: false
  }))
}));

describe('SupabaseProvider', () => {
  it('supabase 클라이언트를 자식 컴포넌트에 제공합니다', async () => {
    render(
      <SupabaseProvider>
        <TestComponent />
      </SupabaseProvider>
    );

    // supabase 클라이언트와 transformers가 제공되는지 확인
    expect(screen.getByTestId('client-exists')).toHaveTextContent('true');
    expect(screen.getByTestId('transformers-exists')).toHaveTextContent('true');
  });

  it('SupabaseProvider 외부에서 useSupabase를 사용하면 오류가 발생합니다', () => {
    // 콘솔 에러 억제
    const originalError = console.error;
    console.error = jest.fn();

    // useSupabase를 SupabaseProvider 외부에서 사용하면 오류가 발생해야 함
    expect(() => {
      render(<TestComponent />);
    }).toThrow('useSupabase는 SupabaseProvider 내에서 사용해야 합니다');

    // 콘솔 에러 복원
    console.error = originalError;
  });

  it('SupabaseGuard 컴포넌트가 children을 렌더링합니다', async () => {
    // SupabaseGuard 동작을 확인하는 테스트는 별도로 작성 가능
  });
}); 