'use client';

import React from 'react';
import Menu from '@/components/features/Menu';
import Footer from '@/components/layouts/Footer';

interface MainLayoutProps {
  children: React.ReactNode;
}

const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  return (
    <div className='min-h-screen flex flex-col'>
      <div className='bg-gray-50 border-b'>
        <div className='container mx-auto px-0'>
          <Menu />
        </div>
      </div>

      <main className='flex-grow'>
        {children}
      </main>

      <Footer />
    </div>
  );
};

export default MainLayout; 