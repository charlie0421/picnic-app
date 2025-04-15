'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { BoardList } from './components';
import { Board } from '../../lib/types/board';

export default function BoardListPage() {
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

  const { resource } = useResource();
  const [form] = Form.useForm();

  // Refine useTable 훅 사용
  const { tableProps, tableQueryResult, sorters, setSorters, filters, setFilters } = useTable<Board>({
    resource: 'boards',
    syncWithLocation: true,
    sorters: {
      initial: initialSorters,
      mode: 'server',
    },
    filters: {
      mode: 'server',
      initial: searchTerm ? [
        {
          field: 'search',
          operator: 'contains',
          value: searchTerm
        }
      ] : undefined,
    },
    pagination: {
      pageSize: 10,
    },
    meta: {
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['name.ko', 'name.en', 'description'],
          }
        : undefined,
      idField: 'board_id',
      select: '*,artist(*)',
    },
    queryOptions: {
      refetchOnWindowFocus: false,
    },
    onSearch: (values: any) => {
      const searchValue = values.search || '';
      setSearchTerm(searchValue);
      return [
        {
          field: 'search',
          operator: 'contains',
          value: searchValue,
        }
      ];
    }
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

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
    setFilters([
      {
        field: 'search',
        operator: 'contains',
        value,
      },
    ]);
  };

  // 에러 처리
  if (tableQueryResult.error) {
    return (
      <Alert
        message="데이터 로딩 오류"
        description={tableQueryResult.error.message}
        type="error"
        showIcon
      />
    );
  }

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
            defaultValue={initialSearchTerm}
          />
        </Space>

        <BoardList tableProps={tableProps} />
      </List>
    </AuthorizePage>
  );
}
