'use client';

import {
  List,
  useTable,
  DateField,
  ShowButton,
  EditButton,
  DeleteButton,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Space, Tag } from 'antd';
import { AdminPermission } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function PermissionList() {
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
  });

  const { create } = useNavigation();

  return (
    <AuthorizePage resource='admin_permissions' action='list'>
      <List
        createButtonProps={{
          onClick: () => create('admin_permissions'),
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
            dataIndex='resource'
            title='리소스'
            render={(value) => <Tag color='blue'>{value}</Tag>}
          />
          <Table.Column
            dataIndex='action'
            title='액션'
            render={(value) => {
              let color = 'green';
              if (value === 'delete') color = 'red';
              else if (value === 'update') color = 'orange';
              else if (value === 'create') color = 'blue';
              else if (value === '*') color = 'magenta';
              return <Tag color={color}>{value}</Tag>;
            }}
          />
          <Table.Column dataIndex='description' title='설명' />
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
            render={(_, record: AdminPermission) => (
              <Space size='middle'>
                <EditButton
                  resource='admin_permissions'
                  hideText
                  size='small'
                  recordItemId={record.id}
                />
                <DeleteButton
                  resource='admin_permissions'
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
