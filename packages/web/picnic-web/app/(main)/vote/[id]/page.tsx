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

const VoteDetailPage: React.FC = (): JSX.Element => {
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

  // 초기 데이터 페칭
  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        if (id) {
          const [voteData, rewardsData] = await Promise.all([
            getVoteById(Number(id)),
            getVoteRewards(Number(id))
          ]);
          
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
    
    return (
      <div className='container mx-auto px-4 py-6'>
        <div className='bg-white rounded-lg shadow-md overflow-hidden'>
          {/* 헤더 */}
          <div className='relative'>
            <div className='bg-gradient-to-r from-green-400 to-teal-500 text-white'>
              <div className='p-4'>
                {/* 좌우 구분된 레이아웃 */}
                <div className='flex justify-between items-start'>
                  {/* 왼쪽: 제목, 기간, 리워드 */}
                  <div className='flex flex-col gap-3'>
                    <h1 className='text-xl font-bold'>
                      {getLocalizedString(vote.title)}
                    </h1>
                    
                    <div className='flex flex-col gap-2 text-sm text-white/80'>
                      {vote.startAt && vote.stopAt && (
                        <div>
                          {format(new Date(vote.startAt), 'yyyy.MM.dd HH:mm', { locale: ko })} ~{' '}
                          {format(new Date(vote.stopAt), 'yyyy.MM.dd HH:mm', { locale: ko })}
                        </div>
                      )}
                      {rewards && rewards.length > 0 && (
                        <div>
                          <VoteRewardPreview rewards={rewards} />
                        </div>
                      )}
                    </div>
                  </div>

                  {/* 오른쪽: 타이머 */}
                  <div>
                    {vote.startAt && vote.stopAt && (
                      <CountdownTimer
                        startTime={vote.startAt}
                        endTime={vote.stopAt}
                        status={voteStatus === 'upcoming' ? 'scheduled' : 'in_progress'}
                      />
                    )}
                  </div>
                </div>
              </div>

            </div>
          </div>

          {/* 투표 컨텐츠 */}
          <div className='p-4'>
            {/* 상위 3개 항목을 VoteRankCard로 표시 */}
            {vote && voteItems.length > 0 && (
              <OngoingVoteItems 
                vote={vote}
                voteItems={voteItems}
              />
            )}

            {/* 검색창 */}
            <VoteSearch
              onSearch={handleSearch}
              onFilterChange={handleFilterChange}
              searchResults={rankedVoteItems}
              totalItems={rankedVoteItems.length}
              isLoading={isSearching}
              className="mt-4"
            />

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
                    <div className='w-12 h-12 flex items-center justify-center'>
                      <span className='text-gray-600 text-lg font-semibold'>{item.rank}</span>
                    </div>

                    {/* 아티스트 이미지 */}
                    <div className='w-14 h-14 rounded-full overflow-hidden border-2 border-white shadow-sm mx-3'>
                      {item.artist && item.artist.image ? (
                        <Image
                          src={`${process.env.NEXT_PUBLIC_CDN_URL}/${item.artist.image}`}
                          alt={getLocalizedString(item.artist.name)}
                          width={56}
                          height={56}
                          className='w-full h-full object-cover'
                        />
                      ) : (
                        <div className='w-full h-full bg-gray-200 flex items-center justify-center'>
                          <span className='text-gray-600 text-xs'>No</span>
                        </div>
                      )}
                    </div>

                    {/* 아티스트 정보 */}
                    <div className='flex-1'>
                      <div className='flex items-center'>
                        <p className='font-bold text-md text-gray-700'>
                          {getLocalizedString(item.artist?.name)}
                        </p>
                        <p className='text-sm text-gray-600 ml-2'>
                          {getLocalizedString(item.artist?.artist_group?.name)}
                        </p>
                      </div>
                      <div className='flex items-center'>
                        <p className='text-primary font-bold'>
                          {item.voteTotal?.toLocaleString() || 0}
                        </p>
                      </div>
                    </div>

                    {/* 투표 버튼 */}
                    <button
                      className='ml-2 p-3 rounded-full text-white bg-primary shadow-sm hover:opacity-90 transition-all flex items-center justify-center'
                      onClick={() => handleSelect(item)}
                    >
                      <svg
                        xmlns='http://www.w3.org/2000/svg'
                        className='h-5 w-5 mr-1'
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
                  </div>
                ))}
            </div>
          </div>
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
