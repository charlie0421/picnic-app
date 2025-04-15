'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Tooltip } from 'antd';
import { useNavigation } from '@refinedev/core';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { Board } from './components/types';
import { MultiLanguageDisplay } from '@/components/ui';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';

export default function BoardList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 검색어 가져오기
  const initialSearchTerm = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState<string>(initialSearchTerm);

  // URL에서 정렬 정보 가져오기
  const initialSortField = searchParams.get('sort');
  const initialSortOrder = searchParams.get('order') as 'asc' | 'desc';
  const initialSorters =
    initialSortField && initialSortOrder
      ? [{ field: initialSortField, order: initialSortOrder }]
      : [{ field: 'created_at', order: 'desc' as const }];

  const { show } = useNavigation();
  const { resource } = useResource();

  // Refine useTable 훅 사용
  const { tableProps, sorters, setSorters } = useTable({
    resource: 'boards',
    syncWithLocation: true,
    sorters: {
      initial: initialSorters,
      mode: 'server',
    },
    meta: {
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['name.ko', 'name.en', 'description'],
          }
        : undefined,
      idField: 'board_id',
    },
  });

  // URL 파라미터 업데이트
  useEffect(() => {
    // 현재 URL 파라미터 가져오기
    const params = new URLSearchParams(searchParams.toString());

    // 검색어 업데이트
    if (searchTerm) {
      params.set('search', searchTerm);
    } else {
      params.delete('search');
    }

    // 정렬 정보 업데이트
    if (sorters && sorters.length > 0) {
      params.set('sort', sorters[0].field as string);
      params.set('order', sorters[0].order as string);
    }

    // URL 변경
    const newUrl = `${pathname}?${params.toString()}`;
    router.replace(newUrl, { scroll: false });
  }, [searchTerm, sorters, pathname, router, searchParams]);

  // URL에서 정렬 정보 가져오기
  useEffect(() => {
    const sortField = searchParams.get('sort');
    const sortOrder = searchParams.get('order');

    if (sortField && sortOrder) {
      setSorters([{ field: sortField, order: sortOrder as 'asc' | 'desc' }]);
    }
  }, [searchParams, setSorters]);

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='boards' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시판 목록'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='게시판 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey='board_id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('boards', record.board_id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column
            dataIndex='board_id'
            title='ID'
            width={100}
            ellipsis={true}
          />
          <Table.Column
            dataIndex='name'
            title='이름'
            sorter
            render={(value) => <MultiLanguageDisplay value={value} />}
          />
          <Table.Column
            dataIndex='description'
            title='설명'
            ellipsis={{
              showTitle: true,
            }}
          />
          <Table.Column
            dataIndex='status'
            title='상태'
            width={120}
            render={(value: string) => (
              <Tag
                color={
                  value === 'ACTIVE'
                    ? 'green'
                    : value === 'PENDING'
                    ? 'orange'
                    : value === 'REJECTED'
                    ? 'red'
                    : 'default'
                }
              >
                {value}
              </Tag>
            )}
          />
          <Table.Column
            dataIndex='is_official'
            title='공식 게시판'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'blue' : 'default'}>
                {value ? '공식' : '비공식'}
              </Tag>
            )}
          />
          <Table.Column dataIndex='artist_id' title='아티스트 ID' width={120} />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            width={180}
            sorter
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
