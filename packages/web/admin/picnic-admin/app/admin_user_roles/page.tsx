'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
} from '@refinedev/antd';
import { useNavigation, useMany } from '@refinedev/core';
import { Table, Space, Tag } from 'antd';
import { AdminUserRole, AdminRole } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleUserList() {
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

  const { create } = useNavigation();

  return (
    <AuthorizePage resource='admin_user_roles' action='list'>
      <List
        createButtonProps={{
          onClick: () => create('admin_user_roles'),
        }}
      >
        <Table
          {...tableProps}
          rowKey='id'
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' />
          <Table.Column
            dataIndex='role_id'
            title='역할'
            render={(value) => {
              const role = rolesData?.data?.find((item) => item.id === value);
              return role ? <Tag color='blue'>{role.name}</Tag> : value;
            }}
          />
          <Table.Column
            dataIndex='user_id'
            title='사용자'
            render={(value) => {
              const user = usersData?.data?.find((item) => item.id === value);
              return user ? user.email || user.id : value;
            }}
          />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            sorter={true}
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
          <Table.Column
            title='작업'
            dataIndex='actions'
            render={(_, record: AdminUserRole) => (
              <Space size='middle'>
                <EditButton
                  resource='admin_user_roles'
                  hideText
                  size='small'
                  recordItemId={record.id}
                />
                <DeleteButton
                  resource='admin_user_roles'
                  hideText
                  size='small'
                  recordItemId={record.id}
                />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
