'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Reward } from '@/types/interfaces';
import { getCdnImageUrl, getLocalizedString } from '@/utils/api/image';

interface RewardListProps {
  rewards: Reward[];
}

const RewardList: React.FC<RewardListProps> = ({ rewards }) => {
  return (
    <section>
      <div className="flex justify-end items-center mb-6">
      <Link href="/rewards" className="text-primary text-sm hover:underline">
          전체보기
        </Link>
      </div>
      
      {rewards.length === 0 ? (
        <div className="bg-gray-100 p-6 rounded-lg text-center">
          <p className="text-gray-500">표시할 리워드가 없습니다.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {rewards.map((reward) => (
            <div key={reward.id} className="bg-white rounded-lg shadow-md overflow-hidden">
              <div className="aspect-square bg-gray-200 relative">
                {reward.thumbnail ? (
                  <Image
                    src={getCdnImageUrl(reward.thumbnail, 320)}
                    alt={typeof reward.title === 'string' ? reward.title : '리워드'}
                    width={320}
                    height={320}
                    className="w-full h-full object-cover"
                    priority
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <span className="text-gray-600">리워드 이미지</span>
                  </div>
                )}
              </div>
              <div className="p-3">
                <h3 className="font-medium mb-1 truncate text-gray-800">
                  {getLocalizedString(reward.title as { [key: string]: string } | null) || '제목 없음'}
                </h3>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
};

export default RewardList; 