import React from 'react';
import { Space, Tag, message } from 'antd';
import { useNavigation, useDelete, CrudFilters } from '@refinedev/core';
import {
  EditButton,
  ShowButton,
  DeleteButton,
  DateField,
  List,
  CreateButton,
} from '@refinedev/antd';
import { FAQ, convertToDisplayFAQ } from '@/lib/types/faq';
import { DataTable } from '../../components/common/DataTable';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function FAQList() {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const createSearchFilters = (value: string, field: string): CrudFilters => {
    if (!value) return [];

    if (field === 'all') {
      const filters: CrudFilters = [];

      filters.push({
        field: 'question->>ko',
        operator: 'contains',
        value,
      });

      // ID가 숫자인 경우에만 ID 검색 추가
      const numericValue = parseInt(value);
      if (!isNaN(numericValue)) {
        filters.push({
          field: 'id',
          operator: 'eq',
          value: numericValue,
        });
      }

      return filters;
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

    if (field === 'id') {
      const numericValue = parseInt(value);
      if (isNaN(numericValue)) {
        message.warning('ID는 숫자만 입력 가능합니다.');
        return [];
      }

      return [
        {
          field: 'id',
          operator: 'eq',
          value: numericValue,
        },
      ];
    }

    return [];
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
      key: 'question',
      dataIndex: ['question', 'ko'],
      sorter: true,
      render: (value: string, record: FAQ) => {
        // 한국어 질문 표시
        const displayText =
          typeof record.question === 'string'
            ? record.question
            : record.question?.ko || '';

        return displayText;
      },
    },
    {
      title: '카테고리',
      dataIndex: 'category',
      key: 'category',
      width: 120,
      sorter: true,
      render: (value: string) => value || '-',
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
      title: '순서',
      dataIndex: 'order_number',
      key: 'order_number',
      width: 80,
      sorter: true,
    },
    {
      title: '작성자',
      key: 'created_by',
      width: 120,
      render: (_: any, record: FAQ) => {
        const userName =
          record.created_by_user?.user_metadata?.name ||
          record.created_by_user?.email ||
          '시스템';
        return userName;
      },
    },
    {
      title: '액션',
      key: 'actions',
      width: 120,
      render: (_: any, record: FAQ) => (
        <Space>
          <ShowButton size='small' recordItemId={record.id} />
          <EditButton size='small' recordItemId={record.id} />
          <DeleteButton size='small' recordItemId={record.id} resource='faqs' />
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
          { value: 'id', label: 'ID' },
        ]}
        createSearchFilters={createSearchFilters}
      />
  );
}
