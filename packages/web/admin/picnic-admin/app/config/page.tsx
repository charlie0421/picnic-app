'use client';

import {
  List,
  useTable,
  DateField,
  ShowButton,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Space } from 'antd';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ConfigList() {
  const { tableProps } = useTable<Config>({
    resource: 'config',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'key',
          order: 'asc',
        },
      ],
    },
    meta: {
      select: 'id, key, value, created_at, updated_at',
    },
  });

  const { create, show } = useNavigation();

  return (
    <AuthorizePage resource='config' action='list'>
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
              onClick: () => show('config', record.id),
            };
          }}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column
            dataIndex='id'
            title='ID'
          />
          <Table.Column dataIndex='key' title='키' width={200} />
          <Table.Column dataIndex='value' title='값' />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            render={(_, record: any) => (
              <Space direction="vertical">
                <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
                <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
