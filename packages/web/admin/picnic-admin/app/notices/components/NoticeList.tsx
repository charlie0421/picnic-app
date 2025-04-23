import React from 'react';
import { Space, Tag, message } from 'antd';
import { useNavigation, useDelete, CrudFilters } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField, List, CreateButton } from '@refinedev/antd';
import { Notice } from '@/lib/types/notice';
import { DataTable } from '../../components/common/DataTable';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function NoticeList() {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const createSearchFilters = (value: string, field: string): CrudFilters => {
    if (!value) return [];

    if (field === 'all') {
      const filters: CrudFilters = [];

      filters.push({
        field: 'title',
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

    if (field === 'title') {
      return [
        {
          field: 'title',
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
      title: '제목',
      dataIndex: 'title',
      key: 'title',
      sorter: true,
      render: (value: string, record: Notice) => (
        <Space>
          {record.is_pinned && <Tag color="red">공지</Tag>}
          <span>{value}</span>
        </Space>
      ),
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
      title: '작성자',
      key: 'created_by',
      width: 120,
      render: (_: any, record: Notice) => {
        const userName = record.created_by_user?.user_metadata?.name || record.created_by_user?.email || '시스템';
        return userName;
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
      render: (_: any, record: Notice) => (
        <Space>
          <ShowButton size="small" recordItemId={record.id} />
          <EditButton size="small" recordItemId={record.id} />
          <DeleteButton
            size="small"
            recordItemId={record.id}
            resource="notices"
          />
        </Space>
      ),
    },
  ];

  return (
      <DataTable<Notice>
        resource='notices'
        columns={columns}
        searchFields={[
          { value: 'title', label: '제목' },
          { value: 'id', label: 'ID' },
        ]}
        createSearchFilters={createSearchFilters}
      />
  );
} 