'use client';

import React from 'react';

interface LoadingSpinnerProps {
  className?: string;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ className = '' }) => {
  return (
    <div className={`flex justify-center items-center min-h-[300px] ${className}`}>
      <div className="animate-spin rounded-full border-t-2 border-b-2 h-12 w-12 border-primary" />
    </div>
  );
};

export default LoadingSpinner; 