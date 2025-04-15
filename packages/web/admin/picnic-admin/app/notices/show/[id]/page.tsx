'use client';

import { Show } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Button, Space, Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { NoticeDetail } from '../../components';
import { Notice } from '@/lib/types/notice';

export default function NoticeShowPage({ params }: { params: { id: string } }) {
  const { list, edit } = useNavigation();
  const { resource } = useResource();
  const { queryResult } = useShow<Notice>({
    resource: resource?.name,
    id: params.id,
    meta: {
      select: '*,notices_created_by_fkey(*)',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  return (
    <AuthorizePage resource="notices" action="show">
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.label}
        canEdit
        headerButtons={
          <>
            <Space>
              <Button onClick={() => list('notices')}>목록으로</Button>
              <Button type="primary" onClick={() => edit('notices', params.id)}>
                수정
              </Button>
            </Space>
          </>
        }
      >
        {isLoading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : (
          <NoticeDetail record={record} />
        )}
      </Show>
    </AuthorizePage>
  );
} 