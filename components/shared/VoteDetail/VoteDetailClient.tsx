'use client';

import React, { useState, useEffect } from 'react';
import { useSupabase } from '@/components/providers/SupabaseProvider';
import { useRouter } from 'next/navigation';
import { Vote, VoteItem, Reward } from '@/types/interfaces';
import { UserVote, SupabaseRpcResponse, Database } from '@/types/supabase';
import { LoadingSpinner } from '@/components/client';
import { useLanguageStore } from '@/stores/languageStore';

interface VoteDetailContentProps {
  id: string;
  initialData: {
    vote: Vote;
    voteItems: VoteItem[];
    rewards: Reward[];
    voteStatus: 'upcoming' | 'ongoing' | 'ended';
  };
}

interface VoteState {
  vote: Vote | null;
  voteItems: VoteItem[];
  rewards: Reward[];
  voteStatus: 'upcoming' | 'ongoing' | 'ended';
  isLoading: boolean;
  error: string | null;
}

const VoteDetailClient: React.FC<VoteDetailContentProps> = ({ id, initialData }) => {
  const { supabase } = useSupabase();
  const router = useRouter();
  const { currentLanguage } = useLanguageStore();
  
  // 투표 상태 초기화
  const [state, setState] = useState<VoteState>({
    vote: initialData.vote,
    voteItems: initialData.voteItems,
    rewards: initialData.rewards,
    voteStatus: initialData.voteStatus,
    isLoading: false,
    error: null
  });
  
  // 사용자 참여 상태
  const [userVoteState, setUserVoteState] = useState({
    hasVoted: false,
    selectedItemId: null as string | null,
    isSubmitting: false,
    participationError: null as string | null
  });

  // 사용자의 참여 여부 확인
  useEffect(() => {
    const checkUserParticipation = async () => {
      try {
        const { data: session } = await supabase.auth.getSession();
        
        if (session?.session?.user) {
          // 사용자 정의 쿼리 (Database 타입에 없는 테이블)
          const { data, error } = await supabase
            .rpc('get_user_vote', {
              p_vote_id: id,
              p_user_id: session.session.user.id
            }) as unknown as { data: UserVote | null; error: any };
            
          if (data && !error) {
            setUserVoteState(prev => ({
              ...prev,
              hasVoted: true,
              selectedItemId: data.vote_item_id
            }));
          }
        }
      } catch (error) {
        console.error('사용자 참여 확인 오류:', error);
      }
    };
    
    if (id) {
      checkUserParticipation();
    }
  }, [id, supabase]);

  // 데이터 재요청 (언어 변경 시)
  useEffect(() => {
    if (currentLanguage && id) {
      const refreshData = async () => {
        try {
          setState(prev => ({ ...prev, isLoading: true }));
          
          // 타입 변환 필요: id가 문자열인데 숫자로 변환해야 함
          const numericId = parseInt(id, 10);
          if (isNaN(numericId)) {
            throw new Error('유효하지 않은 ID 형식입니다.');
          }
          
          // 데이터 다시 가져오기 (필요한 경우)
          const { data: voteData } = await supabase
            .from('vote')
            .select(`
              *,
              vote_item!vote_id (
                id,
                vote_id,
                artist_id,
                group_id,
                vote_total,
                created_at,
                updated_at,
                deleted_at,
                artist (
                  id,
                  name,
                  image,
                  artist_group (
                    id,
                    name
                  )
                )
              ),
              vote_reward (
                reward_id,
                reward:reward_id (*)
              )
            `)
            .eq('id', numericId)
            .is('deleted_at', null)
            .single();
            
          if (voteData) {
            // 데이터 가공 (필요시)
            const formattedVote = {
              id: voteData.id,
              // Vote 인터페이스 요구사항에 맞는 속성 추가
              order: 0, // 기본값 설정 (Vote 인터페이스 요구사항)
              area: '', // 기본값 설정 (Vote 인터페이스 요구사항)
              deletedAt: voteData.deleted_at,
              startAt: voteData.start_at,
              stopAt: voteData.stop_at,
              createdAt: voteData.created_at,
              updatedAt: voteData.updated_at,
              mainImage: voteData.main_image,
              resultImage: voteData.result_image,
              waitImage: voteData.wait_image,
              voteCategory: voteData.vote_category,
              voteContent: voteData.vote_content,
              voteSubCategory: voteData.vote_sub_category,
              visibleAt: voteData.visible_at,
              title: voteData.title || '제목 없음',
            };
            
            const formattedVoteItems = voteData.vote_item
              ? voteData.vote_item.map((item: any) => ({
                  ...item,
                  id: item.id,
                  deletedAt: item.deleted_at,
                  createdAt: item.created_at,
                  updatedAt: item.updated_at,
                  voteId: item.vote_id,
                  artistId: item.artist_id,
                  groupId: item.group_id,
                  voteTotal: item.vote_total || 0,
                  artist: item.artist
                    ? {
                        ...item.artist,
                        id: item.artist.id,
                        name: item.artist.name,
                        image: item.artist.image,
                        artistGroup: item.artist.artist_group // 네이밍 수정
                      }
                    : null,
                }))
              : [];
              
            const formattedRewards = voteData.vote_reward
              ? voteData.vote_reward.map((vr: any) => vr.reward).filter(Boolean)
              : [];
            
            // 투표 상태 재계산
            const now = new Date();
            const startDate = new Date(formattedVote.startAt as string);
            const endDate = new Date(formattedVote.stopAt as string);
            
            let voteStatus: 'upcoming' | 'ongoing' | 'ended' = 'upcoming';
            if (now < startDate) {
              voteStatus = 'upcoming';
            } else if (now < endDate) {
              voteStatus = 'ongoing';
            } else {
              voteStatus = 'ended';
            }
            
            setState({
              vote: formattedVote as Vote, // 타입 변환
              voteItems: formattedVoteItems as VoteItem[],
              rewards: formattedRewards as Reward[],
              voteStatus,
              isLoading: false,
              error: null
            });
          }
        } catch (error) {
          console.error('데이터 새로 고침 오류:', error);
          setState(prev => ({
            ...prev,
            isLoading: false,
            error: '데이터를 업데이트하는 중 오류가 발생했습니다.'
          }));
        }
      };
      
      refreshData();
    }
  }, [currentLanguage, id, supabase]);

  // 투표 항목 선택 핸들러
  const handleSelectItem = (itemId: string) => {
    if (state.voteStatus !== 'ongoing' || userVoteState.hasVoted) {
      return;
    }
    
    setUserVoteState(prev => ({
      ...prev,
      selectedItemId: itemId
    }));
  };

  // 투표 제출 핸들러
  const handleSubmitVote = async () => {
    if (!userVoteState.selectedItemId || userVoteState.isSubmitting) {
      return;
    }
    
    try {
      setUserVoteState(prev => ({ ...prev, isSubmitting: true }));
      
      const { data: session } = await supabase.auth.getSession();
      
      if (!session?.session?.user) {
        // 로그인 페이지로 리다이렉트
        router.push(`/login?redirect=/vote/${id}`);
        return;
      }
      
      // 투표 등록 - RPC 함수 사용
      const { error: voteError } = await supabase
        .rpc('add_user_vote', {
          p_user_id: session.session.user.id,
          p_vote_id: id,
          p_vote_item_id: userVoteState.selectedItemId
        }) as unknown as SupabaseRpcResponse;
        
      if (voteError) {
        throw voteError;
      }
      
      // 투표 카운트 증가 - RPC 함수 사용
      const { error: updateError } = await supabase.rpc('increment_vote', {
        vote_item_id: userVoteState.selectedItemId
      }) as unknown as SupabaseRpcResponse;
      
      if (updateError) {
        throw updateError;
      }
      
      // 성공적으로 투표 완료
      setUserVoteState(prev => ({
        ...prev,
        hasVoted: true,
        isSubmitting: false,
        participationError: null
      }));
      
      // 데이터 갱신
      refreshVoteData();
      
    } catch (error) {
      console.error('투표 제출 오류:', error);
      setUserVoteState(prev => ({
        ...prev,
        isSubmitting: false,
        participationError: '투표 제출 중 오류가 발생했습니다. 다시 시도해주세요.'
      }));
    }
  };

  // 투표 데이터 새로고침
  const refreshVoteData = async () => {
    try {
      setState(prev => ({ ...prev, isLoading: true }));
      
      // ID를 숫자로 변환
      const numericId = parseInt(id, 10);
      if (isNaN(numericId)) {
        throw new Error('유효하지 않은 ID 형식입니다.');
      }
      
      // 투표 항목 데이터 다시 가져오기
      const { data: voteItemsData, error: voteItemsError } = await supabase
        .from('vote_item')
        .select(`
          id,
          vote_id,
          artist_id,
          group_id,
          vote_total,
          created_at,
          updated_at,
          deleted_at,
          artist (
            id,
            name,
            image,
            artist_group (
              id,
              name
            )
          )
        `)
        .eq('vote_id', numericId)
        .is('deleted_at', null);
        
      if (voteItemsError) {
        throw voteItemsError;
      }
      
      const formattedVoteItems = voteItemsData.map((item: any) => ({
        ...item,
        id: item.id,
        deletedAt: item.deleted_at,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
        voteId: item.vote_id,
        artistId: item.artist_id,
        groupId: item.group_id,
        voteTotal: item.vote_total || 0,
        artist: item.artist
          ? {
              ...item.artist,
              id: item.artist.id,
              name: item.artist.name,
              image: item.artist.image,
              artistGroup: item.artist.artist_group // 네이밍 수정
            }
          : null,
      }));
      
      setState(prev => ({
        ...prev,
        voteItems: formattedVoteItems as VoteItem[],
        isLoading: false
      }));
      
    } catch (error) {
      console.error('투표 데이터 새로고침 오류:', error);
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: '데이터를 업데이트하는 중 오류가 발생했습니다.'
      }));
    }
  };

  // 로딩 중일 때 표시할 내용
  if (state.isLoading) {
    return <LoadingSpinner />;
  }

  // 오류가 있을 때 표시할 내용
  if (state.error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[300px] text-center">
        <p className="text-red-500">{state.error}</p>
        <button 
          className="mt-4 px-4 py-2 bg-primary text-white rounded"
          onClick={refreshVoteData}
        >
          다시 시도
        </button>
      </div>
    );
  }

  // 투표 데이터가 없을 때 표시할 내용
  if (!state.vote) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[300px] text-center">
        <p className="text-gray-500">투표 정보를 찾을 수 없습니다.</p>
      </div>
    );
  }

  // 제목 정보 표시를 위한 헬퍼 함수
  const renderTitle = () => {
    if (!state.vote) return '제목 없음';
    
    if (typeof state.vote.title === 'string') {
      return state.vote.title;
    } else if (state.vote.title && typeof state.vote.title === 'object') {
      // 다국어 제목 처리
      const titleObj = state.vote.title as { ko?: string; en?: string };
      return titleObj.ko || titleObj.en || '제목 없음';
    }
    return '제목 없음';
  };

  // vote가 null이 아닌 것이 확실한 시점
  const vote = state.vote;

  return (
    <div className="container mx-auto px-4 py-8">
      {/* 투표 헤더 */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">{renderTitle()}</h1>
        <p className="text-gray-600">
          {new Date(vote.startAt as string).toLocaleDateString()} ~ 
          {new Date(vote.stopAt as string).toLocaleDateString()}
        </p>
      </div>
      
      {/* 투표 상태 표시 */}
      <div className="mb-6">
        {state.voteStatus === 'upcoming' && (
          <div className="bg-blue-100 text-blue-800 px-4 py-2 rounded">
            투표 예정 - {new Date(vote.startAt as string).toLocaleString()}부터 시작됩니다.
          </div>
        )}
        {state.voteStatus === 'ongoing' && (
          <div className="bg-green-100 text-green-800 px-4 py-2 rounded">
            투표 진행 중 - {new Date(vote.stopAt as string).toLocaleString()}에 종료됩니다.
          </div>
        )}
        {state.voteStatus === 'ended' && (
          <div className="bg-gray-100 text-gray-800 px-4 py-2 rounded">
            투표 종료 - {new Date(vote.stopAt as string).toLocaleString()}에 종료되었습니다.
          </div>
        )}
      </div>
      
      {/* 투표 내용 */}
      <div className="mb-8">
        <p className="whitespace-pre-line">{vote.voteContent}</p>
      </div>
      
      {/* 참여 오류 메시지 */}
      {userVoteState.participationError && (
        <div className="bg-red-100 text-red-800 px-4 py-2 rounded mb-6">
          {userVoteState.participationError}
        </div>
      )}
      
      {/* 투표 항목 목록 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 mb-8">
        {state.voteItems.map((item) => {
          // ID를 문자열로 변환하여 비교
          const itemId = String(item.id);
          return (
            <div 
              key={itemId}
              className={`border rounded-lg p-4 cursor-pointer transition-all ${
                userVoteState.selectedItemId === itemId
                  ? 'border-primary bg-primary/10' 
                  : 'border-gray-200 hover:border-primary'
              } ${
                state.voteStatus !== 'ongoing' || userVoteState.hasVoted 
                  ? 'opacity-80' 
                  : ''
              }`}
              onClick={() => handleSelectItem(itemId)}
            >
              {/* 투표 항목 이미지 */}
              {item.artist?.image && (
                <div className="aspect-square mb-3 overflow-hidden rounded">
                  <img 
                    src={String(item.artist.image)} 
                    alt={String(item.artist.name) || '아티스트'} 
                    className="w-full h-full object-cover"
                  />
                </div>
              )}
              
              {/* 투표 항목 정보 */}
              <h3 className="text-lg font-semibold mb-1">
                {String(item.artist?.name) || '항목 이름'}
              </h3>
              {item.artist?.artistGroup?.name && (
                <p className="text-sm text-gray-600 mb-2">
                  {String(item.artist.artistGroup.name)}
                </p>
              )}
              
              {/* 투표 수 표시 (종료된 경우만) */}
              {state.voteStatus === 'ended' && (
                <p className="mt-2 font-semibold">
                  {item.voteTotal?.toLocaleString()} 표
                </p>
              )}
              
              {/* 선택 표시 */}
              {userVoteState.selectedItemId === itemId && (
                <div className="mt-2 text-primary font-semibold">
                  {userVoteState.hasVoted ? '투표함' : '선택됨'}
                </div>
              )}
            </div>
          );
        })}
      </div>
      
      {/* 투표 버튼 */}
      {state.voteStatus === 'ongoing' && !userVoteState.hasVoted && (
        <div className="flex justify-center">
          <button
            className={`px-6 py-3 rounded-full text-white font-medium ${
              userVoteState.selectedItemId && !userVoteState.isSubmitting
                ? 'bg-primary hover:bg-primary/90'
                : 'bg-gray-400 cursor-not-allowed'
            }`}
            onClick={handleSubmitVote}
            disabled={!userVoteState.selectedItemId || userVoteState.isSubmitting}
          >
            {userVoteState.isSubmitting ? '처리 중...' : '투표하기'}
          </button>
        </div>
      )}
      
      {/* 리워드 정보 (있는 경우) */}
      {state.rewards.length > 0 && (
        <div className="mt-12">
          <h2 className="text-2xl font-bold mb-4">리워드</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {state.rewards.map((reward) => (
              <div key={String(reward.id)} className="border rounded-lg p-4">
                <h3 className="text-lg font-semibold mb-2">
                  {typeof reward.title === 'string' ? reward.title : 
                   typeof reward.title === 'object' ? JSON.stringify(reward.title) : '리워드'}
                </h3>
                <p className="text-gray-700">
                  {reward.description ? 
                   (typeof reward.description === 'string' ? reward.description : 
                    typeof reward.description === 'object' ? JSON.stringify(reward.description) : '') : 
                   ''}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default VoteDetailClient; 