'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Space } from 'antd';
import { Config } from '@/lib/types/config';

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

  const { show } = useNavigation();

  return (
    <List 
      breadcrumb={false}
      headerButtons={<CreateButton />}
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
              onClick: () => show('config', record.id),
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
          <Table.Column
            dataIndex='id'
            title='ID'
            width={80}
          />
          <Table.Column 
            dataIndex='key' 
            title='키' 
            width={150} 
          />
          <Table.Column 
            dataIndex='value' 
            title='값' 
            ellipsis={{
              showTitle: true,
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            width={200}
            render={(_, record: any) => (
              <Space direction="vertical" size="small">
                <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
                <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
} 