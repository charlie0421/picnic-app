'use client';

import { List, useTable } from '@refinedev/antd';
import { Table, Space, Input } from 'antd';
import { useState } from 'react';
import dayjs from 'dayjs';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import TableImage from '@/components/ui/TableImage';
import { useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ArtistGroupList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();

  const { tableProps } = useTable({
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
    meta: {
      // Refine의 meta를 통해 검색어를 백엔드로 전달
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['name.ko', 'name.en', 'name.ja', 'name.zh'],
          }
        : undefined,
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='artist_group' action='list'>
      <List>
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='아티스트 그룹 이름 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          onRow={(record: any) => {
            return {
              style: {
                cursor: 'pointer',
              },
              onClick: () => {
                if (record.id) {
                  show('artist_group', record.id);
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
        >
          <Table.Column dataIndex='id' title={'ID'} sorter />
          <Table.Column
            dataIndex={['name']}
            title={'이름'}
            render={(value: Record<string, string>) => (
              <MultiLanguageDisplay value={value} />
            )}
          />
          <Table.Column
            dataIndex='image'
            title={'이미지'}
            width={130}
            render={(value: string) => (
              <TableImage
                src={value}
                alt='아티스트 그룹 이미지'
                width={100}
                height={100}
              />
            )}
          />
          <Table.Column
            title={'데뷔일'}
            render={(_, record: any) => {
              if (!record.debut_date) return '-';
              return dayjs(record.debut_date).format('YYYY년 MM월 DD일');
            }}
            sorter
          />
          <Table.Column
            dataIndex={['created_at']}
            title={'생성일'}
            render={(value: any) =>
              value && new Date(value).toLocaleDateString()
            }
            sorter
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
