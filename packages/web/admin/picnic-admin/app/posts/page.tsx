'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Tooltip } from 'antd';
import { useNavigation, BaseRecord } from '@refinedev/core';
import { useState } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { Post } from './components/types';

export default function PostList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  // Refine useTable 훅 사용
  const { tableProps } = useTable({
    resource: 'posts',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    // 검색 기능 활용
    meta: {
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['title'],
          }
        : undefined,
      idField: 'post_id',
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='posts' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시글 목록'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='제목 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey='post_id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('posts', record.post_id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column
            dataIndex='post_id'
            title='ID'
            width={100}
            ellipsis={true}
          />
          <Table.Column dataIndex='title' title='제목' sorter />
          <Table.Column
            dataIndex='user_id'
            title='작성자'
            width={150}
            ellipsis={true}
          />
          <Table.Column
            dataIndex='view_count'
            title='조회수'
            width={100}
            sorter
          />
          <Table.Column
            dataIndex='reply_count'
            title='댓글수'
            width={100}
            sorter
          />
          <Table.Column
            dataIndex='is_anonymous'
            title='익명 여부'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'blue' : 'default'}>
                {value ? '익명' : '실명'}
              </Tag>
            )}
          />
          <Table.Column
            dataIndex='is_hidden'
            title='숨김 여부'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'red' : 'green'}>
                {value ? '숨김' : '표시'}
              </Tag>
            )}
          />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            width={200}
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
