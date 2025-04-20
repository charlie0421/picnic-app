'use client';

import React, { useEffect, useState, useRef, useCallback } from 'react';
import Link from 'next/link';
import { supabase } from '../../utils/supabase';
import BannerAd from '../../components/BannerAd';
import { getBannerImageUrl, getRewardImageUrl, getVoteImageUrl, getLocalizedImage } from '../../utils/image';
import { format, differenceInDays } from 'date-fns';
import { ko } from 'date-fns/locale';
import Menu from '../../components/Menu';
import Footer from '../../components/Footer';
import { Banner, Reward, Vote, VoteItem } from '@/types/interfaces';

const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL as string;

// 투표 상태 정의
const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = typeof VOTE_STATUS[keyof typeof VOTE_STATUS];

// 투표 상태 태그 색상
const STATUS_TAG_COLORS: Record<VoteStatus, string> = {
  [VOTE_STATUS.UPCOMING]: 'bg-blue-100 text-blue-800',
  [VOTE_STATUS.ONGOING]: 'bg-green-100 text-green-800',
  [VOTE_STATUS.COMPLETED]: 'bg-gray-100 text-gray-800',
};

// 투표 상태 계산 함수
const getVoteStatus = (vote: Vote): VoteStatus => {
  if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
  
  const now = new Date();
  const start = new Date(vote.startAt);
  const end = new Date(vote.stopAt);
  
  if (now < start) return VOTE_STATUS.UPCOMING;
  if (now > end) return VOTE_STATUS.COMPLETED;
  return VOTE_STATUS.ONGOING;
};

// 순위 배지 색상
const RANK_BADGE_COLORS = [
  'bg-yellow-500', // 1위 - 금색
  'bg-gray-300',   // 2위 - 은색
  'bg-amber-600',  // 3위 - 동색
  'bg-gray-200',   // 그 외
];

// 순위 계산 함수
const getVoteRank = (vote: Vote, index: number): number => {
  return vote.order || index + 1;
};

