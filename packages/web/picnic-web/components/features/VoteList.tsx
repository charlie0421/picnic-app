'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vote, VoteItem } from '@/types/interfaces';
import { getCdnImageUrl } from '@/utils/api/image';
import { format, differenceInDays } from 'date-fns';
import { ko } from 'date-fns/locale';
import { getVotes } from '@/utils/api/queries';

interface VoteListProps {
  votes: Vote[];
}

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = typeof VOTE_STATUS[keyof typeof VOTE_STATUS];

const STATUS_TAG_COLORS: Record<VoteStatus, string> = {
  [VOTE_STATUS.UPCOMING]: 'bg-blue-100 text-blue-800',
  [VOTE_STATUS.ONGOING]: 'bg-green-100 text-green-800',
  [VOTE_STATUS.COMPLETED]: 'bg-gray-100 text-gray-800',
};

const RANK_BADGE_COLORS = [
  'bg-gradient-to-br from-yellow-400 to-yellow-600 shadow-lg',
  'bg-gradient-to-br from-gray-300 to-gray-400 shadow-md',
  'bg-gradient-to-br from-amber-500 to-amber-700 shadow-sm',
];

const VoteList: React.FC = () => {
  const [mounted, setMounted] = useState(false);
  const [votes, setVotes] = useState<Vote[]>([]);
  useEffect(() => {
    setMounted(true);
    const updateVoteData = async () => {
      const votesData = await getVotes('votes');
      setVotes(votesData);
    };

    updateVoteData();
    const timer = setInterval(updateVoteData, 1000);
    return () => clearInterval(timer);
  }, []);

  const getVoteStatus = (vote: Vote): VoteStatus => {
    if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
    
    const now = new Date();
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    
    if (now < start) return VOTE_STATUS.UPCOMING;
    if (now > end) return VOTE_STATUS.COMPLETED;
    return VOTE_STATUS.ONGOING;
  };

  const getStatusText = (status: VoteStatus): string => {
    switch (status) {
      case VOTE_STATUS.UPCOMING:
        return '예정됨';
      case VOTE_STATUS.ONGOING:
        return '진행 중';
      case VOTE_STATUS.COMPLETED:
        return '종료됨';
      default:
        return '';
    }
  };

  const getPeriodText = (vote: Vote): string => {
    if (!vote.startAt || !vote.stopAt) return '기간 미정';
    
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    const now = new Date();
    
    if (now < start) {
      const daysUntilStart = differenceInDays(start, now);
      return `${daysUntilStart}일 후 시작`;
    }
    
    if (now > end) {
      return '투표 종료';
    }
    
    const daysLeft = differenceInDays(end, now);
    return `${daysLeft}일 남음`;
  };

  const renderVoteItems = (vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> }) => {
    if (!vote.voteItems || vote.voteItems.length === 0) return null;

    const topThreeItems = [...vote.voteItems]
      .sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0))
      .slice(0, 3);

    return (
      <div className="space-y-3 mt-4">
        {topThreeItems.map((item, index) => (
          <div key={item.id} className="flex items-center space-x-3 bg-white/50 backdrop-blur-sm rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow">
            <div className="relative">
              <div className={`absolute -top-2 -right-2 w-7 h-7 rounded-full flex items-center justify-center text-white text-sm font-bold ${RANK_BADGE_COLORS[index]} transform hover:scale-110 transition-transform`}>
                {index + 1}
              </div>
              <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-white shadow-md">
                {item.artist && item.artist.image ? (
                  <Image
                    src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                    alt={item.artist.name?.ko || '아티스트'}
                    width={56}
                    height={56}
                    className="w-full h-full object-cover"
                    priority
                  />
                ) : (
                  <div className="w-full h-full bg-gray-200 flex items-center justify-center">
                    <span className="text-gray-400 text-xs">No Image</span>
                  </div>
                )}
              </div>
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-semibold text-gray-800 truncate">
                {item.artist ? (item.artist.name?.ko || item.artist.name || 'Unknown Artist') : 'Unknown Artist'}
              </div>
              <div className="text-xs text-primary font-medium">
                {item.voteTotal?.toLocaleString() || 0} 표
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  };

  return (
    <section>
      <div className="flex justify-end items-center mb-6">
        <Link href="/vote/location" className="text-primary text-sm hover:underline">
          전체보기
        </Link>
      </div>
      
      {votes.length === 0 ? (
        <div className="bg-gray-100 p-6 rounded-lg text-center">
          <p className="text-gray-500">투표가 없습니다.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {votes.slice(0, 6).map((vote: Vote) => (
            <Link href={`/vote/${vote.id}`} key={vote.id}>
              <div className="bg-gradient-to-br from-white to-gray-50 rounded-xl shadow-md overflow-hidden hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1">
                <div className="relative">
                  {vote.mainImage && (
                    <div className="h-48 bg-gray-200 relative">
                      <Image
                        src={getCdnImageUrl(vote.mainImage)}
                        alt={vote.title}
                        width={320}
                        height={192}
                        className="w-full h-full object-cover"
                        priority
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
                    </div>
                  )}
                </div>
                
                <div className="p-5">
                  <h3 className="font-bold text-lg mb-3 text-gray-800 line-clamp-2">
                    {vote.title}
                  </h3>
                  
                  {renderVoteItems(vote)}

                  <div className="mt-4 pt-4 border-t border-gray-100">
                    {vote.startAt && vote.stopAt && (
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-gray-500">
                          {getPeriodText(vote)}
                        </span>
                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                          getVoteStatus(vote) === VOTE_STATUS.ONGOING
                            ? 'bg-green-100 text-green-800'
                            : getVoteStatus(vote) === VOTE_STATUS.UPCOMING
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {getStatusText(getVoteStatus(vote))}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </section>
  );
};

export default VoteList; 