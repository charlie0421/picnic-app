'use client';

import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { Vote, VoteItem } from '@/types/interfaces';
import UpcomingVoteItems from '@/components/features/vote/UpcomingVoteItems';
import OngoingVoteItems from '@/components/features/vote/OngoingVoteItems';
import CompletedVoteItems from '@/components/features/vote/CompletedVoteItems';

const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];

interface VoteItemsProps {
  vote: Vote & { voteItems?: Array<VoteItem & { artist?: any }> };
}

/**
 * 투표 항목 컴포넌트
 * 
 * 투표 상태(예정/진행중/완료)에 따라 다른 하위 컴포넌트를 렌더링합니다.
 * 클라이언트 컴포넌트로 구현되어야 하는 이유:
 * 1. 시간 기반 상태 계산(setInterval 사용)
 * 2. 이벤트 핸들러 사용
 * 3. useRef, useCallback 등 React 훅 사용
 */
const VoteItems = React.memo(({ vote }: VoteItemsProps) => {
  const now = useRef(new Date());
  const status = useMemo(() => {
    if (!vote.startAt || !vote.stopAt) return VOTE_STATUS.UPCOMING;
    const start = new Date(vote.startAt);
    const end = new Date(vote.stopAt);
    if (now.current < start) return VOTE_STATUS.UPCOMING;
    if (now.current > end) return VOTE_STATUS.COMPLETED;
    return VOTE_STATUS.ONGOING;
  }, [vote.startAt, vote.stopAt]);

  // 1초마다 현재 시간 업데이트
  useEffect(() => {
    const timer = setInterval(() => {
      now.current = new Date();
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  // 투표 업데이트 핸들러
  const handleVoteChange = useCallback(
    (voteId: string | number, itemId: string | number, newTotal: number) => {
      console.log(
        `VoteItems: 투표 변경 감지 - ${voteId}:${itemId} = ${newTotal}`,
      );
      // 여기서 추가 로직 구현 가능
    },
    [],
  );

  switch (status) {
    case VOTE_STATUS.UPCOMING:
      return <UpcomingVoteItems voteItems={vote.voteItems} />;
    case VOTE_STATUS.ONGOING:
      return <OngoingVoteItems vote={vote} onVoteChange={handleVoteChange} />;
    case VOTE_STATUS.COMPLETED:
      return <CompletedVoteItems vote={vote} />;
    default:
      return null;
  }
});

VoteItems.displayName = 'VoteItems';

export default VoteItems; 