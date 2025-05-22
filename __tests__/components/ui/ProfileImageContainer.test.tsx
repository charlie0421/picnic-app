import React from 'react';
import { render, screen } from '@testing-library/react';
import { ProfileImageContainer, DefaultAvatar } from '@/components/ui/ProfileImageContainer';

// Next/Image 모킹
jest.mock('next/image', () => ({
  __esModule: true,
  default: (props: any) => {
    // eslint-disable-next-line @next/next/no-img-element
    return <img {...props} alt={props.alt || ''} />;
  },
}));

describe('ProfileImageContainer', () => {
  const mockProps = {
    avatarUrl: 'https://example.com/avatar.jpg',
    width: 100,
    height: 100,
  };

  it('이미지를 렌더링합니다', () => {
    render(<ProfileImageContainer {...mockProps} />);
    
    const image = screen.getByRole('img', { name: '프로필 이미지' });
    expect(image).toBeInTheDocument();
    expect(image).toHaveAttribute('src', mockProps.avatarUrl);
    expect(image).toHaveAttribute('width', mockProps.width.toString());
    expect(image).toHaveAttribute('height', mockProps.height.toString());
  });

  it('borderRadius 속성을 적용합니다', () => {
    const borderRadius = 50;
    render(<ProfileImageContainer {...mockProps} borderRadius={borderRadius} />);
    
    // 부모 div에 스타일 적용 확인
    const container = screen.getByRole('img', { name: '프로필 이미지' }).parentElement;
    expect(container).toHaveStyle(`border-radius: ${borderRadius}px`);
    expect(container).toHaveStyle('overflow: hidden');
  });
});

describe('DefaultAvatar', () => {
  it('기본 아바타를 렌더링합니다', () => {
    const width = 50;
    const height = 60;
    
    render(<DefaultAvatar width={width} height={height} />);
    
    // 이모지 확인
    const avatarContainer = screen.getByText('👤').parentElement;
    expect(avatarContainer).toBeInTheDocument();
    expect(avatarContainer).toHaveStyle(`width: ${width}px`);
    expect(avatarContainer).toHaveStyle(`height: ${height}px`);
    expect(avatarContainer).toHaveClass('bg-gray-200');
  });
}); 