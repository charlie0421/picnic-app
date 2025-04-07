'use client';

import { List, useTable } from '@refinedev/antd';
import { Table, Button, Input, Space } from 'antd';
import { useMany, useNavigation } from '@refinedev/core';
import { useState } from 'react';
import { getImageUrl } from '@/lib/image';
import MultiLanguageDisplay from '@/components/common/MultiLanguageDisplay';
import TableImage from '@/components/common/TableImage';
import { SearchOutlined } from '@ant-design/icons';

export default function ArtistList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();

  const { tableProps, filters } = useTable({
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
    filters: {
      initial: [],
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

  // 아티스트 그룹 정보 가져오기
  const { data: groupsData, isLoading: groupsIsLoading } = useMany({
    resource: 'artist_group',
    ids:
      (tableProps?.dataSource
        ?.map((item: any) => {
          const groupId = item?.artist_group_id;
          return groupId ? String(groupId) : undefined;
        })
        .filter(Boolean) as string[]) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource?.length,
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <List>
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder='아티스트 이름 검색'
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
                show('artist', record.id);
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
              alt='아티스트 이미지'
              width={100}
              height={100}
            />
          )}
        />
        <Table.Column dataIndex='gender' title={'성별'} />
        <Table.Column
          dataIndex={'artist_group_id'}
          title={'그룹'}
          render={(value) =>
            groupsIsLoading ? (
              <>로딩 중...</>
            ) : (
              groupsData?.data?.find(
                (item) => Number(item.id) === Number(value),
              )?.name?.ko || '-'
            )
          }
        />
        <Table.Column
          dataIndex='birth_date'
          title={'생년월일'}
          render={(value: string) => value || '-'}
          sorter
        />
        <Table.Column
          dataIndex={['created_at']}
          title={'생성일'}
          render={(value: any) => value && new Date(value).toLocaleDateString()}
          sorter
        />
      </Table>
    </List>
  );
}
