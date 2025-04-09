'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Input, Space } from 'antd';
import { useMany, useNavigation, useResource } from '@refinedev/core';
import { useState } from 'react';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';
import { Image } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ArtistList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable({
    resource: 'artist',
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
    <AuthorizePage resource="artist" action="list">
      <List 
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder="아티스트 이름 검색"
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey="id"
          scroll={{ x: 'max-content' }}
          onRow={(record: any) => ({
            style: { cursor: 'pointer' },
            onClick: () => {
              if (record.id) {
                show('artist', record.id);
              }
            },
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex="id" title="ID" sorter />
          
          <Table.Column
            dataIndex={['name']}
            title="이름"
            align="center"
            render={(value: Record<string, string>) => (
              <MultiLanguageDisplay value={value} />
            )}
          />
          
          <Table.Column
            dataIndex="image"
            title="이미지"
            align="center"
            width={130}
            render={(value: string) => (
              <Image
                src={getCdnImageUrl(value, 100)}
                alt="아티스트 이미지"
                width={100}
                height={100}
                preview={false}
              />
            )}
          />
          
          <Table.Column dataIndex="gender" title="성별" align="center" />
          
          <Table.Column
            dataIndex="artist_group_id"
            title="그룹"
            align="center"
            render={(value) =>
              groupsIsLoading ? (
                <>로딩 중...</>
              ) : (
                <Space>
                  {groupsData?.data?.find(
                    (item) => Number(item.id) === Number(value),
                  )?.image && (
                    <Image
                      src={getCdnImageUrl(
                        groupsData?.data?.find(
                          (item) => Number(item.id) === Number(value),
                        )?.image,
                        50
                      )}
                      alt="그룹 이미지"
                      width={50}
                      height={50}
                      preview={false}
                    />
                  )}
                  <span>
                    {groupsData?.data?.find(
                      (item) => Number(item.id) === Number(value),
                    )?.name?.ko || '-'}
                  </span>
                </Space>
              )
            }
          />
          
          <Table.Column
            dataIndex="birth_date"
            title="생년월일"
            align="center"
            render={(value: string) => value || '-'}
            sorter
          />
          
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title="생성일/수정일"
            align="center"
            render={(_, record: any) => (
              <Space direction="vertical">
                <DateField value={record.created_at} format="YYYY-MM-DD HH:mm:ss" />
                <DateField value={record.updated_at} format="YYYY-MM-DD HH:mm:ss" />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
