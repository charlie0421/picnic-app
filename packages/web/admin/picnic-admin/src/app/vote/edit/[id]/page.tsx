'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useEffect, useState } from 'react';
import { useNavigation, useOne } from '@refinedev/core';
import { VoteItem } from '@/types/vote';
import { VoteRecord } from '@/utils/vote';
import VoteForm from '@/components/vote/VoteForm';

export default function VoteEdit({ params }: { params: { id: string } }) {
  const { push } = useNavigation();
  const [messageApi, contextHolder] = message.useMessage();
  const [initialVoteItems, setInitialVoteItems] = useState<VoteItem[]>([]);

  // 데이터 불러오기
  const {
    data: voteData,
    isLoading,
    isError,
  } = useOne({
    resource: 'vote',
    id: params.id,
    meta: {
      select:
        'id, title, main_image, vote_category, start_at, stop_at, visible_at, vote_item!vote_id(id, artist_id, vote_total, artist(id, name, image, birth_date, yy, mm, dd, artist_group(id, name, image, debut_yy, debut_mm, debut_dd)))',
    },
  });

  // 폼 정의
  const { formProps, saveButtonProps, id } = useForm<VoteRecord>({
    redirect: false, // 리디렉션 비활성화 - 투표 항목 저장 후 직접 처리
    warnWhenUnsavedChanges: true,
  });

  // 초기 투표 항목 설정
  useEffect(() => {
    if (voteData?.data?.vote_item) {
      const voteItems = voteData.data.vote_item.map((item: any) => ({
        ...item,
        temp_id: item.id, // 기존 항목은 DB ID를 임시 ID로 사용
        is_existing: true, // 기존 항목 표시
      }));
      setInitialVoteItems(voteItems);
    } else {
    }
  }, [voteData]);

  // 데이터 로딩 중이면 로딩 표시
  if (isLoading) {
    return (
      <Edit title='투표 수정'>
        <div style={{ textAlign: 'center', padding: '50px' }}>
          <Spin tip='데이터를 불러오는 중...' />
        </div>
      </Edit>
    );
  }

  // 데이터 로드 실패 시 에러 메시지
  if (isError) {
    return (
      <Edit title='투표 수정'>
        <div style={{ textAlign: 'center', padding: '50px', color: 'red' }}>
          데이터를 불러오는 중 오류가 발생했습니다.
        </div>
      </Edit>
    );
  }

  return (
    <Edit title='투표 수정'>
      {contextHolder}
      <VoteForm
        mode='edit'
        id={params.id}
        initialVoteItems={initialVoteItems}
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Edit>
  );
}
