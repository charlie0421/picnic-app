'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import type { LinkProps } from 'next/link';

interface NavigationLinkProps extends Omit<LinkProps, 'href'> {
  href: string;
  children: React.ReactNode;
  className?: string;
}

// Next.js 15.3.1에서 새로 도입된 네비게이션 훅을 사용하는 컴포넌트입니다.
// 참고: 이 코드는 Next.js 15.3.1 이상 버전에서만 작동합니다.
export default function NavigationLink({
  href,
  children,
  className = '',
  ...props
}: NavigationLinkProps) {
  const [isNavigating, setIsNavigating] = useState(false);
  
  // Next.js 15.3.1 업데이트 이후 onNavigate 이벤트 핸들러와 useLinkStatus를
  // 사용할 수 있게 되면 아래 주석을 해제하고 사용하세요.
  
  /*
  // 실제 구현:
  const handleNavigate = (event: any) => {
    // 네비게이션 이벤트 추적 또는 분석 로직
    console.log(`Navigation initiated to: ${href}`);
    
    // 사용자 정의 네비게이션 로직을 여기에 추가할 수 있습니다.
    // 필요한 경우 event.preventDefault()를 호출하여 네비게이션을 취소할 수 있습니다.
    
    setIsNavigating(true);
  };
  
  // useLinkStatus 훅 사용 예시:
  const LinkStatusIndicator = () => {
    const { pending } = useLinkStatus();
    
    if (!pending) return null;
    
    return (
      <span className="inline-block ml-2 w-3 h-3 rounded-full bg-blue-500 animate-pulse" 
            aria-label="Loading" />
    );
  };
  */
  
  return (
    <Link 
      href={href}
      className={`relative ${className} ${isNavigating ? 'opacity-70' : 'opacity-100'}`}
      {...props}
      // Next.js 15.3.1 지원 시 주석 해제:
      // onNavigate={handleNavigate}
    >
      {children}
      {/* Next.js 15.3.1 지원 시 주석 해제: <LinkStatusIndicator /> */}
      {isNavigating && (
        <span className="inline-block ml-2 w-3 h-3 rounded-full bg-blue-500 animate-pulse" 
              aria-label="Loading" />
      )}
    </Link>
  );
} 