const VotePage: React.FC = () => {
  // 데이터 상태
  const [votes, setVotes] = useState<Vote[]>([]);
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [banners, setBanners] = useState<Banner[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // UI 상태 (데이터와 분리)
  const [currentDateTime, setCurrentDateTime] = useState<string>('');
  
  // 이미지 URL 캐싱을 위한 ref (리렌더링되지 않음)
  const voteImageCache = useRef<Record<string, string>>({});
  const bannerImageCache = useRef<Record<string, string>>({});
  const rewardImageCache = useRef<Record<string, string>>({});

  // 캐싱된 이미지 URL 가져오기 함수
  const getCachedVoteImageUrl = useCallback((voteId: string, imagePath?: string): string => {
    if (!imagePath) return '';
    const cacheKey = `vote_${voteId}_${imagePath}`;
    
    if (!voteImageCache.current[cacheKey]) {
      voteImageCache.current[cacheKey] = getVoteImageUrl(voteId, imagePath);
    }
    
    return voteImageCache.current[cacheKey];
  }, []);
  
  const getCachedBannerImageUrl = useCallback((imagePath?: string): string => {
    if (!imagePath) return '';
    const cacheKey = `banner_${imagePath}`;
    
    if (!bannerImageCache.current[cacheKey]) {
      bannerImageCache.current[cacheKey] = getBannerImageUrl(imagePath);
    }
    
    return bannerImageCache.current[cacheKey];
  }, []);
  
  const getCachedRewardImageUrl = useCallback((imagePath?: string): string => {
    if (!imagePath) return '';
    const cacheKey = `reward_${imagePath}`;
    
    if (!rewardImageCache.current[cacheKey]) {
      rewardImageCache.current[cacheKey] = getRewardImageUrl(imagePath);
    }
    
    return rewardImageCache.current[cacheKey];
  }, []);

  // 현재 날짜를 ISO 형식으로 반환하는 함수
  const getFormattedDate = (): string => {
    const now = new Date();
    return now.toISOString();
  };

  // 현재 시간 설정 - 1초마다 업데이트 (UI 전용)
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const formattedDate = format(now, 'MM/dd (EEE) HH:mm:ss', { locale: ko });
      setCurrentDateTime(formattedDate);
    };
    
    // 초기 설정
    updateTime();
    
    // 1초마다 시간 업데이트
    const intervalId = setInterval(updateTime, 1000);

    return () => clearInterval(intervalId);
  }, []);

  // 데이터 가져오기 - 1분마다 업데이트
  useEffect(() => {
    // 초기 데이터 로딩
    fetchData();
    
    // 1분마다 데이터 새로고침
    const intervalId = setInterval(() => {
      fetchData();
    }, 60000);
    
    return () => clearInterval(intervalId);
  }, []);
  
  // 데이터 가져오기 함수
  const fetchData = async () => {
    try {
      setIsLoading(true);
      
      // 모든 데이터를 병렬로 가져옵니다
      const [votesData, rewardsData, bannersData] = await Promise.all([
        getVotes('votes', 3),
        getRewards(),
        getBanners(),
      ]);
      
      setVotes(votesData);
      setRewards(rewardsData);
      setBanners(bannersData);
      
    } catch (error) {
      console.error('데이터를 가져오는 중 오류가 발생했습니다:', error);
        setError('데이터를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setIsLoading(false);
      }
    };

  /**
   * 투표 데이터를 가져옵니다.
   * @param sortBy - 정렬 기준 ('votes': 투표수 기준, 'recent': 최신순)
   * @param limit - 가져올 투표 수 (0이면 제한 없음)
   */
  const getVotes = async (sortBy: 'votes' | 'recent' = 'votes', limit: number = 0): Promise<Vote[]> => {
    try {
      const now = new Date();
      const currentTime = now.toISOString();

      // 기본 쿼리: 현재 활성화된 모든 투표 가져오기
      const { data: voteData, error: voteError } = await supabase
        .from('vote')
        .select(`
          *,
          vote_items:vote_item(*, artist(*))
        `)
        .is('deleted_at', null)
        .lte('start_at', currentTime)
        .gte('stop_at', currentTime)
        .order('created_at', { ascending: false });

      if (voteError) throw voteError;
      if (!voteData || voteData.length === 0) return [];

      // 투표 데이터 처리
      const processedVotes = voteData.map((vote: any) => {
        // 각 투표의 최대 투표 수 계산
        let maxVoteTotal = 0;
        // 원본 vote_items를 저장
        const allVoteItems = vote.vote_items || [];
        
        // vote_items 투표 수 기준으로 정렬하고 상위 3개만 선택
        const topVoteItems = [...allVoteItems]
          .sort((a, b) => (b.vote_total || 0) - (a.vote_total || 0))
          .slice(0, 3);
        
        // 각 투표 아이템의 아티스트 정보 로그 출력
        topVoteItems.forEach((item, idx) => {
          // 깊은 복사하여 출력 (순환 참조 방지)
          const safeItem = JSON.parse(JSON.stringify({
            id: item.id,
            vote_id: item.vote_id,
            group_id: item.group_id,
            artist_id: item.artist_id,
            vote_total: item.vote_total
          }));
          
          
          if (item.artist) {
            const artistName = typeof item.artist.name === 'object' 
              ? getLocalizedName(item.artist.name)
              : item.artist.name || '이름 없음';
              
          }
        });
        
        if (allVoteItems.length > 0) {
          maxVoteTotal = allVoteItems.reduce(
            (max: number, item: any) => Math.max(max, item.vote_total || 0),
            0
          );
        }

        // 투표 상태 계산
        const status = getVoteStatus(vote);
        
        return {
          id: vote.id?.toString() || '',
          title: typeof vote.vote_title === 'string' ? vote.vote_title : 
                typeof vote.title_ko === 'string' ? vote.title_ko : 
                (vote.title && typeof vote.title === 'object' && vote.title.ko) ? vote.title.ko : '제목 없음',
          description: typeof vote.vote_content === 'string' ? vote.vote_content : '',
          createdAt: vote.created_at || '',
          deletedAt: vote.deleted_at || null,
          mainImage: vote.main_image || '',
          order: vote.order || 0,
          startAt: vote.start_at || '',
          stopAt: vote.stop_at || '',
          updatedAt: vote.updated_at || '',
          voteCategory: vote.vote_category || '',
          voteSubCategory: vote.vote_sub_category || '',
          voteTotal: maxVoteTotal,
          voteItems: topVoteItems,
          totalVoteItemsCount: allVoteItems.length,
          resultImage: vote.result_image || '',
          visibleAt: vote.visible_at || '',
          voteContent: vote.vote_content || '',
          waitImage: vote.wait_image || '',
          rank: vote.order || 0,
          displayRank: vote.order || 0,
          status: vote.vote_category || '',
          vote_items: true,
          artistId: null,
          groupId: null,
          voteId: vote.id?.toString() || ''
        };
      });

      // 정렬 방식에 따라 데이터 정렬
      let sortedVotes = [...processedVotes];
      
      if (sortBy === 'votes') {
        // 투표 수 기준 내림차순 정렬
        sortedVotes.sort((a, b) => b.voteTotal - a.voteTotal);
      }
      // recent는 이미 created_at으로 정렬되어 있으므로 추가 정렬 불필요

      // 요청된 수만큼 결과 반환 (limit이 0이면 모두 반환)
      const result = limit > 0 ? sortedVotes.slice(0, limit) : sortedVotes;
      
      // 모든 투표에 순위 정보 추가 (전체 순위)
      result.forEach((vote, index) => {
        // 투표수 기준 전체 순위 계산
        const globalRank = sortedVotes.findIndex(v => v.id === vote.id) + 1;
        (vote as any).rank = globalRank;
        
        // 현재 결과 내에서의 순위도 추가
        (vote as any).displayRank = index + 1;
      });

      return result;
    } catch (error) {
      console.error('투표 데이터를 가져오는 중 오류가 발생했습니다:', error);
      return [];
    }
  };

  /**
   * 리워드 데이터를 가져옵니다.
   */
  const getRewards = async (): Promise<Reward[]> => {
    try {
      // 리워드 데이터 가져오기 (deleted_at이 null인 것만)
      const { data: rewardData, error: rewardError } = await supabase
        .from('reward')
        .select('*')
        .is('deleted_at', null)
        .order('id', { ascending: true })
        .limit(4);

      if (rewardError) throw rewardError;

      // 리워드 데이터 형식 맞추기
      const formattedRewards = rewardData?.map((reward: any) => ({
        id: reward.id,
        title: reward.title,
        thumbnail: reward.thumbnail,
        createdAt: reward.created_at,
        deletedAt: reward.deleted_at,
        location: reward.location,
        locationImages: reward.location_images,
        order: reward.order,
        overviewImages: reward.overview_images,
        sizeGuide: reward.size_guide,
        sizeGuideImages: reward.size_guide_images,
        updatedAt: reward.updated_at
      })) || [];

      return formattedRewards;
    } catch (error) {
      console.error('리워드 데이터를 가져오는 중 오류가 발생했습니다:', error);
      return [];
    }
  };

  /**
   * 배너 데이터를 가져옵니다.
   */
  const getBanners = async (): Promise<Banner[]> => {
    try {
      const currentTime = new Date().toISOString();

      // 배너 데이터 가져오기 (deleted_at이 null이고 현재 시간에 해당하는 것만)
      const { data: bannerData, error: bannerError } = await supabase
        .from('banner')
        .select('*')
        .is('deleted_at', null)
        .lte('start_at', currentTime) // 시작 시간이 현재 시간보다 이전이거나 같은 배너
        .gte('end_at', currentTime)   // 종료 시간이 현재 시간보다 나중이거나 같은 배너
        .order('id', { ascending: true })
        .limit(2); // 두 개만 가져오기

      if (bannerError) throw bannerError;
      
      // 시작/종료 시간이 설정되지 않은 배너도 조회 (항상 표시됨)
      const { data: alwaysVisibleBanners, error: alwaysVisibleError } = await supabase
        .from('banner')
        .select('*')
        .is('deleted_at', null)
        .or('start_at.is.null,end_at.is.null') // 시작 또는 종료 시간이 null인 배너
        .order('id', { ascending: true })
        .limit(2); // 두 개만 가져오기
        
      if (alwaysVisibleError) throw alwaysVisibleError;
      
      // 두 배너 데이터 합치기 (중복 제거)
      const mergedBannerData = [
        ...(bannerData || []),
        ...(alwaysVisibleBanners || []).filter(
          (banner) => !(bannerData || []).some((b) => b.id === banner.id)
        ),
      ].slice(0, 2); // 최대 2개만 사용

      // 배너 데이터 형식 맞추기
      const formattedBanners = mergedBannerData?.map((banner: any) => ({
        id: banner.id,
        title: banner.title,
        image: banner.image,
        link: banner.link,
        startAt: banner.start_at,
        endAt: banner.end_at,
        celebId: banner.celeb_id,
        createdAt: banner.created_at,
        deletedAt: banner.deleted_at,
        duration: banner.duration,
        location: banner.location,
        order: banner.order,
        thumbnail: banner.thumbnail,
        updatedAt: banner.updated_at
      })) || [];

      return formattedBanners;
    } catch (error) {
      console.error('배너 데이터를 가져오는 중 오류가 발생했습니다:', error);
      return [];
    }
  };

  // 투표 상태 표시 텍스트
  const getStatusText = (status?: VoteStatus): string => {
    if (!status) return '';
    
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

  // 기간 표시 텍스트
  const getPeriodText = (startDate?: string, endDate?: string): string => {
    if (!startDate || !endDate) return '';
    
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffDays = differenceInDays(end, start);
    
    if (diffDays < 0) return '';
    
    const startFormatted = format(start, 'MM/dd', { locale: ko });
    const endFormatted = format(end, 'MM/dd', { locale: ko });
    
    return `${startFormatted} ~ ${endFormatted} (${diffDays}일)`;
  };

  // 다국어 이름 객체에서 가장 적절한 이름을 가져오는 함수
  const getLocalizedName = (nameObj: any): string => {
    if (!nameObj) return '이름 없음';
    
    // 문자열인 경우 그대로 반환
    if (typeof nameObj === 'string') return nameObj;
    
    // 객체인 경우 다음 순서로 이름 반환: ko > en > 첫 번째 언어
    if (typeof nameObj === 'object') {
      if (nameObj.ko) return nameObj.ko;
      if (nameObj.en) return nameObj.en;
      
      // 첫 번째 키의 값 반환
      const firstKey = Object.keys(nameObj)[0];
      if (firstKey) return nameObj[firstKey];
    }
    
    return '이름 없음';
  };

  return (
    <div className="min-h-screen">
      {/* 메뉴 + 현재 시간 */}
      <div className="bg-gray-50 border-b">
        <div className="container mx-auto px-0">
          <Menu currentDateTime={currentDateTime} />
        </div>
      </div>
      
      {isLoading ? (
        <div className="flex justify-center items-center min-h-[300px]">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
        </div>
      ) : error ? (
        <div className="bg-red-100 text-red-700 p-4 rounded-md">
          {error}
        </div>
      ) : (
        <div className="container mx-auto px-4 py-6 space-y-10">
          {/* 배너 리스트 섹션 */}
          <section>
            <div className="mb-4">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold">배너</h2>
                <Link href="/banner" className="text-primary text-sm hover:underline">
                  전체보기
                </Link>
              </div>
              
              {banners.length === 0 ? (
                <div className="bg-gray-100 p-6 rounded-lg text-center">
                  <p className="text-gray-500">현재 표시할 배너가 없습니다.</p>
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-4">
                  {banners.map((banner: Banner) => (
                    <Link key={banner.id} href={banner.link || '#'}>
                      <div className="w-full h-[180px] rounded-lg bg-gray-200 overflow-hidden hover:shadow-lg transition-shadow">
                        {banner.image ? (
                          <img 
                            src={getCachedBannerImageUrl(getLocalizedImage(banner.image))} 
                            alt={typeof banner.title === 'string' ? banner.title : '배너'} 
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              console.error(`배너 이미지 로드 실패: ${banner.image}`);
                              // 이미지 로드 실패 시 기본 이미지 표시
                              e.currentTarget.src = '/images/banner-placeholder.jpg';
                            }}
                          />
                        ) : (
                        <div className="w-full h-full flex items-center justify-center">
                            <span className="text-gray-600">
                              {typeof banner.title === 'string' ? banner.title : '배너'}
                            </span>
                        </div>
                        )}
                      </div>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </section>

          {/* 리워드 리스트 섹션 */}
          <section>
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">리워드</h2>
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
                        <img 
                          src={getCachedRewardImageUrl(reward.thumbnail)} 
                          alt={typeof reward.title === 'string' ? reward.title : '리워드'} 
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            console.error(`리워드 이미지 로드 실패: ${reward.thumbnail}`);
                            // 이미지 로드 실패 시 기본 이미지 표시
                            e.currentTarget.src = '/images/reward-placeholder.jpg';
                          }}
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                      <span className="text-gray-600">리워드 이미지</span>
                        </div>
                      )}
                  </div>
                  <div className="p-3">
                      <h3 className="font-medium mb-1 truncate text-gray-800">
                        {typeof reward.title === 'string' ? reward.title : '리워드'}
                      </h3>
                  </div>
                </div>
              ))}
            </div>
            )}
          </section>

          {/* 투표 섹션 */}
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
              <div className="grid grid-cols-2 md:grid-cols-2 gap-6">
                {votes.slice(0, 6).map((vote: Vote, index: number) => (
                <Link href={`/vote/${vote.id}`} key={vote.id}>
                    <div className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
                      <div className="relative">
                        {vote.mainImage && (
                          <div className="h-40 bg-gray-200 relative">
                            <img 
                              src={getCachedVoteImageUrl(vote.id.toString(), vote.mainImage)} 
                              alt={typeof vote.title === 'string' ? vote.title : '투표'} 
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.src = '/images/vote_placeholder.png';
                              }}
                            />
                            
                            {/* 순위 뱃지 */}
                            <div className={`absolute top-3 left-3 w-10 h-10 rounded-full ${RANK_BADGE_COLORS[index < 3 ? index : 3]} flex items-center justify-center text-white font-bold text-xl shadow-md`}>
                              {getVoteRank(vote, index)}
                            </div>
                            
                            {/* 상태 태그 */}
                            {vote.voteCategory && (
                              <div className={`absolute top-2 right-2 px-3 py-1 rounded-full text-xs font-medium ${STATUS_TAG_COLORS[getVoteStatus(vote)]} shadow`}>
                                {getStatusText(getVoteStatus(vote))}
                              </div>
                            )}
                        </div>
                        )}
                      </div>
                      
                      <div className="p-4">
                        <h3 className="font-medium mb-2 line-clamp-2 text-gray-800">
                          {typeof vote.title === 'string' ? vote.title : '제목 없음'}
                        </h3>
                        
                        {/* 투표 아이템 디버그 정보 */}
                        <div className="text-xs text-gray-500 mb-2 bg-gray-50 p-2 rounded">
                          {/* 상위 투표 아이템 리스트 */}
                          {vote.voteItems && vote.voteItems.length > 0 && (
                            <div className="mt-2 space-y-2">
                              {vote.voteItems.map((item: any, idx: number) => (
                                <div key={item.id} className="flex items-start p-2 bg-white rounded shadow-sm">
                                  <div className="w-12 h-12 mr-2 bg-gray-200 rounded overflow-hidden flex-shrink-0">
                                    {item.artist && item.artist.image ? (
                                      <img 
                                        src={typeof item.artist.image === 'string' ? `${cdnUrl}/${item.artist.image}` : '/images/artist_placeholder.png'} 
                                        alt={getLocalizedName(item.artist.name)}
                                        className="w-full h-full object-cover"
                                        onError={(e) => {
                                          const target = e.target as HTMLImageElement;
                                          target.src = '/images/artist_placeholder.png';
                                        }}
                                      />
                                    ) : item.image_path ? (
                                      <img 
                                        src={typeof item.image_path === 'string' ? item.image_path : '/images/vote_placeholder.png'} 
                                        alt={getLocalizedName(item.name || item.title)}
                                        className="w-full h-full object-cover"
                                        onError={(e) => {
                                          const target = e.target as HTMLImageElement;
                                          target.src = '/images/vote_placeholder.png';
                                        }}
                                      />
                                    ) : (
                                      <div className="w-full h-full flex items-center justify-center text-gray-400 text-xl">
                                        📷
                                      </div>
                                    )}
                                  </div>
                                  <div className="flex-grow">
                                    {item.artist && (
                                      <div className="flex items-center text-xs text-gray-500">
                                        <span className="inline-block w-4 h-4 mr-1">👤</span> 
                                        {getLocalizedName(item.artist.name)}
                                      </div>
                                    )}
                                    <div className="flex justify-between mt-1">
                                      <span className="text-primary font-bold">{item.vote_total?.toLocaleString() || 0}표</span>
                                      <span className="bg-gray-200 text-gray-700 px-2 py-0.5 rounded">#{idx+1}</span>
                      </div>
                    </div>
                  </div>
              ))}
            </div>
                          )}
                        </div>
                        
                        <div className="flex justify-between items-center text-xs text-gray-500">
                          {vote.startAt && vote.stopAt && (
                            <span className="text-gray-400">
                              {getPeriodText(vote.startAt, vote.stopAt)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </section>
        </div>
      )}
      
      {/* 공통 푸터 사용 */}
      <Footer />
    </div>
  );
};

export default VotePage; 