'use client';

import {
  List,
  useTable,
  DateField,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { Table, Space } from 'antd';
import { AdminRole } from '@/lib/types/permission';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useNavigation } from '@refinedev/core';
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

  const { show } = useNavigation();

  return (
    <AuthorizePage resource='admin_roles' action='list'>
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
              onClick: () => show('admin_roles', record.id),
            };
          }}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' align='center' />
          <Table.Column dataIndex='name' title='역할 이름' align='center' />
          <Table.Column dataIndex='description' title='설명' align='center' />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            render={(_, record: any) => (
              <Space direction="vertical">
                <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
                <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
              </Space>
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
