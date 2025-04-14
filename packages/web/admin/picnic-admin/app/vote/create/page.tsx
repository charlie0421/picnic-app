'use client';

import { Create } from '@refinedev/antd';
import { message } from 'antd';
import { useNavigation } from '@refinedev/core';
import { useForm } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import VoteForm from '@/app/vote/components/VoteForm';
import { VoteRecord } from '@/lib/vote';
import { handleVoteData } from '../lib/voteDataHandler';
import { BaseRecord, BaseKey } from '@refinedev/core';

export default function VoteCreatePage() {
  const [messageApi, contextHolder] = message.useMessage();
  const { push } = useNavigation();

  // 폼 설정
  const { formProps } = useForm<VoteRecord>({
    resource: 'vote',
    redirect: false,
    successNotification: false,
  });

  const handleSubmit = async (values: any) => {
    console.log('Create handleSubmit 실행');
    try {
      // 현재 폼 데이터 로깅
      console.log('Create - 현재 폼 데이터:', values);

      // 투표 기본 정보 생성 (vote_item과 vote_reward 제외)
      const { vote_item, vote_reward, ...voteData } = values;
      console.log('Create - vote 데이터 저장 전:', voteData);

      const result = await (formProps.onFinish?.(
        voteData,
      ) as unknown as Promise<{ data: { id: BaseKey } }>);

      console.log('Create - vote 데이터 저장 결과:', result);

      if (result?.data) {
        const voteId = Number(result.data.id);
        console.log('Create - 생성된 vote ID:', voteId);

        try {
          console.log('Create - vote_item과 vote_reward 처리 시작', {
            vote_item,
            vote_reward,
          });

          // vote_item과 vote_reward 데이터 처리
          await handleVoteData({
            voteId,
            currentVoteItems: vote_item || [],
            existingVoteItems: [], // 생성 시에는 기존 데이터가 없음
            voteRewards: vote_reward || [],
          });

          message.success('투표가 성공적으로 생성되었습니다.');
          push('/vote');
        } catch (error) {
          console.error('Create - 데이터 처리 중 오류:', error);
          message.error('데이터 처리 중 오류가 발생했습니다.');
        }
      }

      return result;
    } catch (error) {
      console.error('Create - 폼 제출 중 오류:', error);
      message.error('투표 생성 중 오류가 발생했습니다.');
      throw error;
    }
  };

  return (
    <AuthorizePage resource='vote' action='create'>
      <Create
        title='투표 생성'
        saveButtonProps={{
          onClick: () => {
            console.log('saveButtonProps 클릭됨');
            formProps.form?.submit();
          },
        }}
      >
        {contextHolder}
        <VoteForm
          mode='create'
          formProps={formProps}
          redirectPath='/vote'
          onFinish={handleSubmit}
        />
      </Create>
    </AuthorizePage>
  );
}
