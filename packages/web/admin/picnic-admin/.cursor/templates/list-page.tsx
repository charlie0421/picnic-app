'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Table, Button, Space, message, Popconfirm } from 'antd';
import { createSupabaseClient } from '../../lib/supabase';

interface Props {
  tableName: string;
  columns: {
    title: string;
    dataIndex: string;
    key: string;
    render?: (text: any, record: any) => React.ReactNode;
  }[];
}

export default function ListPage() {
  const tableName = '${dirname}';
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

  const router = useRouter();
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(tableName);

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
        <Button onClick={() => router.push(`/${tableName}/edit/${record.id}`)}>
          수정
        </Button>
        <Button onClick={() => router.push(`/${tableName}/show/${record.id}`)}>
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
    <div className='container mx-auto py-10'>
      <div className='flex justify-between items-center mb-6'>
        <h1 className='text-3xl font-bold'>목록</h1>
        <Button
          type='primary'
          onClick={() => router.push(`/${tableName}/create`)}
        >
          새로 만들기
        </Button>
      </div>
      <Table
        columns={allColumns}
        dataSource={data}
        rowKey='id'
        loading={loading}
      />
    </div>
  );
}
