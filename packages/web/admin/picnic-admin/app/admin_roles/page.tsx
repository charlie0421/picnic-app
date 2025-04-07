'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Space } from 'antd';
import { AdminRole } from '@/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function RoleList() {
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
  });

  const { create } = useNavigation();

  return (
    <AuthorizePage resource='admin_roles' action='list'>
      <List
        createButtonProps={{
          onClick: () => create('admin_roles'),
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
          <Table.Column dataIndex='name' title='역할 이름' />
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
            render={(_, record: AdminRole) => (
              <Space size='middle'>
                <EditButton
                  resource='admin_roles'
                  hideText
                  size='small'
                  recordItemId={record.id}
                />
                <DeleteButton
                  resource='admin_roles'
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
