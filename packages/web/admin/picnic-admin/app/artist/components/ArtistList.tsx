'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { useMany, useNavigation, useResource } from '@refinedev/core';
import { Table, Input, Space, Image } from 'antd';
import { useState, useEffect } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';
import { Artist } from '@/lib/types/artist';
import { genderOptions } from '@/lib/types/user_profiles';
import { supabaseBrowserClient } from '@/lib/supabase/client';

export default function ArtistList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';

  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [searchQuery, setSearchQuery] = useState<string>(urlSearch);
  const [searchResults, setSearchResults] = useState<Artist[]>([]);
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps, tableQueryResult } = useTable<Artist>({
    resource: 'artist',
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
      select: '*, group_id',
    },
  });

  // URL 파라미터 업데이트
  const updateUrlParams = (search: string) => {
    const params = new URLSearchParams(searchParams.toString());

    if (!search) {
      params.delete('search');
    } else {
      params.set('search', search);
    }

    router.push(`${pathname}?${params.toString()}`);
  };

  // 검색어 입력 시
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  // 검색 실행
  const handleSearch = async (value: string) => {
    const trimmedValue = value.trim();
    setSearchQuery(trimmedValue);
    updateUrlParams(trimmedValue);

    if (trimmedValue) {
      const { data, error } = await supabaseBrowserClient
        .from('artist')
        .select('*')
        .or(
          `name->>ko.ilike.%${trimmedValue}%,` +
            `name->>en.ilike.%${trimmedValue}%,` +
            `name->>ja.ilike.%${trimmedValue}%,` +
            `name->>zh.ilike.%${trimmedValue}%,` +
            `name->>id.ilike.%${trimmedValue}%`,
        )
        .order('created_at', { ascending: false });

      if (!error && data) {
        setSearchResults(data);
      }
    } else {
      tableQueryResult.refetch();
      setSearchResults([]);
    }
  };

  // URL 검색 파라미터가 변경될 때마다 검색어 상태 업데이트
  useEffect(() => {
    setSearchTerm(urlSearch);
    setSearchQuery(urlSearch);
    handleSearch(urlSearch);
  }, [urlSearch]);

  const finalTableProps = {
    ...tableProps,
    dataSource: searchQuery ? searchResults : tableProps.dataSource,
  };

  // 아티스트 그룹 정보 가져오기
  const { data: groupsData, isLoading: groupsIsLoading } = useMany({
    resource: 'artist_group',
    ids:
      (tableProps?.dataSource
        ?.map((item: Artist) => {
          const groupId = item?.group_id;
          return groupId ? String(groupId) : undefined;
        })
        .filter(Boolean) as string[]) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource?.length,
    },
  });

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resource?.meta?.list?.label}
    >
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder='아티스트 이름 검색'
          onSearch={handleSearch}
          value={searchTerm}
          onChange={handleSearchChange}
          style={{ width: 300, maxWidth: '100%' }}
          allowClear
        />
      </Space>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...finalTableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('artist', record.id),
          })}
          pagination={{
            ...finalTableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50', '100'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          size='small'
        >
          <Table.Column
            dataIndex='id'
            title='ID'
            align='center'
            sorter
            width={80}
          />

          <Table.Column
            dataIndex={['name']}
            title='이름'
            align='center'
            width={200}
            render={(value: Record<string, string>) => (
              <MultiLanguageDisplay languages={['ko']} value={value} />
            )}
          />

          <Table.Column
            dataIndex='image'
            title='이미지'
            align='center'
            width={120}
            responsive={['md']}
            render={(value: string) => (
              <Image
                src={getCdnImageUrl(value, 80)}
                alt='아티스트 이미지'
                width={80}
                height={80}
                preview={false}
              />
            )}
          />

          <Table.Column
            dataIndex='gender'
            title='성별'
            align='center'
            sorter
            width={100}
            responsive={['sm']}
            render={(value: string) => {
              const option = genderOptions.find((opt) => opt.value === value);
              return option ? option.label : value || '-';
            }}
          />

          <Table.Column
            dataIndex='group_id'
            title='그룹'
            align='center'
            sorter
            width={150}
            render={(value) => {
              if (groupsIsLoading) {
                return <>로딩 중...</>;
              }

              if (!value) {
                return <span>-</span>;
              }

              const group = groupsData?.data?.find(
                (item) => Number(item.id) === Number(value),
              );

              if (!group) {
                return <span>-</span>;
              }

              return (
                <Space
                  style={{ cursor: 'pointer' }}
                  onClick={(e) => {
                    e.stopPropagation();
                    show('artist_group', value);
                  }}
                >
                  {group.image && (
                    <Image
                      src={getCdnImageUrl(group.image, 40)}
                      alt='그룹 이미지'
                      width={40}
                      height={40}
                      preview={false}
                    />
                  )}
                  <span>{group.name?.ko || '-'}</span>
                </Space>
              );
            }}
          />

          <Table.Column
            dataIndex='birth_date'
            title='생년월일'
            align='center'
            sorter
            width={120}
            responsive={['lg']}
            render={(value: string) => value || '-'}
          />

          <Table.Column
            dataIndex='debut_date'
            title='데뷔일'
            align='center'
            sorter
            width={120}
            render={(value: string) => value || '-'}
          />

          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            sorter
            width={140}
            responsive={['lg']}
            render={(_, record: Artist) => (
              <Space direction='vertical' size='small'>
                <DateField value={record.created_at} format='YYYY-MM-DD' />
                <DateField value={record.updated_at} format='YYYY-MM-DD' />
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
}
