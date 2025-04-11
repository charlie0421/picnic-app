'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Table, Button, Space, message, Popconfirm } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { List } from '@refinedev/antd';
import { createSupabaseClient } from '../../supabase';

interface Props {
  resource: string;
}

export function ResourceList({ resource }: Props) {
  const router = useRouter();
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(resource);

  const columns = [
    {
      title: '이름',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: '설명',
      dataIndex: 'description',
      key: 'description',
    },
    {
      title: '생성일',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (text: string) => new Date(text).toLocaleString(),
    },
  ];

  const fetchData = async () => {
    setLoading(true);
    try {
      const result = await supabase.getAll();
      setData(result);
    } catch (error) {
      message.error('데이터를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDelete = async (id: string) => {
    try {
      await supabase.delete(id);
      message.success('삭제되었습니다.');
      fetchData();
    } catch (error) {
      message.error('삭제에 실패했습니다.');
    }
  };

  const actionColumn = {
    title: '작업',
    key: 'action',
    render: (_: any, record: any) => (
      <Space size='middle'>
        <Button onClick={() => router.push(`/${resource}/edit/${record.id}`)}>
          수정
        </Button>
        <Button onClick={() => router.push(`/${resource}/show/${record.id}`)}>
          상세
        </Button>
        <Popconfirm
          title='삭제하시겠습니까?'
          onConfirm={() => handleDelete(record.id)}
          okText='예'
          cancelText='아니오'
        >
          <Button danger>삭제</Button>
        </Popconfirm>
      </Space>
    ),
  };

  const allColumns = [...columns, actionColumn];

  return (
    <AuthorizePage resource={resource} action='list'>
      <List
        createButtonProps={{
          children: '추가',
        }}
      >
        <Table
          dataSource={data}
          columns={allColumns}
          loading={loading}
          pagination={{
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          rowKey='id'
        />
      </List>
    </AuthorizePage>
  );
} 