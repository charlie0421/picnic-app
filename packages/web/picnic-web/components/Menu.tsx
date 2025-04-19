import React from 'react';
import Link from 'next/link';

interface MenuProps {
  currentDateTime: string;
}

/**
 * 투표 페이지 메뉴 컴포넌트
 * 투표홈, 픽차트, 미디어, 상점 등의 메뉴 항목과 현재 시간을 표시합니다.
 */
const Menu: React.FC<MenuProps> = ({ currentDateTime }) => {
  return (
    <div className="flex justify-between items-center py-0">
      <div className="flex overflow-x-auto">
        <Link href="/vote" className="px-5 py-2 font-medium text-primary border-b-2 border-primary">
          투표홈
        </Link>
        <Link href="/vote/chart" className="px-5 py-2 text-gray-500 hover:text-primary hover:border-b-2 hover:border-primary">
          픽차트
        </Link>
        <Link href="/media" className="px-5 py-2 text-gray-500 hover:text-primary hover:border-b-2 hover:border-primary">
          미디어
        </Link>
        <Link href="/shop" className="px-5 py-2 text-gray-500 hover:text-primary hover:border-b-2 hover:border-primary">
          상점
        </Link>
      </div>
      <div className="px-4 text-gray-500 text-sm font-mono">
        <span className="text-primary mr-1">⏱</span>
        {currentDateTime}
      </div>
    </div>
  );
};

export default Menu; 