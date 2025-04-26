'use client';

import React, { useEffect, useState, useCallback, useMemo } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { format, differenceInSeconds } from 'date-fns';
import { ko } from 'date-fns/locale';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import Menu from '@/components/features/Menu';
import Footer from '@/components/layouts/Footer';
import { getVoteById, getVoteItems, getVoteRewards } from '@/utils/api/queries';
import { getLocalizedString } from '@/utils/api/image';
import { getCdnImageUrl } from '@/utils/api/image';
import VoteRankCard from '@/components/features/vote/VoteRankCard';

const VoteDetailPage: React.FC = (): JSX.Element => {
  const { id } = useParams();
  const [vote, setVote] = useState<Vote | null>(null);
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [selectedArtist, setSelectedArtist] = useState<VoteItem | null>(null);
  const [votes, setVotes] = useState(1);
  const [isUseAll, setIsUseAll] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [tab, setTab] = useState<'ranking' | 'info'>('ranking');
  const [remainingTime, setRemainingTime] = useState<{
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
  } | null>(null);
  const [voteStatus, setVoteStatus] = useState<
    'upcoming' | 'ongoing' | 'ended'
  >('ongoing');
  const [prevRankings, setPrevRankings] = useState<{ [key: number]: number }>({});
  const [prevVotes, setPrevVotes] = useState<{ [key: number]: number }>({});
  const [voteChanges, setVoteChanges] = useState<{ [key: number]: number }>({});
  const [isAnimating, setIsAnimating] = useState(false);

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
          setVoteItems(sortedItems);
        }
      } catch (error) {
        console.error('투표 아이템을 가져오는 중 오류가 발생했습니다:', error);
      }
    };

    fetchVoteItems();
    const intervalId = setInterval(fetchVoteItems, 1000);
    return () => clearInterval(intervalId);
  }, [id, voteStatus]);

  // 남은 시간 계산 및 상태 업데이트
  useEffect(() => {
    if (!vote || !vote.startAt || !vote.stopAt) return;

    const calculateRemainingTime = () => {
      const now = new Date();
      const startDate = new Date(vote.startAt as string);
      const endDate = new Date(vote.stopAt as string);

      if (now < startDate) {
        setVoteStatus('upcoming');
        const diffInSeconds = differenceInSeconds(startDate, now);
        setRemainingTime({
          days: Math.floor(diffInSeconds / 86400),
          hours: Math.floor((diffInSeconds % 86400) / 3600),
          minutes: Math.floor((diffInSeconds % 3600) / 60),
          seconds: diffInSeconds % 60
        });
      } else if (now < endDate) {
        setVoteStatus('ongoing');
        const diffInSeconds = differenceInSeconds(endDate, now);
        setRemainingTime({
          days: Math.floor(diffInSeconds / 86400),
          hours: Math.floor((diffInSeconds % 86400) / 3600),
          minutes: Math.floor((diffInSeconds % 3600) / 60),
          seconds: diffInSeconds % 60
        });
      } else {
        setVoteStatus('ended');
        setRemainingTime(null);
      }
    };

    calculateRemainingTime();
    const intervalId = setInterval(calculateRemainingTime, 1000);
    return () => clearInterval(intervalId);
  }, [vote]);

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

  // 1초마다 투표수와 순위 변경 확인
  useEffect(() => {
    if (voteStatus !== 'ongoing') return;

    const checkChanges = () => {
      const newRankings: { [key: number]: number } = {};
      const newVotes: { [key: number]: number } = {};
      const newVoteChanges: { [key: number]: number } = {};

      rankedVoteItems.forEach((item) => {
        newRankings[item.id] = item.rank;
        newVotes[item.id] = item.voteTotal || 0;
        newVoteChanges[item.id] = (item.voteTotal || 0) - (prevVotes[item.id] || 0);
      });

      // 순위나 투표수가 변경되었는지 확인
      const hasRankChange = Object.keys(prevRankings).some(
        (id) => prevRankings[Number(id)] !== newRankings[Number(id)],
      );
      const hasVoteChange = Object.keys(prevVotes).some(
        (id) => prevVotes[Number(id)] !== newVotes[Number(id)],
      );

      if (hasRankChange || hasVoteChange) {
        setIsAnimating(true);
        setVoteChanges(newVoteChanges);
        setTimeout(() => {
          setIsAnimating(false);
        }, 1000);
      }

      setPrevRankings(newRankings);
      setPrevVotes(newVotes);
    };

    const intervalId = setInterval(checkChanges, 1000);
    return () => clearInterval(intervalId);
  }, [rankedVoteItems, voteStatus, prevRankings, prevVotes]);

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

  const handleVote = () => {
    if (!selectedArtist) {
      alert('아티스트를 선택해주세요.');
      return;
    }

    // 투표 처리 로직 구현
    alert(
      `${getLocalizedString(selectedArtist.artist?.name) || '아티스트'}에게 ${votes}표 투표 완료!`,
    );
  };

  const handleSelect = (item: VoteItem) => {
    setSelectedArtist(item);

    // 모달 표시 로직 구현
    const modal = document.getElementById('voteModal');
    if (modal) {
      modal.classList.remove('hidden');
    }
  };

  const closeModal = () => {
    const modal = document.getElementById('voteModal');
    if (modal) {
      modal.classList.add('hidden');
    }
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
            <div className='p-6 text-center bg-gradient-to-r from-green-400 to-teal-500 text-white'>
              <h1 className='text-xl font-bold mb-2'>
                {getLocalizedString(vote.title)}
              </h1>
              {remainingTime && (
                <div className='bg-white/20 rounded-lg p-2 inline-flex items-center space-x-2 backdrop-blur-sm'>
                  <div className='text-white'>
                    {voteStatus === 'upcoming' ? '시작까지 ' : '종료까지 '}
                  </div>
                  <div className='flex space-x-2'>
                    <div className='bg-white/30 px-2 py-1 rounded text-white backdrop-blur-sm'>
                      <span className='font-mono font-bold'>
                        {remainingTime.days}
                      </span>
                      <span className='text-xs ml-1'>일</span>
                    </div>
                    <div className='bg-white/30 px-2 py-1 rounded text-white backdrop-blur-sm'>
                      <span className='font-mono font-bold'>
                        {remainingTime.hours.toString().padStart(2, '0')}
                      </span>
                      <span className='text-xs ml-1'>시</span>
                    </div>
                    <div className='bg-white/30 px-2 py-1 rounded text-white backdrop-blur-sm'>
                      <span className='font-mono font-bold'>
                        {remainingTime.minutes.toString().padStart(2, '0')}
                      </span>
                      <span className='text-xs ml-1'>분</span>
                    </div>
                    <div className='bg-white/30 px-2 py-1 rounded text-white backdrop-blur-sm'>
                      <span className='font-mono font-bold'>
                        {remainingTime.seconds.toString().padStart(2, '0')}
                      </span>
                      <span className='text-xs ml-1'>초</span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className='p-3 bg-gray-100'>
              <p className='text-center text-gray-700 text-sm'>
                {formatDateRange(vote.startAt, vote.stopAt)}
              </p>
            </div>
          </div>

          {/* 투표 컨텐츠 */}
          <div className='p-4'>
            {/* 탭 메뉴 */}
            <div className='flex border-b mb-4'>
              <button
                className={`flex-1 py-2 text-center font-medium ${
                  tab === 'ranking'
                    ? 'text-primary border-b-2 border-primary'
                    : 'text-gray-500'
                }`}
                onClick={() => setTab('ranking')}
              >
                랭킹
              </button>
              <button
                className={`flex-1 py-2 text-center font-medium ${
                  tab === 'info'
                    ? 'text-primary border-b-2 border-primary'
                    : 'text-gray-500'
                }`}
                onClick={() => setTab('info')}
              >
                정보
              </button>
            </div>

            {/* 랭킹 탭 */}
            {tab === 'ranking' && (
              <div className='space-y-3'>
                {/* 상위 3개 항목을 VoteRankCard로 표시 */}
                <div className='grid grid-cols-1 sm:grid-cols-3 gap-4 mt-16 mb-8'>
                  {rankedVoteItems.slice(0, 3).map((item, index) => (
                    <VoteRankCard
                      key={item.id}
                      item={item}
                      rank={index + 1}
                      isAnimating={isAnimating}
                      voteChange={voteChanges[item.id] || 0}
                      showVoteChange={true}
                    />
                  ))}
                </div>

                {/* 검색창 */}
                <div className='relative mt-4'>
                  <input
                    type='text'
                    placeholder='나의 최애는 어디에?'
                    className='w-full p-3 pl-12 rounded-full border border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent'
                  />
                  <div className='absolute left-4 top-1/2 transform -translate-y-1/2'>
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-5 w-5 text-gray-600'
                      fill='none'
                      viewBox='0 0 24 24'
                      stroke='currentColor'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        strokeWidth={2}
                        d='M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
                      />
                    </svg>
                  </div>
                  {/* 검색어 지우기 버튼 */}
                  <button className='absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-600'>
                    <svg
                      xmlns='http://www.w3.org/2000/svg'
                      className='h-5 w-5'
                      fill='none'
                      viewBox='0 0 24 24'
                      stroke='currentColor'
                    >
                      <path
                        strokeLinecap='round'
                        strokeLinejoin='round'
                        strokeWidth={2}
                        d='M6 18L18 6M6 6l12 12'
                      />
                    </svg>
                  </button>
                </div>

                {/* 전체 항목들 (1위부터) */}
                <div className='space-y-4 mt-4 mb-8'>
                  {rankedVoteItems.map((item) => (
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
                          <span className='text-gray-600 text-sm ml-1'>표</span>
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
                        <span className='font-bold'>투표</span>
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 정보 탭 */}
            {tab === 'info' && (
              <div className='space-y-4'>
                <h3 className='text-lg font-bold'>투표 정보</h3>
                <div className='bg-gray-50 p-4 rounded-lg'>
                  <p className='text-sm'>
                    {getLocalizedString(vote.title)}은(는)
                    {vote.startAt && vote.stopAt
                      ? `${format(new Date(vote.startAt), 'yyyy.MM.dd HH:mm', {
                          locale: ko,
                        })}부터 
                    ${format(new Date(vote.stopAt), 'yyyy.MM.dd HH:mm', {
                      locale: ko,
                    })}까지 진행됩니다.`
                      : '기간이 정해지지 않았습니다.'}
                  </p>
                </div>

                {rewards.length > 0 && (
                  <>
                    <h3 className='text-lg font-bold mt-6'>보상 정보</h3>
                    <div className='space-y-3'>
                      {rewards.map((reward) => (
                        <div
                          key={reward.id}
                          className='bg-gray-50 p-4 rounded-lg'
                        >
                          <h4 className='font-medium mb-2'>
                            {getLocalizedString(reward.title)}
                          </h4>
                          <div className='flex space-x-2 overflow-x-auto pb-2'>
                            {reward.overviewImages?.map((image, index) => (
                              <div
                                key={index}
                                className='flex-shrink-0 w-32 h-24 rounded-md overflow-hidden'
                              >
                                <Image
                                  src={getCdnImageUrl(image)}
                                  alt={`${getLocalizedString(
                                    reward.title,
                                  )} 이미지 ${index + 1}`}
                                  width={128}
                                  height={96}
                                  className='w-full h-full object-cover'
                                />
                              </div>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>
            )}
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
    </div>
  );
};

export default VoteDetailPage;
