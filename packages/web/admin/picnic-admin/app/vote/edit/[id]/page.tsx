'use client';

import { Edit } from '@refinedev/antd';
import { useOne } from '@refinedev/core';
import { message } from 'antd';
import { useEffect } from 'react';
import { useNavigation, BaseKey } from '@refinedev/core';
import { useForm } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import VoteForm from '@/app/vote/components/VoteForm';
import { VoteRecord } from '@/lib/vote';
import { handleVoteData } from '../../lib/voteDataHandler';
import { HttpError } from '@refinedev/core';

export default function VoteEditPage({ params }: { params: { id: string } }) {
  const [messageApi, contextHolder] = message.useMessage();
  const { push } = useNavigation();

  // 폼 설정
  const { formProps, queryResult } = useForm<VoteRecord>({
    resource: 'vote',
    action: 'edit',
    id: params.id,
    meta: {
      select: '*, vote_item(*, artist(*)), vote_reward(*)',
    },
    redirect: false,
    successNotification: false,
  });

  // queryResult로부터 받은 데이터를 이용한 로깅 (디버깅용)
  useEffect(() => {
    if (queryResult?.data?.data) {
      const voteData = queryResult.data.data;
    }
  }, [queryResult?.data]);

  const handleSubmit = async (values: VoteRecord) => {
    try {
      // vote_item과 vote_reward 데이터 분리
      const { vote_item, vote_reward, ...voteData } = values;

      // 투표 기본 정보 업데이트
      const onFinishFn = formProps.onFinish as (
        values: VoteRecord,
      ) => Promise<{ data: { id: BaseKey } }>;
      const result = await onFinishFn(voteData);

      if (result?.data) {
        const voteId = Number(result.data.id);

        try {
          // vote_item과 vote_reward 데이터 처리
          await handleVoteData({
            voteId,
            currentVoteItems: values.vote_item || [],
            existingVoteItems: queryResult?.data?.data?.vote_item || [],
            voteRewards: values.vote_reward || [],
          });

          message.success('투표가 성공적으로 수정되었습니다.');
          push('/vote');
        } catch (error) {
          console.error('데이터 처리 중 오류:', error);
          message.error('데이터 처리 중 오류가 발생했습니다.');
        }
      }

      return result;
    } catch (error) {
      console.error('폼 제출 중 오류 발생:', error);
      message.error('투표 수정 중 오류가 발생했습니다.');
      throw error;
    }
  };

  return (
    <AuthorizePage action='edit'>
      <Edit
        isLoading={queryResult?.isLoading}
        title='투표 수정'
        breadcrumb={false}
        saveButtonProps={{
          onClick: () => {
            formProps.form
              ?.validateFields()
              .then((values) => {
                handleSubmit(values);
              })
              .catch((error) => {
                console.error('폼 검증 실패:', error);
              });
          },
        }}
      >
        {contextHolder}
        <VoteForm
          mode='edit'
          id={params.id}
          formProps={formProps}
          redirectPath='/vote'
          onFinish={handleSubmit}
        />
      </Edit>
    </AuthorizePage>
  );
}
