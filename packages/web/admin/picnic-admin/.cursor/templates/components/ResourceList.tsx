'use client';

import React, { useState, useEffect } from 'react';
import { List, useTable, DateField, CreateButton } from '@refinedev/antd';
import { useNavigation, useResource, BaseKey } from '@refinedev/core';
import { Table, Space, Input } from 'antd';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';

/**
 * 리소스 리스트 템플릿 컴포넌트
 *
 * 이 컴포넌트는 URL 파라메터 저장 기능을 포함합니다:
 * 1. useSearchParams, usePathname, useRouter를 사용하여 URL 상태 관리
 * 2. 검색어를 URL의 query 파라메터로 저장
 * 3. 페이지 이동 후 돌아왔을 때 이전 검색 상태 유지
 * 4. 정렬 상태를 URL에 저장하고 복원
 *
 * 다른 필터링 기능이 필요한 경우 비슷한 방식으로 구현할 수 있습니다:
 * 1. 필터 상태를 useState로 정의
 * 2. 초기값을 URL에서 가져옴
 * 3. 값이 변경될 때 URL 업데이트
 * 4. URL 변경 시 상태 업데이트
 */
interface ResourceListProps {
  resource?: string;
}

export function ResourceList({
  resource = 'resource_name',
}: ResourceListProps) {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);

  // URL에서 정렬 정보 가져오기
  const initialSortField = searchParams.get('sort');
  const initialSortOrder = searchParams.get('order') as 'asc' | 'desc';
  const initialSorters =
    initialSortField && initialSortOrder
      ? [{ field: initialSortField, order: initialSortOrder }]
      : [{ field: 'created_at', order: 'desc' as const }];

  const { show } = useNavigation();
  const { resource: resourceInfo } = useResource();

  const { tableProps, sorters, setSorters } = useTable({
    resource,
    syncWithLocation: true,
    sorters: {
      initial: initialSorters,
      mode: 'server',
    },
    meta: {
      search: searchTerm
        ? { query: searchTerm, fields: ['name', 'title'] }
        : undefined,
    },
  });

  // URL 파라미터 업데이트
  const updateUrlParams = (params: {
    search?: string;
    sort?: string;
    order?: string;
  }) => {
    const urlParams = new URLSearchParams(searchParams.toString());

    // 검색어 업데이트
    if (params.search !== undefined) {
      if (!params.search) {
        urlParams.delete('search');
      } else {
        urlParams.set('search', params.search);
      }
    }

    // 정렬 필드 업데이트
    if (params.sort !== undefined) {
      if (!params.sort) {
        urlParams.delete('sort');
      } else {
        urlParams.set('sort', params.sort);
      }
    }

    // 정렬 순서 업데이트
    if (params.order !== undefined) {
      if (!params.order) {
        urlParams.delete('order');
      } else {
        urlParams.set('order', params.order);
      }
    }

    router.push(`${pathname}?${urlParams.toString()}`, {
      scroll: false,
    });
  };

  // 컴포넌트 마운트 시 URL에서 검색어 복원
  useEffect(() => {
    if (urlSearch) {
      setSearchTerm(urlSearch);
    }
  }, [urlSearch]);

  // 정렬 상태가 변경될 때 URL 업데이트
  useEffect(() => {
    if (sorters && sorters.length > 0) {
      updateUrlParams({
        sort: sorters[0].field as string,
        order: sorters[0].order as string,
      });
    }
  }, [sorters]);

  // URL에서 정렬 정보 가져와서 상태 업데이트
  useEffect(() => {
    const sortField = searchParams.get('sort');
    const sortOrder = searchParams.get('order');

    if (sortField && sortOrder) {
      setSorters([{ field: sortField, order: sortOrder as 'asc' | 'desc' }]);
    }
  }, [searchParams, setSorters]);

  const handleSearch = (value: string) => {
    setSearchTerm(value);
    updateUrlParams({ search: value });
  };

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resourceInfo?.meta?.list?.label}
    >
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder='검색어를 입력하세요'
          onSearch={handleSearch}
          defaultValue={searchTerm}
          style={{ width: 300, maxWidth: '100%' }}
          allowClear
        />
      </Space>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => {
              if (record.id) {
                show(resource, record.id);
              }
            },
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          scroll={{ x: 'max-content' }}
          size='small'
        >
          {/* 항상 표시되는 주요 컬럼 */}
          <Table.Column dataIndex='id' title='ID' width={80} />
          <Table.Column
            dataIndex='title'
            title='제목'
            ellipsis={{ showTitle: true }}
            render={(value) => value || '-'}
          />

          {/* 중간 크기 이상 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex='description'
            title='설명'
            responsive={['md']}
            ellipsis={{ showTitle: true }}
            render={(value) => value || '-'}
          />

          {/* 작은 크기 이상 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex='status'
            title='상태'
            responsive={['sm']}
            width={100}
            render={(value) => value || '-'}
          />

          {/* 큰 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            responsive={['lg']}
            width={120}
            render={(value) => <DateField value={value} format='YYYY-MM-DD' />}
          />

          {/* 초대형 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex='updated_at'
            title='수정일'
            responsive={['xl']}
            width={120}
            render={(value) => <DateField value={value} format='YYYY-MM-DD' />}
          />
        </Table>
      </div>
    </List>
  );
}
