'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useMany, useResource } from '@refinedev/core';
import { Table, Space, Tag, Input } from 'antd';
import { useState } from 'react';
import { AdminUserRole, AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleUserList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<AdminUserRole>({
    resource: 'admin_user_roles',
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
      select: '*, role_id, user_id',
      search: searchTerm
        ? { query: searchTerm, fields: ['role_id', 'user_id'] }
        : undefined,
    },
  });

  // 역할 정보 가져오기
  const { data: rolesData } = useMany({
    resource: 'admin_roles',
    ids: tableProps?.dataSource?.map((item) => item.role_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  // 사용자 정보 가져오기
  const { data: usersData } = useMany({
    resource: 'user_profiles',
    ids: tableProps?.dataSource?.map((item) => item.user_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='admin_user_roles' action='list'>
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
            onClick: () => show('admin_user_roles', record.id),
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
            dataIndex='role_id'
            title='역할'
            align='center'
            sorter
            render={(value) => {
              const role = rolesData?.data?.find((item) => item.id === value);
              return role ? <Tag color='blue'>{role.name}</Tag> : value;
            }}
          />
          <Table.Column
            dataIndex='user_id'
            title='사용자'
            align='center'
            sorter
            render={(value) => {
              const user = usersData?.data?.find((item) => item.id === value);
              return user ? user.email || user.id : value;
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            sorter
            render={(_, record: AdminUserRole) => (
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
          <Table.Column
            title='작업'
            dataIndex='actions'
            align='center'
            render={(_, record: AdminUserRole) => (
              <Space size='middle'>
                <EditButton hideText size='small' recordItemId={record.id} />
                <DeleteButton hideText size='small' recordItemId={record.id} />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
