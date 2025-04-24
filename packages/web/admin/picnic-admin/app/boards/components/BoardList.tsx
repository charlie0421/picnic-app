import React from 'react';
import { Space, Tag } from 'antd';
import { useNavigation, useDelete, CrudFilters } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField } from '@refinedev/antd';
import { Board } from '@/lib/types/board';
import { DataTable } from '../../components/common/DataTable';
import { MultiLanguageDisplay } from '@/components/ui';

export const BoardList: React.FC = () => {
  const { show } = useNavigation();

  const createSearchFilters = (value: string, field: string): CrudFilters => {
    if (!value) return [];

    if (field === 'all') {
      return [
        {
          field: 'name->>ko',
          operator: 'contains',
          value,
        },
      ];
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
      dataIndex: 'board_id',
      key: 'board_id',
      width: 80,
      sorter: true,
    },
    {
      title: '이름',
      dataIndex: 'name',
      key: 'name',
      sorter: true,
      render: (value: any) => <MultiLanguageDisplay value={value} />,
    },
    {
      title: '상태',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      sorter: true,
      render: (value: string) => {
        let color = 'default';
        if (value === 'ACTIVE') color = 'green';
        if (value === 'PENDING') color = 'orange';
        if (value === 'REJECTED') color = 'red';
        
        return <Tag color={color}>{value}</Tag>;
      },
    },
    {
      title: '공식',
      dataIndex: 'is_official',
      key: 'is_official',
      width: 80,
      render: (value: boolean) => (
        <Tag color={value ? 'blue' : 'default'}>
          {value ? '공식' : '비공식'}
        </Tag>
      ),
    },
    {
      title: '아티스트',
      key: 'artist',
      width: 120,
      render: (_: any, record: Board) => (
        record.artist ? <MultiLanguageDisplay value={record.artist.name} /> : '-'
      ),
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
      render: (_: any, record: Board) => (
        <Space>
          <ShowButton size="small" recordItemId={record.board_id} />
          <EditButton size="small" recordItemId={record.board_id} />
          <DeleteButton
            size="small"
            recordItemId={record.board_id}
            resource="boards"
          />
        </Space>
      ),
    },
  ];

  return (
    <DataTable<Board>
      resource='boards'
      columns={columns}
      searchFields={[
        { value: 'name', label: '이름' },
        { value: 'description', label: '설명' },
      ]}
      createSearchFilters={createSearchFilters}
      onRow={(record) => ({
        onClick: () => show('boards', record.board_id),
        style: { cursor: 'pointer' }
      })}
    />
  );
}; 