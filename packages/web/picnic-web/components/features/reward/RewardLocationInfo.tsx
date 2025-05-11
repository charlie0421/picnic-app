import React from 'react';

interface LocationInfo {
  desc?: string[];
  address?: string[];
}

interface RewardLocationInfoProps {
  locationInfo: LocationInfo | null;
}

const RewardLocationInfo: React.FC<RewardLocationInfoProps> = ({ locationInfo }) => {
  if (!locationInfo) return null;
  return (
    <div className='mt-8 text-gray-900'>
      <h2 className='text-xl font-semibold mb-4'>위치 정보</h2>
      <div className='bg-gray-50 p-6 rounded-lg'>
        {locationInfo.desc && locationInfo.desc.length > 0 && (
          <div className='mb-4 text-gray-700'>
            <h3 className='text-lg font-medium mb-2'>설명</h3>
            {locationInfo.desc.map((desc: string, index: number) => (
              <p key={index} className='text-gray-700 whitespace-pre-line'>
                {desc}
              </p>
            ))}
          </div>
        )}
        {locationInfo.address && locationInfo.address.length > 0 && (
          <div className='mb-4 text-gray-700'>
            <h3 className='text-lg font-medium mb-2'>주소</h3>
            {locationInfo.address.map((address: string, index: number) => (
              <p key={index} className='text-gray-700'>
                {address}
              </p>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default RewardLocationInfo; 