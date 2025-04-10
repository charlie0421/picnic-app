'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Table, Space, Input } from 'antd';
import { useState } from 'react';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<AdminRole>({
    resource: 'admin_roles',
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
        ? { query: searchTerm, fields: ['name', 'description'] }
        : undefined,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='admin_roles' action='list'>
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
            onClick: () => show('admin_roles', record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' align='center' sorter />
          <Table.Column
            dataIndex='name'
            title='역할 이름'
            align='center'
            sorter
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
            sorter
            render={(_, record: AdminRole) => (
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
