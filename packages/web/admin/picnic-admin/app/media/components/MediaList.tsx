'use client';

import {
  List,
  useTable,
  DateField,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Typography, Card, Space } from 'antd';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import { Image } from 'antd';

const { Link } = Typography;

export default function MediaList() {
  const { show } = useNavigation();

  const { tableProps } = useTable({
    resource: 'media',
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
      select: '*, created_at',
    },
  });

  return (
    <List>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => {
            return {
              style: {
                cursor: 'pointer'
              },
              onClick: () => {
                if (record.id) {
                  show('media', record.id);
                }
              },
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
          <Table.Column dataIndex='id' title={'ID'} width={80} />
          <Table.Column
            dataIndex='title'
            title={'제목'}
            align='center'
            ellipsis={{ showTitle: true }}
            render={(value) => <MultiLanguageDisplay languages={['ko']} value={value} />}
          />
          <Table.Column
            dataIndex='video_id'
            title={'비디오 ID'}
            align='center'
            responsive={['md']}
            render={(value) => value || '-'}
          />
          <Table.Column
            dataIndex='video_url'
            title={'비디오 URL'}
            align='center'
            responsive={['md']}
            render={(value) => value || '-'}
          />
          <Table.Column
            dataIndex='created_at'
            title={'생성일'}
            align='center'
            width={120}
            responsive={['lg']}
            render={(value) => <DateField value={value} format='YYYY-MM-DD' />}
          />
        </Table>
      </div>
    </List>
  );
} 