'use client';

import { Create } from '@refinedev/antd';
import { message, theme } from 'antd';
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
  const { token } = theme.useToken();

  // 폼 설정
  const { formProps } = useForm<VoteRecord>({
    resource: 'vote',
    redirect: false,
    successNotification: false,
  });

  const handleSubmit = async (values: any) => {
    try {
      // 투표의 메인 데이터만 저장하고 관련 데이터는 제외
      const { vote_item, vote_reward, ...voteData } = values;

      // 1. 먼저 투표 메인 데이터 저장 (vote 테이블)
      const response = await formProps.onFinish?.(voteData) as any;
      const voteId = response?.data?.id;
      
      if (!voteId) {
        messageApi.error('투표 생성 실패: 투표 ID를 가져올 수 없습니다');
        return;
      }

      // 2. 관련 데이터 처리 (투표 항목, 리워드 연결 등)
      await handleVoteData({
        voteId: Number(voteId),
        currentVoteItems: vote_item || [],
        voteRewards: vote_reward || [],
      });
      
      messageApi.success('투표가 성공적으로 생성되었습니다');
      
      // 성공 후 리스트 페이지로 이동
      setTimeout(() => {
        push('/vote');
      }, 1000);
      
      return response;
    } catch (error) {
      console.error('투표 생성 중 오류 발생:', error);
      messageApi.error('투표 생성 중 오류가 발생했습니다');
      throw error;
    }
  };

  return (
    <AuthorizePage resource='vote' action='create'>
      <Create
        title='투표 생성'
        breadcrumb={false}
        saveButtonProps={{
          onClick: () => {
            formProps.form?.validateFields()
              .then((values) => {
                handleSubmit(values);
              })
              .catch((error) => {
                console.error('폼 검증 실패:', error);
              });
          },
          style: {
            backgroundColor: token.colorPrimary,
            borderColor: token.colorPrimaryBorder
          }
        }}
        contentProps={{
          style: {
            backgroundColor: token.colorBgContainer,
            padding: '24px',
            borderRadius: token.borderRadiusLG,
            boxShadow: `0 2px 8px ${token.colorBgContainerDisabled}`
          }
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
