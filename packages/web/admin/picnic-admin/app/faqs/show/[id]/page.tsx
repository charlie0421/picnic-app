'use client';

import { Show } from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import { Button, Space, Skeleton } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { FAQDetail } from '../../components';
import { FAQ } from '@/lib/types/faq';

export default function FAQShowPage({ params }: { params: { id: string } }) {
  const { list, edit } = useNavigation();
  const { resource } = useResource();
  const { queryResult } = useShow<FAQ>({
    resource: resource?.name,
    id: params.id,
    meta: {
      select: '*,faqs_created_by_fkey(*)',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  return (
    <AuthorizePage resource="faqs" action="show">
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.label}
        canEdit
        headerButtons={
          <>
            <Space>
              <Button onClick={() => list('faqs')}>목록으로</Button>
              <Button type="primary" onClick={() => edit('faqs', params.id)}>
                수정
              </Button>
            </Space>
          </>
        }
      >
          <FAQDetail record={record} />
      </Show>
    </AuthorizePage>
  );
} 