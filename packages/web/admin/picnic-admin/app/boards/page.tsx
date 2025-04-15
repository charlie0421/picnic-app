'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Tooltip } from 'antd';
import { useNavigation } from '@refinedev/core';
import { useState } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { Board } from './components/types';
import { MultiLanguageDisplay } from '@/components/ui';

export default function BoardList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  // Refine useTable 훅 사용
  const { tableProps } = useTable({
    resource: 'boards',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    meta: {
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['name.ko', 'name.en', 'description'],
          }
        : undefined,
      idField: 'board_id',
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='boards' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시판 목록'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='게시판 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey='board_id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('boards', record.board_id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column
            dataIndex='board_id'
            title='ID'
            width={100}
            ellipsis={true}
          />
          <Table.Column
            dataIndex='name'
            title='이름'
            sorter
            render={(value) => <MultiLanguageDisplay value={value} />}
          />
          <Table.Column
            dataIndex='description'
            title='설명'
            ellipsis={{
              showTitle: true,
            }}
          />
          <Table.Column
            dataIndex='status'
            title='상태'
            width={120}
            render={(value: string) => (
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
            )}
          />
          <Table.Column
            dataIndex='is_official'
            title='공식 게시판'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'blue' : 'default'}>
                {value ? '공식' : '비공식'}
              </Tag>
            )}
          />
          <Table.Column dataIndex='artist_id' title='아티스트 ID' width={120} />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            width={180}
            sorter
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
