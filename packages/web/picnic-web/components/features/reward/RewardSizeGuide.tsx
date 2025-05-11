import React from 'react';

interface SizeGuideItem {
  desc?: string[];
}

interface RewardSizeGuideProps {
  sizeGuideInfo: SizeGuideItem[];
}

const RewardSizeGuide: React.FC<RewardSizeGuideProps> = ({ sizeGuideInfo }) => {
  if (!Array.isArray(sizeGuideInfo) || sizeGuideInfo.length === 0) return null;
  return (
    <div className='mt-8 text-gray-900'>
      <h2 className='text-xl font-semibold mb-4'>사이즈 가이드</h2>
      <div className='space-y-6'>
        {sizeGuideInfo.map((sizeItem, index) => (
          <div key={index} className='bg-gray-50 p-4 rounded-lg'>
            {sizeItem.desc && sizeItem.desc.length > 0 && (
              <div className='mb-2'>
                {sizeItem.desc.map((desc, descIndex) => (
                  <p key={descIndex} className='text-gray-700'>
                    {desc}
                  </p>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default RewardSizeGuide; 