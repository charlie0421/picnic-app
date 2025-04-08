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
        createButtonProps={{
          onClick: () => create('config'),
          children: '설정 추가',
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
          <Table.Column
            dataIndex='id'
            title='ID'
            render={(value) => value?.substring(0, 8)}
          />
          <Table.Column dataIndex='key' title='키' />
          <Table.Column dataIndex='value' title='값' />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            sorter={true}
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
          <Table.Column
            dataIndex='updated_at'
            title='수정일'
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
          <Table.Column
            title='작업'
            dataIndex='actions'
            render={(_, record: Config) => (
              <Space size='middle'>
                <ShowButton
                  hideText
                  size='small'
                  recordItemId={record.id}
                  resource='config'
                />
                <EditButton
                  hideText
                  size='small'
                  recordItemId={record.id}
                  resource='config'
                />
                <DeleteButton
                  hideText
                  size='small'
                  recordItemId={record.id}
                  resource='config'
                />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
