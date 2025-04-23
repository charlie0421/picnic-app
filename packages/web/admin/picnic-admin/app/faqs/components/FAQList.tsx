import React from 'react';
import { Space, Tag } from 'antd';
import { useNavigation, useDelete, CrudFilters } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField } from '@refinedev/antd';
import { FAQ } from '@/lib/types/faq';
import { DataTable } from '../../components/common/DataTable';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const FAQList: React.FC = () => {
  const { show } = useNavigation();

  const createSearchFilters = (value: string, field: string): CrudFilters => {
    if (!value) return [];

    if (field === 'all') {
      return [
        {
          field: 'question->>ko',
          operator: 'contains',
          value,
        },
      ];
    }

    if (field === 'question') {
      return [
        {
          field: 'question->>ko',
          operator: 'contains',
          value,
        },
      ];
    }

    if (field === 'answer') {
      return [
        {
          field: 'answer->>ko',
          operator: 'contains',
          value,
        },
      ];
    }

    return [
      {
        field: field,
        operator: 'contains',
        value,
      },
    ];
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      sorter: true,
    },
    {
      title: '질문',
      dataIndex: 'question',
      key: 'question',
      sorter: true,
      render: (value: any) => value?.ko || value,
    },
    {
      title: '카테고리',
      dataIndex: 'category',
      key: 'category',
      width: 120,
      sorter: true,
      render: (value: string) => <Tag>{value || '미분류'}</Tag>,
    },
    {
      title: '상태',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      sorter: true,
      render: (value: string) => {
        let color = 'default';
        if (value === 'PUBLISHED') color = 'green';
        if (value === 'DRAFT') color = 'gold';
        if (value === 'ARCHIVED') color = 'gray';
        
        return <Tag color={color}>{value}</Tag>;
      },
    },
    {
      title: '작성일',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      sorter: true,
      render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm" />,
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
    <DataTable<FAQ>
      resource='faqs'
      columns={columns}
      searchFields={[
        { value: 'question', label: '질문' },
        { value: 'answer', label: '답변' },
      ]}
      createSearchFilters={createSearchFilters}
      onRow={(record) => ({
        onClick: () => show('faqs', record.id),
        style: { cursor: 'pointer' }
      })}
    />
  );
};
