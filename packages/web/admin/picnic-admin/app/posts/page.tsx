'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { PostList } from './components';

export default function PostListPage() {
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

  // Refine useTable 훅 사용
  const { tableProps, sorters, setSorters, current, pageSize } =
    useTable({
      resource: 'posts',
      syncWithLocation: true,
      sorters: {
        initial: initialSorters,
        mode: 'server',
      },
      pagination: {
        mode: 'server',
        current: Number(searchParams.get('current')) || 1,
        pageSize: Number(searchParams.get('pageSize')) || 10,
      },
      // 검색 기능 활용
      meta: {
        search: searchTerm
          ? {
              query: searchTerm,
              fields: ['title'],
            }
          : undefined,
        idField: 'post_id',
        select: '*,user_profiles!posts_user_id_fkey(*)',
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

    // 페이지네이션 정보 업데이트
    if (tableProps.pagination && typeof tableProps.pagination !== 'boolean') {
      if (tableProps.pagination.current) {
        params.set('current', tableProps.pagination.current.toString());
      }

      if (tableProps.pagination.pageSize) {
        params.set('pageSize', tableProps.pagination.pageSize.toString());
      }
    }

    // 정렬 정보 업데이트
    if (sorters && sorters.length > 0) {
      params.set('sort', sorters[0].field as string);
      params.set('order', sorters[0].order as string);
    }

    // URL 변경
    const newUrl = `${pathname}?${params.toString()}`;
    router.replace(newUrl, { scroll: false });
  }, [
    searchTerm,
    tableProps.pagination,
    sorters,
    pathname,
    router,
    searchParams,
  ]);

  // 컴포넌트 마운트 시 URL에서 정렬 정보 가져오기
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
    <AuthorizePage resource='posts' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시글 목록'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='제목 검색'
            onSearch={handleSearch}
            defaultValue={searchTerm}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <PostList tableProps={tableProps} />
      </List>
    </AuthorizePage>
  );
}
