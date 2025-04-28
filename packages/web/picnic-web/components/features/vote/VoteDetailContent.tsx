'use client';

import React, {
  useEffect,
  useState,
  useCallback,
  useMemo,
  useRef,
} from 'react';
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

interface VoteDetailContentProps {
  id: string;
  initialData?: {
    vote?: Vote | null;
    voteItems?: VoteItem[];
    rewards?: Reward[];
  };
}

const VoteDetailContent: React.FC<VoteDetailContentProps> = ({
  id,
  initialData,
}): JSX.Element | null => {
  const { isAuthenticated } = useAuth();
  const [vote, setVote] = useState<Vote | null>(initialData?.vote || null);
  const [voteItems, setVoteItems] = useState<VoteItem[]>(
    initialData?.voteItems || [],
  );
  const [rewards, setRewards] = useState<Reward[]>(initialData?.rewards || []);
  const [selectedArtist, setSelectedArtist] = useState<VoteItem | null>(null);
  const [votes, setVotes] = useState(1);
  const [isUseAll, setIsUseAll] = useState(false);
  const [isLoading, setIsLoading] = useState(!initialData?.vote);
  const [voteStatus, setVoteStatus] = useState<
    'upcoming' | 'ongoing' | 'ended'
  >('ongoing');
  const [isVoteDialogOpen, setIsVoteDialogOpen] = useState(false);
  const [isLoginDialogOpen, setIsLoginDialogOpen] = useState(false);
  const { t, currentLanguage } = useLanguageStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [searchFilter, setSearchFilter] = useState<'all' | 'artist' | 'group'>(
    'all',
  );
  const [isSearching, setIsSearching] = useState(false);
  const rewardRef = useRef<HTMLDivElement>(null);
  const [isRewardHidden, setIsRewardHidden] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // 초기 데이터 페칭
  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        if (id && !initialData?.vote) {
          const [voteData, rewardsData] = await Promise.all([
            getVoteById(Number(id)),
            getVoteRewards(Number(id)),
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
        } else if (initialData?.vote) {
          // 투표 상태 설정
          const now = new Date();
          const voteData = initialData.vote;
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
        console.error('Error fetching initial data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchInitialData();
  }, [id, initialData]);

  // 투표 아이템 주기적 업데이트
  useEffect(() => {
    if (voteStatus !== 'ongoing') return;

    const fetchVoteItems = async () => {
      try {
        if (id) {
          const voteItemsData = await getVoteItems(Number(id));
          const sortedItems = voteItemsData.sort(
            (a, b) => (b.voteTotal || 0) - (a.voteTotal || 0),
          );
          setVoteItems((prevItems) => {
            if (!prevItems.length) return sortedItems;
            const hasChanges = sortedItems.some(
              (item, index) => item.voteTotal !== prevItems[index]?.voteTotal,
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
    if (!startAt || !stopAt) return null;
    return (
      <>
        {format(new Date(startAt), 'yyyy.MM.dd HH:mm', {
          locale: ko,
        })}{' '}
        ~{' '}
        {format(new Date(stopAt), 'yyyy.MM.dd HH:mm', {
          locale: ko,
        })}
      </>
    );
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
      `${
        getLocalizedString(selectedArtist.artist?.name) || '아티스트'
      }에게 ${votes}표 투표 완료!`,
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
    const slideTop3 = slideOrder.map((i) => top3[i]).filter(Boolean);

    return (
      <div className='container mx-auto px-4 py-8'>
        {/* 상단 정보창: 아주 얇고 심플하게 */}
        <div className='sticky top-0 z-30 bg-gradient-to-r from-green-400 to-teal-500 text-white border-b px-2 py-6 min-h-[72px] md:py-6 md:min-h-[96px] flex flex-col items-start gap-y-1 relative'>
          <span className='text-base md:text-xl font-bold truncate w-full'>
            {mounted ? getLocalizedString(vote.title) : typeof vote.title === 'string' ? vote.title : (vote.title as Record<string, string>)?.[currentLanguage] || (vote.title as Record<string, string>)?.['en'] || ''}
          </span>
          <span className='text-sm md:text-base'>
            {mounted ? formatDateRange(vote.startAt, vote.stopAt) : formatDateRange(vote.startAt, vote.stopAt)}
          </span>
          <div className='absolute right-2 top-1 md:top-4'>
            {vote.startAt && vote.stopAt && (
              <CountdownTimer
                startTime={vote.startAt}
                endTime={vote.stopAt}
                status={voteStatus === 'upcoming' ? 'scheduled' : 'in_progress'}
                className='text-[10px] md:text-base [&_.w-14]:w-10 [&_.h-14]:h-10 md:[&_.w-14]:w-14 md:[&_.h-14]:h-14'
              />
            )}
          </div>
        </div>
        {/* 정보창과 랭킹카드 사이 여백 */}
        <div className='h-2 md:h-1' />
        {/* 상위 3위: sticky + 가로 슬라이드, 항상 가로로만 */}
        <div className='sticky top-[72px] md:top-[96px] z-20 bg-white border-b'>
          <div className='flex gap-1 md:gap-3 overflow-x-auto overflow-y-hidden px-1 py-1 justify-center'>
            {vote &&
              voteItems.length > 0 &&
              slideTop3.map((item, idx) => (
                <div key={item.id} className='flex-shrink-0'>
                  <VoteRankCard
                    item={item}
                    rank={item.rank}
                    showVoteChange={true}
                    isAnimating={true}
                  />
                </div>
              ))}
          </div>
        </div>

        {/* 리워드가 있는 경우 표시 */}
        {rewards.length > 0 && (
          <div ref={rewardRef} className='mt-4'>
            <VoteRewardPreview rewards={rewards} isSticky={isRewardHidden} />
          </div>
        )}

        {/* 검색 필터 */}
        <div className='mt-4'>
          <VoteSearch
            onSearch={handleSearch}
            onFilterChange={handleFilterChange}
            filter={searchFilter}
          />
        </div>

        {/* 투표 항목 리스트 */}
        <div className='mt-4 space-y-4'>
          {rankedVoteItems
            .filter((item) => {
              if (!searchQuery) return true;
              const artistName = getLocalizedString(item.artist?.name || '');
              const groupName = getLocalizedString(
                item.artist?.artistGroup?.name || '',
              );

              const query = searchQuery.toLowerCase();

              if (searchFilter === 'artist')
                return artistName.toLowerCase().includes(query);
              if (searchFilter === 'group')
                return groupName.toLowerCase().includes(query);

              return (
                artistName.toLowerCase().includes(query) ||
                groupName.toLowerCase().includes(query)
              );
            })
            .map((item) => (
              <div
                key={item.id}
                className='bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow overflow-hidden cursor-pointer'
                onClick={() => handleSelect(item)}
              >
                <div className='flex items-center p-4'>
                  <div className='relative w-20 h-20 rounded-full overflow-hidden border-2 border-gray-100 flex-shrink-0'>
                    {item.artist?.image ? (
                      <Image
                        src={getCdnImageUrl(item.artist.image)}
                        alt={getLocalizedString(item.artist.name)}
                        fill
                        className='object-cover'
                      />
                    ) : (
                      <div className='w-full h-full bg-gray-100 flex items-center justify-center'>
                        <span className='text-gray-400'>No Image</span>
                      </div>
                    )}
                  </div>
                  <div className='flex-1 ml-4'>
                    <div className='flex items-center gap-2'>
                      <h3 className='text-lg font-bold text-gray-900'>
                        {getLocalizedString(item.artist?.name)}
                      </h3>
                      {item.rank && (
                        <div 
                          className='px-2 py-1 rounded-full text-sm font-bold'
                          style={{
                            background: item.rank === 1 ? 'linear-gradient(135deg, #FFD700, #FFA500)' :
                                      item.rank === 2 ? 'linear-gradient(135deg, #C0C0C0, #A9A9A9)' :
                                      item.rank === 3 ? 'linear-gradient(135deg, #CD7F32, #8B4513)' :
                                      'none',
                            color: item.rank <= 3 ? 'white' : 'inherit'
                          }}
                        >
                          {item.rank}위
                        </div>
                      )}
                    </div>
                    <p className='text-sm text-gray-600 mt-1'>
                      {getLocalizedString(item.artist?.artistGroup?.name)}
                    </p>
                    <p className='text-xl font-bold text-primary mt-2'>
                      {item.voteTotal?.toLocaleString() || 0}
                    </p>
                  </div>
                  <div className='flex-shrink-0 ml-4'>
                    <button
                      className='px-6 py-3 bg-primary text-white rounded-full font-bold hover:bg-primary-dark transition-colors'
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSelect(item);
                      }}
                    >
                      {t('label_button_vote')}
                    </button>
                  </div>
                </div>
              </div>
            ))}
        </div>
      </div>
    );
  };

  if (isLoading) return <LoadingSpinner />;
  if (!vote) return <ErrorMessage />;

  return (
    <>
      <MainContent />
      {selectedArtist && (
        <>
          <VoteDialog
            isOpen={isVoteDialogOpen}
            onClose={closeVoteDialog}
            onVote={handleVote}
            selectedArtist={selectedArtist}
            votes={votes}
            setVotes={setVotes}
          />
          <LoginDialog isOpen={isLoginDialogOpen} onClose={closeLoginDialog} />
        </>
      )}
    </>
  );
};

export default VoteDetailContent;
