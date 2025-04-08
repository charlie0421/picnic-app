'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useMany } from '@refinedev/core';
import { Table, Space, Tag } from 'antd';
import {
  AdminRolePermission,
  AdminRole,
  AdminPermission,
} from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RolePermissionList() {
  const { tableProps } = useTable<AdminRolePermission>({
    resource: 'admin_role_permissions',
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
      select: '*, role_id, permission_id',
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

  // 권한 정보 가져오기
  const { data: permissionsData } = useMany({
    resource: 'admin_permissions',
    ids: tableProps?.dataSource?.map((item) => item.permission_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  const { create, show } = useNavigation();

  return (
    <AuthorizePage resource='admin_role_permissions' action='list'>
      <List 
        breadcrumb={false}
        headerButtons={<CreateButton />}
      >
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => {
            return {
              style: {
                cursor: 'pointer',
              },
              onClick: () => show('admin_role_permissions', record.id),
            };
          }}
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
            dataIndex='permission_id'
            title='권한'
            render={(value) => {
              const permission = permissionsData?.data?.find(
                (item) => item.id === value,
              );
              return permission ? (
                <Tag color='green'>{`${permission.resource} - ${permission.action}`}</Tag>
              ) : (
                value
              );
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
            render={(_, record: AdminRolePermission) => (
              <Space size='middle'>
                <EditButton
                  resource='admin_role_permissions'
                  hideText
                  size='small'
                  recordItemId={record.id}
                />
                <DeleteButton
                  resource='admin_role_permissions'
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
