import React from 'react';

/**
 * 공통 푸터 컴포넌트
 * 웹사이트 전체에 사용되는 푸터 컴포넌트입니다.
 */
const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-100 p-6 mt-12">
      <div className="container mx-auto">
        <div className="text-center text-gray-500 text-sm">
          &copy; 2025 IconCasting Ltd. All rights reserved.
        </div>
      </div>
    </footer>
  );
};

export default Footer; 