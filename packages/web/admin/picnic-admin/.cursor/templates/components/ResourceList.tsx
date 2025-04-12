'use client';

import React, { useState } from 'react';
import { List, useTable, DateField, CreateButton } from '@refinedev/antd';
import { useNavigation, useResource, BaseKey } from '@refinedev/core';
import { Table, Space, Input } from 'antd';

interface ResourceListProps {
  resource?: string;
}

export function ResourceList({ resource = 'resource_name' }: ResourceListProps) {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource: resourceInfo } = useResource();

  const { tableProps } = useTable({
    resource,
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
        ? { query: searchTerm, fields: ['name', 'title'] }
        : undefined,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <List
      breadcrumb={false}
      headerButtons={
        <Space>
          <Input.Search
            placeholder="검색어를 입력하세요"
            onSearch={handleSearch}
            style={{ width: 300, maxWidth: '100%' }}
            allowClear
          />
          <CreateButton />
        </Space>
      }
      title={resourceInfo?.meta?.list?.label}
    >
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey="id"
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => {
              if (record.id) {
                show(resource, record.id);
              }
            },
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          scroll={{ x: 'max-content' }}
          size="small"
        >
          {/* 항상 표시되는 주요 컬럼 */}
          <Table.Column dataIndex="id" title="ID" width={80} />
          <Table.Column
            dataIndex="title"
            title="제목"
            ellipsis={{ showTitle: true }}
            render={(value) => value || '-'}
          />
          
          {/* 중간 크기 이상 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex="description"
            title="설명"
            responsive={['md']}
            ellipsis={{ showTitle: true }}
            render={(value) => value || '-'}
          />
          
          {/* 작은 크기 이상 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex="status"
            title="상태"
            responsive={['sm']}
            width={100}
            render={(value) => value || '-'}
          />
          
          {/* 큰 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex="created_at"
            title="생성일"
            responsive={['lg']}
            width={120}
            render={(value) => <DateField value={value} format="YYYY-MM-DD" />}
          />
          
          {/* 초대형 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex="updated_at"
            title="수정일"
            responsive={['xl']}
            width={120}
            render={(value) => <DateField value={value} format="YYYY-MM-DD" />}
          />
        </Table>
      </div>
    </List>
  );
} 