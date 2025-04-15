'use client';

import React, { useState, useEffect } from 'react';
import { List, useTable, DateField, CreateButton } from '@refinedev/antd';
import { useNavigation, useResource, BaseKey } from '@refinedev/core';
import { Table, Space, Input, Select, Tag } from 'antd';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';

/**
 * 상태 필터를 포함한 리소스 리스트 템플릿 컴포넌트
 *
 * 이 컴포넌트는 URL 파라메터 저장 기능과 상태 필터링을 포함합니다:
 * 1. useSearchParams, usePathname, useRouter를 사용하여 URL 상태 관리
 * 2. 검색어와 상태 필터를 URL의 query 파라메터로 저장
 * 3. 페이지 이동 후 돌아왔을 때 이전 필터 상태 유지
 * 4. 정렬 상태를 URL에 저장하고 복원
 *
 * 사용 시 STATUS_OPTIONS과 STATUS_COLORS를 해당 리소스에 맞게 변경하세요.
 */

interface ResourceListProps {
  resource?: string;
}

// 상태 옵션 (실제 사용 시 수정 필요)
const STATUS = {
  ALL: 'all',
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PENDING: 'pending',
};

type StatusType = (typeof STATUS)[keyof typeof STATUS];

// 상태 옵션 목록 (실제 사용 시 수정 필요)
const STATUS_OPTIONS = [
  { label: '전체', value: STATUS.ALL },
  { label: '활성', value: STATUS.ACTIVE },
  { label: '비활성', value: STATUS.INACTIVE },
  { label: '대기중', value: STATUS.PENDING },
];

export function ResourceListWithStatusFilter({
  resource = 'resource_name',
}: ResourceListProps) {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  const urlStatus = searchParams.get('status') as StatusType;
  const initialStatus = Object.values(STATUS).includes(urlStatus as StatusType)
    ? urlStatus
    : STATUS.ALL;

  // URL에서 정렬 정보 가져오기
  const initialSortField = searchParams.get('sort');
  const initialSortOrder = searchParams.get('order') as 'asc' | 'desc';
  const initialSorters =
    initialSortField && initialSortOrder
      ? [{ field: initialSortField, order: initialSortOrder }]
      : [{ field: 'created_at', order: 'desc' as const }];

  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [statusFilter, setStatusFilter] = useState<StatusType>(initialStatus);
  const [filteredData, setFilteredData] = useState<any[]>([]);

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
    status?: StatusType;
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

    // 상태 필터 업데이트
    if (params.status !== undefined) {
      if (params.status === STATUS.ALL) {
        urlParams.delete('status');
      } else {
        urlParams.set('status', params.status);
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

  // 데이터가 로드된 후 필터링 적용
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      if (statusFilter === STATUS.ALL) {
        setFilteredData([...tableProps.dataSource]);
        return;
      }

      const filtered = tableProps.dataSource.filter((item) => {
        // 여기에 상태별 필터링 로직 구현 (예시)
        if (statusFilter === STATUS.ACTIVE) {
          return item.status === 'active';
        } else if (statusFilter === STATUS.INACTIVE) {
          return item.status === 'inactive';
        } else if (statusFilter === STATUS.PENDING) {
          return item.status === 'pending';
        }
        return true;
      });

      setFilteredData([...filtered]);
    }
  }, [tableProps.dataSource, statusFilter]);

  // 컴포넌트 마운트 시 URL에서 상태 복원
  useEffect(() => {
    if (urlSearch) {
      setSearchTerm(urlSearch);
    }

    if (urlStatus && Object.values(STATUS).includes(urlStatus as StatusType)) {
      setStatusFilter(urlStatus);
    }
  }, [urlSearch, urlStatus]);

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

  const handleStatusChange = (value: StatusType) => {
    const newStatus = value || STATUS.ALL;
    setStatusFilter(newStatus);
    updateUrlParams({ status: newStatus });
  };

  // 필터링된 데이터로 tableProps 수정
  const modifiedTableProps = {
    ...tableProps,
    dataSource: filteredData,
  };

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resourceInfo?.meta?.list?.label}
    >
      <Space style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 160, maxWidth: '100%' }}
          placeholder='상태'
          value={statusFilter}
          onChange={handleStatusChange}
          options={STATUS_OPTIONS}
        />
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
          {...modifiedTableProps}
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

          {/* 상태 컬럼 */}
          <Table.Column
            dataIndex='status'
            title='상태'
            width={100}
            render={(value) => {
              if (value === 'active') return <Tag color='green'>활성</Tag>;
              if (value === 'inactive') return <Tag color='red'>비활성</Tag>;
              if (value === 'pending') return <Tag color='blue'>대기중</Tag>;
              return value || '-';
            }}
          />

          {/* 중간 크기 이상 화면에서만 표시되는 컬럼 */}
          <Table.Column
            dataIndex='description'
            title='설명'
            responsive={['md']}
            ellipsis={{ showTitle: true }}
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
        </Table>
      </div>
    </List>
  );
}
