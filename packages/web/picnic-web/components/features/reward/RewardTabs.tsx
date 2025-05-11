import React from 'react';

interface RewardTabsProps {
  activeTab: 'overview' | 'location' | 'size';
  setActiveTab: (tab: 'overview' | 'location' | 'size') => void;
  setCurrentImageIndex: (index: number) => void;
  t: (key: string) => string;
}

const RewardTabs: React.FC<RewardTabsProps> = ({
  activeTab,
  setActiveTab,
  setCurrentImageIndex,
  t,
}) => {
  return (
    <div className='flex border-b border-gray-200 mb-6'>
      <button
        className={`px-4 py-2 font-medium ${
          activeTab === 'overview'
            ? 'text-primary border-b-2 border-primary'
            : 'text-gray-500'
        }`}
        onClick={() => {
          setActiveTab('overview');
          setCurrentImageIndex(0);
        }}
      >
        {t('label_reward_overview')}
      </button>
      <button
        className={`px-4 py-2 font-medium ${
          activeTab === 'location'
            ? 'text-primary border-b-2 border-primary'
            : 'text-gray-500'
        }`}
        onClick={() => {
          setActiveTab('location');
          setCurrentImageIndex(0);
        }}
      >
        {t('label_reward_location')}
      </button>
      <button
        className={`px-4 py-2 font-medium ${
          activeTab === 'size'
            ? 'text-primary border-b-2 border-primary'
            : 'text-gray-500'
        }`}
        onClick={() => {
          setActiveTab('size');
          setCurrentImageIndex(0);
        }}
      >
        {t('label_reward_size')}
      </button>
    </div>
  );
};

export default RewardTabs; 