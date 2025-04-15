'use client';

import { Show } from '@refinedev/antd';
import { useShow, useNavigation } from '@refinedev/core';
import { Button, Space, Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { QnADetail } from '../../components';
import { QnA } from '@/lib/types/qna';

export default function QnAShowPage({ params }: { params: { id: string } }) {
  const { list, edit } = useNavigation();
  const { queryResult } = useShow<QnA>({
    resource: 'qnas',
    id: params.id,
    meta: {
      idField: 'qna_id',
      select: '*,qnas_created_by_fkey(*),qnas_answered_by_fkey(*)',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  return (
    <AuthorizePage resource="qnas" action="show">
      <Show
        isLoading={isLoading}
        title="질문 상세"
        canEdit
        headerButtons={
          <>
            <Space>
              <Button onClick={() => list('qnas')}>목록으로</Button>
              <Button type="primary" onClick={() => edit('qnas', params.id)}>
                수정
              </Button>
            </Space>
          </>
        }
      >
        {isLoading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : (
          <QnADetail record={record} />
        )}
      </Show>
    </AuthorizePage>
  );
} 