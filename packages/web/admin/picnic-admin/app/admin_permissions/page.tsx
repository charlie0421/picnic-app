'use client';

import { List, useTable, DateField, CreateButton } from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Table, Space, Tag, Input } from 'antd';
import { useState } from 'react';
import { AdminPermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function PermissionList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<AdminPermission>({
    resource: 'admin_permissions',
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
        ? { query: searchTerm, fields: ['resource', 'action', 'description'] }
        : undefined,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='admin_permissions' action='list'>
      <List
        breadcrumb={false}
        headerButtons={
          <>
            <Space>
              <Input.Search
                placeholder='검색...'
                onSearch={handleSearch}
                style={{ width: 200 }}
              />
              <CreateButton />
            </Space>
          </>
        }
        title={resource?.meta?.list?.label}
      >
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('admin_permissions', record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' sorter />
          <Table.Column
            dataIndex='resource'
            title='리소스'
            align='center'
            sorter
            render={(value) => <Tag color='blue'>{value}</Tag>}
          />
          <Table.Column
            dataIndex='action'
            title='액션'
            align='center'
            sorter
            render={(value) => {
              let color = 'green';
              if (value === 'delete') color = 'red';
              else if (value === 'update') color = 'orange';
              else if (value === 'create') color = 'blue';
              else if (value === '*') color = 'magenta';
              return <Tag color={color}>{value}</Tag>;
            }}
          />
          <Table.Column
            dataIndex='description'
            title='설명'
            align='center'
            sorter
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            render={(_, record: AdminPermission) => (
              <Space direction='vertical'>
                <DateField
                  value={record.created_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
                <DateField
                  value={record.updated_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
