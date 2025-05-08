'use client';

import { List, useTable } from '@refinedev/antd';
import { Table, Space } from 'antd';
import { useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Version } from '@/lib/types/version';

export default function VersionList() {
  const { show } = useNavigation();

  const { tableProps } = useTable<Version>({
    resource: 'version',
    syncWithLocation: true,
    sorters: {
      initial: [{ field: 'id', order: 'desc' }],
    },
  });

  return (
    <AuthorizePage resource='version' action='list'>
      <List breadcrumb={false} title='버전 관리'>
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('version', record.id),
          })}
        >
          <Table.Column
            title='Android'
            dataIndex={['android', 'version']}
            render={(value, record) => (
              <Space direction='vertical' size='small'>
                <div>권장 업데이트: {value || '-'}</div>
                <div>강제 업데이트: {record.android?.force_version || '-'}</div>
              </Space>
            )}
          />
          <Table.Column
            title='iOS'
            dataIndex={['ios', 'version']}
            render={(value, record) => (
              <Space direction='vertical' size='small'>
                <div>권장 업데이트: {value || '-'}</div>
                <div>강제 업데이트: {record.ios?.force_version || '-'}</div>
              </Space>
            )}
          />
          <Table.Column
            title='Linux'
            dataIndex={['linux', 'version']}
            render={(value, record) => (
              <Space direction='vertical' size='small'>
                <div>권장 업데이트: {value || '-'}</div>
                <div>강제 업데이트: {record.linux?.force_version || '-'}</div>
              </Space>
            )}
          />
          <Table.Column
            title='macOS'
            dataIndex={['macos', 'version']}
            render={(value, record) => (
              <Space direction='vertical' size='small'>
                <div>권장 업데이트: {value || '-'}</div>
                <div>강제 업데이트: {record.macos?.force_version || '-'}</div>
              </Space>
            )}
          />
          <Table.Column
            title='Windows'
            dataIndex={['windows', 'version']}
            render={(value, record) => (
              <Space direction='vertical' size='small'>
                <div>권장 업데이트: {value || '-'}</div>
                <div>강제 업데이트: {record.windows?.force_version || '-'}</div>
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
