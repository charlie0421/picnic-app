import React from 'react';
import { Table, Space, Button, Tag } from 'antd';
import { useNavigation, useDelete } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField } from '@refinedev/antd';
import { TableProps } from 'antd/es/table';
import { FAQ } from '@/lib/types/faq';

interface FAQListProps {
  tableProps: TableProps<FAQ>;
}

export const FAQList: React.FC<FAQListProps> = ({ tableProps }) => {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: '질문',
      dataIndex: 'question',
      key: 'question',
      render: (value: string, record: FAQ) => (
        <span style={{ cursor: 'pointer' }} onClick={() => show('faqs', record.id)}>
          {value}
        </span>
      ),
    },
    {
      title: '카테고리',
      dataIndex: 'category',
      key: 'category',
      width: 120,
      render: (value: string) => value || '-',
    },
    {
      title: '상태',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (value: string) => {
        let color = 'default';
        if (value === 'PUBLISHED') color = 'green';
        if (value === 'DRAFT') color = 'gold';
        if (value === 'ARCHIVED') color = 'gray';
        
        return <Tag color={color}>{value}</Tag>;
      },
    },
    {
      title: '순서',
      dataIndex: 'order_number',
      key: 'order_number',
      width: 80,
    },
    {
      title: '작성자',
      key: 'created_by',
      width: 120,
      render: (_: any, record: FAQ) => {
        const userName = record.created_by_user?.user_metadata?.name || record.created_by_user?.email || '시스템';
        return userName;
      },
    },
    {
      title: '액션',
      key: 'actions',
      width: 120,
      render: (_: any, record: FAQ) => (
        <Space>
          <ShowButton size="small" recordItemId={record.id} />
          <EditButton size="small" recordItemId={record.id} />
          <DeleteButton
            size="small"
            recordItemId={record.id}
            resource="faqs"
          />
        </Space>
      ),
    },
  ];

  return (
    <Table
      {...tableProps}
      rowKey="id"
      columns={columns}
    />
  );
}; 