import {
  BaseRecord,
  CreateResponse,
  UpdateResponse,
  HttpError,
  UpdateParams,
  PrevContext,
  CreateParams,
} from '@refinedev/core';

type MutateFunction<TData, TError, TVariables, TContext> = (
  variables: TVariables,
  options?: {
    onSuccess?: (data: TData, variables: TVariables, context: TContext) => void;
    onError?: (error: TError, variables: TVariables, context: TContext) => void;
  },
) => void;

interface VoteRewardApi {
  createVoteReward: any;
  deleteVoteReward: any;
}

export const createRewardConnection = async (
  voteId: number,
  rewardId: number,
  api: VoteRewardApi,
) => {
  try {
    console.log(`리워드 연결 생성: vote_id=${voteId}, reward_id=${rewardId}`);

    // 숫자 타입 검증
    if (isNaN(voteId) || voteId <= 0) {
      throw new Error(`유효하지 않은 vote_id: ${voteId}`);
    }

    if (isNaN(rewardId) || rewardId <= 0) {
      throw new Error(`유효하지 않은 reward_id: ${rewardId}`);
    }

    // 연결 생성
    await api.createVoteReward({
      resource: 'vote_reward',
      values: {
        vote_id: voteId,
        reward_id: rewardId,
        deleted: false,
      },
      meta: {
        successNotification: false,
      },
    });

    console.log(`리워드 연결 생성 성공: reward_id=${rewardId}`);
    return true;
  } catch (error) {
    console.error(
      `리워드 연결 생성 실패: vote_id=${voteId}, reward_id=${rewardId}`,
      error,
    );
    throw error;
  }
};

export const deleteRewardConnection = async (
  voteId: number,
  rewardId: number,
  api: VoteRewardApi,
) => {
  try {
    console.log(`리워드 연결 삭제: vote_id=${voteId}, reward_id=${rewardId}`);

    // 기존 연결 삭제
    await api.deleteVoteReward({
      resource: 'vote_reward',
      values: {
        deleted: true,
      },
      meta: {
        query: {
          filter: {
            vote_id: { eq: voteId },
            reward_id: { eq: rewardId },
          },
        },
        successNotification: false,
      },
    });

    console.log(`리워드 연결 삭제 성공: reward_id=${rewardId}`);
    return true;
  } catch (error) {
    console.error(
      `리워드 연결 삭제 실패: vote_id=${voteId}, reward_id=${rewardId}`,
      error,
    );
    throw error;
  }
};

export const handleRewardConnections = async (
  mode: 'create' | 'edit',
  voteId: number,
  selectedRewardIds: number[],
  initialRewardIds: number[],
  api: VoteRewardApi,
) => {
  try {
    console.log('리워드 연결 처리 시작');
    console.log('- 모드:', mode);
    console.log('- 투표 ID:', voteId);
    console.log('- 선택된 리워드:', selectedRewardIds);
    console.log('- 초기 리워드:', initialRewardIds);

    if (mode === 'edit') {
      // 기존 리워드에서 삭제된 항목 찾기
      const toRemove = initialRewardIds.filter(
        (oldId) => !selectedRewardIds.includes(oldId),
      );

      // 새로 추가된 항목 찾기
      const toAdd = selectedRewardIds.filter(
        (newId) => !initialRewardIds.includes(newId),
      );

      console.log('삭제할 리워드 연결:', toRemove);
      console.log('추가할 리워드 연결:', toAdd);

      // 삭제 처리
      if (toRemove.length > 0) {
        console.log(`${toRemove.length}개 리워드 연결 삭제 시작`);
        await Promise.all(
          toRemove.map((rewardId) =>
            deleteRewardConnection(voteId, rewardId, api),
          ),
        );
      }

      // 추가 처리
      if (toAdd.length > 0) {
        console.log(`${toAdd.length}개 리워드 연결 추가 시작`);
        await Promise.all(
          toAdd.map((rewardId) =>
            createRewardConnection(voteId, rewardId, api),
          ),
        );
      }
    } else if (mode === 'create' && selectedRewardIds.length > 0) {
      console.log(`${selectedRewardIds.length}개 리워드 연결 생성 시작`);
      await Promise.all(
        selectedRewardIds.map((rewardId) =>
          createRewardConnection(voteId, rewardId, api),
        ),
      );
    }

    console.log(`===== ${mode} 모드에서 리워드 연결 처리 완료 =====`);
  } catch (error) {
    console.error('리워드 연결 처리 중 오류 발생:', error);
    throw error;
  }
};
