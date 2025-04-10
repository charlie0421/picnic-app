'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Table, Space, Input, Image } from 'antd';
import { useState } from 'react';
import dayjs from 'dayjs';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { ArtistGroup } from '@/lib/types/artist';

export default function ArtistGroupList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<ArtistGroup>({
    resource: 'artist_group',
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
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['name.ko', 'name.en', 'name.ja', 'name.zh'],
          }
        : undefined,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='artist_group' action='list'>
      <List
        breadcrumb={false}
        headerButtons={
          <>
            <Space>
              <Input.Search
                placeholder='아티스트 그룹 이름 검색'
                onSearch={handleSearch}
                style={{ width: 300 }}
                allowClear
              />
              <CreateButton />
            </Space>
          </>
        }
        title={resource?.meta?.list?.label}
      >
        <Table
          {...tableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('artist_group', record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' align='center' sorter />
          <Table.Column
            dataIndex={['name']}
            title='이름'
            align='center'
            sorter
            render={(value: Record<string, string>) => (
              <MultiLanguageDisplay value={value} />
            )}
          />
          <Table.Column
            dataIndex='image'
            title='이미지'
            align='center'
            width={130}
            render={(value: string | undefined) => {
              if (!value) return '-';
              return (
                <Image
                  src={getCdnImageUrl(value, 100)}
                  alt='아티스트 그룹 이미지'
                  width={100}
                  height={100}
                  preview={false}
                />
              );
            }}
          />
          <Table.Column
            dataIndex='debut_date'
            title='데뷔일'
            align='center'
            sorter
            render={(value) => {
              if (!value) return '-';
              return dayjs(value).format('YYYY년 MM월 DD일');
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            sorter
            render={(_, record: ArtistGroup) => (
              <Space direction='vertical'>
                <DateField
                  value={record.created_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
                <DateField
                  value={record.updated_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
