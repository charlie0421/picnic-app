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
import type { SortOrder } from 'antd/es/table/interface';
import { MultiLanguageDisplay } from '@/components/ui';
import { Board } from '@/lib/types/board';
import { DataTable } from '../../components/common/DataTable';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function BoardList() {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const createSearchFilters = (value: string, field: string): CrudFilters => {
    if (!value) return [];

    if (field === 'all') {
      const filters: CrudFilters = [];

      filters.push({
        field: 'name->>ko',
        operator: 'contains',
        value,
      });

      if (UUID_REGEX.test(value)) {
        filters.push({
          field: 'board_id',
          operator: 'eq',
          value,
        });
      }

      return filters;
    }

    if (field === 'name') {
      return [
        {
          field: 'name->>ko',
          operator: 'contains',
          value,
        },
      ];
    }

    if (field === 'board_id') {
      if (!UUID_REGEX.test(value)) {
        message.warning(
          'UUID 형식이 올바르지 않습니다. 예: 123e4567-e89b-12d3-a456-426614174000',
        );
        return [];
      }

      return [
        {
          field: 'board_id',
          operator: 'eq',
          value,
        },
      ];
    }

    return [];
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'board_id',
      key: 'board_id',
      width: 80,
      render: (value: string) => (
        <Tag color="blue">{value}</Tag>
      ),
    },
    {
      title: '이름',
      key: 'name',
      dataIndex: ['name', 'ko'],
      sorter: true,
      render: (value: string, record: Board) => {
        return (
          <Space>
            {record.is_official && <Tag color="red">공식</Tag>}
            <span>{value}</span>
          </Space>
        );
      },
    },
    {
      dataIndex: 'status',
      title: '상태',
      width: 120,
      sorter: true,
      render: (value: string) => (
        <Tag
          color={
            value === 'ACTIVE'
              ? 'green'
              : value === 'PENDING'
              ? 'orange'
              : value === 'REJECTED'
              ? 'red'
              : 'default'
          }
        >
          {value}
        </Tag>
      ),
    },
    {
      dataIndex: 'is_official',
      title: '공식 게시판',
      width: 120,
      sorter: true,
      render: (value: boolean) => (
        <Tag color={value ? 'blue' : 'default'}>
          {value ? '공식' : '비공식'}
        </Tag>
      ),
    },
    {
      title: '아티스트',
      width: 120,
      dataIndex: ['artist', 'name', 'ko'],
      render: (_: any, record: Board) =>
        record.artist ? (
          <MultiLanguageDisplay languages={['ko']} value={record.artist.name} />
        ) : (
          '-'
        ),
    },
    {
      dataIndex: 'created_at',
      title: '생성일',
      width: 180,
      sorter: true,
      defaultSortOrder: 'descend' as SortOrder,
      render: (value: string) => (
        <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  return (
      <DataTable<Board>
        resource='boards'
        columns={columns}
        searchFields={[
          { value: 'name', label: '이름' },
          { value: 'board_id', label: 'ID' },
        ]}
        createSearchFilters={createSearchFilters}
      />
  );
} 