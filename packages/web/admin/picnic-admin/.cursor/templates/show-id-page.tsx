'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Descriptions, Button, message } from 'antd';
import { createSupabaseClient } from '../../lib/supabase';

export default function ShowPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const tableName = '${dirname}';
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(tableName);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const result = await supabase.getById(params.id);
        setData(result);
      } catch (error) {
        message.error('데이터를 불러오는데 실패했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [params.id]);

  if (!data) {
    return <div>로딩 중...</div>;
  }

  return (
    <div className='container mx-auto py-10'>
      <div className='flex justify-between items-center mb-6'>
        <h1 className='text-3xl font-bold'>상세 정보</h1>
        <div className='space-x-2'>
          <Button onClick={() => router.push(`/${tableName}/edit/${data.id}`)}>
            수정
          </Button>
          <Button onClick={() => router.push(`/${tableName}`)}>목록으로</Button>
        </div>
      </div>
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
    </div>
  );
}
