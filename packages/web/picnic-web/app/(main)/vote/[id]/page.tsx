'use client';

import React, { useEffect, useState, useCallback, useMemo, useRef } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';
import { format, differenceInSeconds } from 'date-fns';
import { ko } from 'date-fns/locale';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { getVoteById, getVoteItems, getVoteRewards } from '@/utils/api/queries';
import { getLocalizedString, getCdnImageUrl } from '@/utils/api/image';
import OngoingVoteItems from '@/components/features/vote/OngoingVoteItems';
import VoteDialog from '@/components/features/vote/dialogs/VoteDialog';
import LoginDialog from '@/components/features/vote/dialogs/LoginDialog';
import { useAuth } from '@/hooks/useAuth';
import { useLanguageStore } from '@/stores/languageStore';
import VoteSearch from '@/components/features/vote/VoteSearch';
import VoteRewardPreview from '@/components/features/vote/VoteRewardPreview';
import CountdownTimer from '@/components/features/CountdownTimer';
import VoteRankCard from '@/components/features/vote/VoteRankCard';

const VoteDetailPage: React.FC = (): JSX.Element | null => {
  const { id } = useParams();
  const { isAuthenticated } = useAuth();
  const [vote, setVote] = useState<Vote | null>(null);
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [selectedArtist, setSelectedArtist] = useState<VoteItem | null>(null);
  const [votes, setVotes] = useState(1);
  const [isUseAll, setIsUseAll] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [voteStatus, setVoteStatus] = useState<'upcoming' | 'ongoing' | 'ended'>('ongoing');
  const [isVoteDialogOpen, setIsVoteDialogOpen] = useState(false);
  const [isLoginDialogOpen, setIsLoginDialogOpen] = useState(false);
  const { t } = useLanguageStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [searchFilter, setSearchFilter] = useState<'all' | 'artist' | 'group'>('all');
  const [isSearching, setIsSearching] = useState(false);
  const rewardRef = useRef<HTMLDivElement>(null);
  const [isRewardHidden, setIsRewardHidden] = useState(false);

  // 초기 데이터 페칭
  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        if (id) {
          const [voteData, rewardsData] = await Promise.all([
            getVoteById(Number(id)),
            getVoteRewards(Number(id))
          ]);
          
          if (voteData) {
            setVote(voteData);
            setRewards(rewardsData);

            // 투표 상태 설정
            const now = new Date();
            const startDate = new Date(voteData.startAt as string);
            const endDate = new Date(voteData.stopAt as string);

            if (now < startDate) {
              setVoteStatus('upcoming');
            } else if (now < endDate) {
              setVoteStatus('ongoing');
            } else {
              setVoteStatus('ended');
            }
          }
        }
      } catch (error) {
        console.error('데이터를 가져오는 중 오류가 발생했습니다:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchInitialData();
  }, [id]);

  // 투표 아이템 주기적 업데이트
  useEffect(() => {
    if (voteStatus !== 'ongoing') return;

    const fetchVoteItems = async () => {
      try {
        if (id) {
          const voteItemsData = await getVoteItems(Number(id));
          const sortedItems = voteItemsData.sort(
            (a, b) => (b.voteTotal || 0) - (a.voteTotal || 0)
          );
          setVoteItems(prevItems => {
            if (!prevItems.length) return sortedItems;
            const hasChanges = sortedItems.some((item, index) => 
              item.voteTotal !== prevItems[index]?.voteTotal
            );
            return hasChanges ? sortedItems : prevItems;
          });
        }
      } catch (error) {
        console.error('투표 아이템을 가져오는 중 오류가 발생했습니다:', error);
      }
    };

    fetchVoteItems();
    const intervalId = setInterval(fetchVoteItems, 1000);
    return () => clearInterval(intervalId);
  }, [id, voteStatus]);

  // 투표 아이템 랭킹 계산 (동점자 공동 순위 처리)
  const rankedVoteItems = useMemo(() => {
    if (!voteItems.length) return [];

    // 투표수 기준 내림차순 정렬
    const sortedItems = [...voteItems].sort(
      (a, b) => (b.voteTotal || 0) - (a.voteTotal || 0),
    );

    let currentRank = 1;
    let currentScore = sortedItems[0]?.voteTotal || 0;
    let itemsWithRank = sortedItems.map((item, index) => {
      // 이전 아이템과 점수가 다르면 순위 업데이트
      if (index > 0 && currentScore !== (item.voteTotal || 0)) {
        currentRank = index + 1;
        currentScore = item.voteTotal || 0;
      }

      return {
        ...item,
        rank: currentRank,
      };
    });

    return itemsWithRank;
  }, [voteItems]);

  // 스크롤 시 리워드 프리뷰 숨김 처리
  useEffect(() => {
    const handleScroll = () => {
      if (!rewardRef.current) return;
      const rect = rewardRef.current.getBoundingClientRect();
      // 상단에서 80px 이상 스크롤되면 숨김
      setIsRewardHidden(rect.top < 80);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const formatDateRange = (startAt?: string | null, stopAt?: string | null) => {
    if (!startAt || !stopAt) return '';

    const start = new Date(startAt as string);
    const end = new Date(stopAt as string);

    return `${format(start, 'yyyy.MM.dd HH:mm', { locale: ko })} ~ ${format(
      end,
      'yyyy.MM.dd HH:mm',
      { locale: ko },
    )} (KST)`;
  };

  const handleSelect = (item: VoteItem) => {
    setSelectedArtist(item);
    if (isAuthenticated) {
      setIsVoteDialogOpen(true);
    } else {
      setIsLoginDialogOpen(true);
    }
  };

  const closeVoteDialog = () => {
    setIsVoteDialogOpen(false);
  };

  const closeLoginDialog = () => {
    setIsLoginDialogOpen(false);
  };

  const handleVote = () => {
    if (!selectedArtist) {
      alert('아티스트를 선택해주세요.');
      return;
    }

    // 투표 처리 로직 구현
    alert(
      `${getLocalizedString(selectedArtist.artist?.name) || '아티스트'}에게 ${votes}표 투표 완료!`,
    );
    closeVoteDialog();
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
  };

  const handleFilterChange = (filter: 'all' | 'artist' | 'group') => {
    setSearchFilter(filter);
  };

  // 로딩 컴포넌트
  const LoadingSpinner = () => (
    <div className='flex justify-center items-center min-h-[300px]'>
      <div className='animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary'></div>
    </div>
  );

  // 에러 컴포넌트
  const ErrorMessage = () => (
    <div className='bg-red-100 text-red-700 p-4 rounded-md'>
      투표 정보를 찾을 수 없습니다.
    </div>
  );

  // 메인 컨텐츠 컴포넌트
  const MainContent = () => {
    if (!vote) return null;
    
    const top3 = rankedVoteItems.slice(0, 3);
    const slideOrder = [1, 0, 2];
    const slideTop3 = slideOrder.map(i => top3[i]).filter(Boolean);

    return (
      <div className='container mx-auto px-2 py-2'>
        {/* 상단 정보창: 아주 얇고 심플하게 */}
        <div className="sticky top-0 z-30 bg-gradient-to-r from-green-400 to-teal-500 text-white border-b px-2 py-6 min-h-[72px] md:py-6 md:min-h-[96px] flex flex-col items-start gap-y-1 relative">
          <span className="text-base md:text-xl font-bold truncate w-full">
            {getLocalizedString(vote.title)}
          </span>
          <span className="text-xs md:text-sm">
            {vote.startAt && vote.stopAt && (
              <>{format(new Date(vote.startAt), 'yyyy.MM.dd HH:mm', { locale: ko })} ~ {format(new Date(vote.stopAt), 'yyyy.MM.dd HH:mm', { locale: ko })}</>
            )}
          </span>
          <div className="absolute right-2 top-1 md:top-4">
            {vote.startAt && vote.stopAt && (
              <CountdownTimer
                startTime={vote.startAt}
                endTime={vote.stopAt}
                status={voteStatus === 'upcoming' ? 'scheduled' : 'in_progress'}
                className="text-[10px] md:text-base [&_.w-14]:w-10 [&_.h-14]:h-10 md:[&_.w-14]:w-14 md:[&_.h-14]:h-14"
              />
            )}
          </div>
        </div>
        {/* 정보창과 랭킹카드 사이 여백 */}
        <div className="h-2 md:h-1" />
        {/* 상위 3위: sticky + 가로 슬라이드, 항상 가로로만 */}
        <div className='sticky top-[72px] md:top-[96px] z-20 bg-white border-b'>
          <div className='flex gap-2 md:gap-6 overflow-x-auto px-2 py-2 justify-center'>
            {vote && voteItems.length > 0 && (
              slideTop3.map((item, idx) => (
                <div key={item.id} className='w-40 min-w-[10rem] flex-shrink-0'>
                  <VoteRankCard
                    item={item}
                    rank={item.rank}
                    className={voteStatus === 'ended' ? 'opacity-80 grayscale' : ''}
                  />
                </div>
              ))
            )}
          </div>
        </div>
        {/* 검색창 */}
        <div className='bg-white z-10 pt-4'>
          <VoteSearch
            onSearch={handleSearch}
            onFilterChange={handleFilterChange}
            searchResults={rankedVoteItems}
            totalItems={rankedVoteItems.length}
            isLoading={isSearching}
            className="mt-4"
          />
        </div>
        {/* 전체 항목들 (1위부터) */}
        <div className='space-y-4 mt-4'>
          {rankedVoteItems
            .filter(item => {
              if (!searchQuery) return true;
              const artistName = getLocalizedString(item.artist?.name)?.toLowerCase() || '';
              const groupName = getLocalizedString(item.artist?.artist_group?.name)?.toLowerCase() || '';
              const query = searchQuery.toLowerCase();
              
              if (searchFilter === 'artist') {
                return artistName.includes(query);
              } else if (searchFilter === 'group') {
                return groupName.includes(query);
              } else {
                return artistName.includes(query) || groupName.includes(query);
              }
            })
            .map((item) => (
              <div
                key={item.id}
                className='flex items-center p-4 rounded-lg hover:bg-gray-50 transition-all border border-gray-200'
              >
                {/* 랭킹 표시 */}
                <div className='w-10 h-10 md:w-12 md:h-12 flex items-center justify-center'>
                  <span className='text-gray-600 text-base md:text-lg font-semibold'>{item.rank}</span>
                </div>

                {/* 아티스트 이미지 */}
                <div className='w-10 h-10 md:w-14 md:h-14 rounded-full overflow-hidden border-2 border-white shadow-sm mx-2 md:mx-3'>
                  {item.artist && item.artist.image ? (
                    <Image
                      src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                      alt={getLocalizedString(item.artist.name)}
                      width={40}
                      height={40}
                      className='w-full h-full object-cover'
                    />
                  ) : (
                    <div className='w-full h-full bg-gray-200 flex items-center justify-center'>
                      <span className='text-gray-600 text-[10px] md:text-xs'>No</span>
                    </div>
                  )}
                </div>

                {/* 아티스트 정보 */}
                <div className='flex-1'>
                  <div className='flex items-center'>
                    <p className='font-bold text-sm md:text-md text-gray-700'>
                      {getLocalizedString(item.artist?.name)}
                    </p>
                    <p className='text-xs md:text-sm text-gray-600 ml-1 md:ml-2'>
                      {getLocalizedString(item.artist?.artist_group?.name)}
                    </p>
                  </div>
                  <div className='flex items-center'>
                    <p className='text-primary font-bold text-xs md:text-base'>
                      {item.voteTotal?.toLocaleString() || 0}
                    </p>
                  </div>
                </div>

                {/* 투표 버튼 */}
                {voteStatus === 'ongoing' ? (
                  <button
                    className='ml-1 md:ml-2 p-2 md:p-3 rounded-full text-xs md:text-base text-white bg-primary shadow-sm hover:opacity-90 transition-all flex items-center justify-center min-w-[32px] min-h-[32px] md:min-w-[48px] md:min-h-[48px]'
                    onClick={() => handleSelect(item)}
                  >
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-4 w-4 md:h-5 md:w-5 mr-0.5 md:mr-1'
                      fill='none'
                      viewBox='0 0 24 24'
                      stroke='currentColor'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        strokeWidth={2}
                        d='M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z'
                      />
                    </svg>
                    <span className='font-bold'>{t('label_button_vote')}</span>
                  </button>
                ) : voteStatus === 'upcoming' ? (
                  <div className='ml-1 md:ml-2 p-2 md:p-3 rounded-full text-xs md:text-base text-gray-600 bg-gray-100 flex items-center justify-center min-w-[32px] min-h-[32px] md:min-w-[48px] md:min-h-[48px]'>
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-4 w-4 md:h-5 md:w-5 mr-0.5 md:mr-1'
                      fill='none'
                      viewBox='0 0 24 24'
                      stroke='currentColor'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        strokeWidth={2}
                        d='M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
                      />
                    </svg>
                    <span className='font-medium'>{t('label_button_vote_upcoming')}</span>
                  </div>
                ) : (
                  <div className='ml-1 md:ml-2 p-2 md:p-3 rounded-full text-xs md:text-base text-gray-600 bg-gray-100 flex items-center justify-center min-w-[32px] min-h-[32px] md:min-w-[48px] md:min-h-[48px]'>
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-4 w-4 md:h-5 md:w-5 mr-0.5 md:mr-1'
                      fill='none'
                      viewBox='0 0 24 24'
                      stroke='currentColor'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        strokeWidth={2}
                        d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
                      />
                    </svg>
                    <span className='font-medium'>{t('label_button_vote_ended')}</span>
                  </div>
                )}
              </div>
            ))}
        </div>
      </div>
    );
  };

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!vote) {
    return <ErrorMessage />;
  }

  return (
    <div className='min-h-screen'>
      <MainContent />
      <VoteDialog
        isOpen={isVoteDialogOpen}
        onClose={closeVoteDialog}
        onVote={handleVote}
        selectedArtist={selectedArtist}
        votes={votes}
        setVotes={setVotes}
      />
      <LoginDialog
        isOpen={isLoginDialogOpen}
        onClose={closeLoginDialog}
      />
    </div>
  );
};

export default VoteDetailPage;
