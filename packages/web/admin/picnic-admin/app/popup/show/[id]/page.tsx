'use client';

import { Show } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Button, Space, Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { PopupDetail } from '../../components';
import type { Popup } from '@/lib/types/popup';

export default function PopupShowPage({ params }: { params: { id: string } }) {
  const { list, edit } = useNavigation();
  const { resource } = useResource();
  const { queryResult } = useShow<Popup>({
    resource: resource?.name,
    id: params.id,
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  return (
    <AuthorizePage resource='popup' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label || '팝업 상세'}
        canEdit
        headerButtons={
          <Space>
            <Button onClick={() => list('popup')}>목록으로</Button>
            <Button type='primary' onClick={() => edit('popup', params.id)}>
              수정
            </Button>
          </Space>
        }
      >
        {isLoading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : (
          <PopupDetail record={record} />
        )}
      </Show>
    </AuthorizePage>
  );
}
