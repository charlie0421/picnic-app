'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useMany, useResource } from '@refinedev/core';
import { Table, Space, Tag, Input } from 'antd';
import { useState } from 'react';
import {
  AdminRolePermission,
  AdminRole,
  AdminPermission,
} from '@/lib/types/permission';

export default function RolePermissionList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

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
      search: searchTerm
        ? { query: searchTerm, fields: ['role_id', 'permission_id'] }
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

  // 권한 정보 가져오기
  const { data: permissionsData } = useMany({
    resource: 'admin_permissions',
    ids: tableProps?.dataSource?.map((item) => item.permission_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <List
      breadcrumb={false}
      headerButtons={
        <>
          <Space>
            <Input.Search
              placeholder='검색...'
              onSearch={handleSearch}
              style={{ width: 200, maxWidth: '100%' }}
              allowClear
            />
            <CreateButton />
          </Space>
        </>
      }
      title={resource?.meta?.list?.label}
    >
      <div style={{ width: '100%', overflowX: 'auto' }}>
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
          scroll={{ x: 'max-content' }}
          size="small"
        >
          <Table.Column dataIndex='id' title='ID' sorter width={80} />
          <Table.Column
            dataIndex='role_id'
            title='역할'
            align='center'
            sorter
            width={140}
            ellipsis={{ showTitle: true }}
            render={(value) => {
              const role = rolesData?.data?.find((item) => item.id === value);
              return role ? <Tag color='blue'>{role.name}</Tag> : value;
            }}
          />
          <Table.Column
            dataIndex='permission_id'
            title='권한'
            align='center'
            sorter
            ellipsis={{ showTitle: true }}
            width={180}
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
            align='center'
            sorter
            width={120}
            responsive={['md']}
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD' />
            )}
          />
        </Table>
      </div>
    </List>
  );
} 