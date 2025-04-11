'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Descriptions, Button, message, Space } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Show } from '@refinedev/antd';
import { createSupabaseClient } from '../../supabase';

interface Props {
  resource: string;
  id: string;
}

export function ResourceDetail({ resource, id }: Props) {
  const router = useRouter();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(resource);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const result = await supabase.getById(id);
        setData(result);
      } catch (error) {
        message.error('데이터를 불러오는데 실패했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  if (!data) {
    return <div>로딩 중...</div>;
  }

  return (
    <AuthorizePage resource={resource} action='show'>
      <Show
        isLoading={loading}
        title="상세 정보"
        headerButtons={({ defaultButtons }) => (
          <Space>
            {defaultButtons}
            <Button onClick={() => router.push(`/${resource}/edit/${id}`)}>
              수정
            </Button>
            <Button onClick={() => router.push(`/${resource}`)}>
              목록으로
            </Button>
          </Space>
        )}
      >
        <Descriptions bordered column={1}>
          <Descriptions.Item label='이름'>{data.name}</Descriptions.Item>
          <Descriptions.Item label='설명'>{data.description}</Descriptions.Item>
          <Descriptions.Item label='생성일'>
            {new Date(data.created_at).toLocaleString()}
          </Descriptions.Item>
          <Descriptions.Item label='수정일'>
            {new Date(data.updated_at).toLocaleString()}
          </Descriptions.Item>
        </Descriptions>
      </Show>
    </AuthorizePage>
  );
} 