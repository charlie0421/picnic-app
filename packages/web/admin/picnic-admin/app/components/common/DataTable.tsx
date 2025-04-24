import { useCallback, useRef, useState, useEffect } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { useTable } from '@refinedev/antd';
import { CrudFilters, BaseRecord, useNavigation } from '@refinedev/core';
import { Table, Space, Input, Select, message } from 'antd';
import { TableProps } from 'antd/lib/table';

export interface SearchField {
  value: string;
  label: string;
}

interface DataTableProps<T extends BaseRecord> {
  resource: string;
  columns: TableProps<T>['columns'];
  searchFields?: SearchField[];
  createSearchFilters?: (value: string, field: string) => CrudFilters;
  onRow?: (record: T) => {
    onClick?: () => void;
    style?: React.CSSProperties;
  };
  sorters?: {
    initial?: {
      field: string;
      order: 'asc' | 'desc';
    }[];
  };
  meta?: {
    select?: string;
    head?: boolean;
    count?: 'exact' | 'planned' | 'estimated';
    order?: Array<{
      foreignTable: string;
      column: string;
      direction: 'asc' | 'desc';
    }>;
  };
}

export function DataTable<T extends BaseRecord>({
  resource,
  columns,
  searchFields,
  createSearchFilters,
  onRow,
  sorters,
  meta,
}: DataTableProps<T>) {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const { show } = useNavigation();

  // URL에서 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  const urlField = searchParams.get('field') || 'all';

  // URL에서 페이지네이션 및 정렬 정보 가져오기
  const urlCurrent = searchParams.get('current')
    ? Number(searchParams.get('current'))
    : 1;
  const urlPageSize = searchParams.get('pageSize')
    ? Number(searchParams.get('pageSize'))
    : 10;
  const urlSortField =
    searchParams.get('sorters[0][field]') || searchParams.get('sort');
  const urlSortOrder = (searchParams.get('sorters[0][order]') ||
    searchParams.get('order')) as 'asc' | 'desc';
  const initialSorters =
    urlSortField && urlSortOrder
      ? [{ field: urlSortField, order: urlSortOrder }]
      : undefined;

  // 초기 마운트 여부를 추적하는 ref
  const initialMountRef = useRef(true);

  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [localSearchTerm, setLocalSearchTerm] = useState<string>(urlSearch);
  const [searchField, setSearchField] = useState<string>(urlField);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  // Refine useTable 훅 사용
  const { tableProps, setFilters } = useTable<T>({
    resource,
    syncWithLocation: true,
    sorters: sorters || {
      initial: initialSorters,
      mode: 'server',
    },
    pagination: {
      mode: 'server',
      current: urlCurrent,
      pageSize: urlPageSize,
    },
    filters: {
      mode: 'server',
      initial: createSearchFilters
        ? createSearchFilters(urlSearch, urlField)
        : [],
    },
    meta: meta || {
      select: '*',
    },
  });

  // 검색어 입력 핸들러 - 로컬 상태만 업데이트
  const handleSearchInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      setLocalSearchTerm(value);
    },
    [],
  );

  // 검색 실행 함수
  const executeSearch = useCallback(
    (value: string) => {
      if (!createSearchFilters) return;

      setIsSearching(true);
      setSearchTerm(value);

      const filters = createSearchFilters(value, searchField);

      // 검색 시 페이지네이션 상태도 함께 초기화
      if (tableProps.onChange && tableProps.pagination) {
        const newPagination = {
          ...tableProps.pagination,
          current: 1,
        };

        tableProps.onChange(
          newPagination,
          {},
          {},
          { currentDataSource: [], action: 'paginate' },
        );
      }

      setFilters(filters, 'replace');

      // URL 파라미터 업데이트
      const params = new URLSearchParams();

      if (value) {
        params.set('search', value);
      }

      if (searchField !== 'all') {
        params.set('field', searchField);
      }

      // 페이지 크기만 유지
      if (tableProps.pagination && typeof tableProps.pagination === 'object') {
        const pageSize = tableProps.pagination.pageSize || 10;
        if (pageSize !== 10) {
          params.set('pageSize', pageSize.toString());
        }
      }

      router.push(`${pathname}?${params.toString()}`, { scroll: false });
      setIsSearching(false);
    },
    [
      searchField,
      setFilters,
      createSearchFilters,
      pathname,
      router,
      tableProps,
    ],
  );

  // 검색 버튼 클릭 핸들러
  const handleSearch = useCallback(
    (value: string) => {
      executeSearch(value);
    },
    [executeSearch],
  );

  // 필드 변경 핸들러
  const handleFieldChange = useCallback(
    (value: string) => {
      setSearchField(value);
      if (searchTerm) {
        executeSearch(searchTerm);
      }
    },
    [searchTerm, executeSearch],
  );

  // 컴포넌트 마운트 시 초기화
  useEffect(() => {
    if (initialMountRef.current) {
      initialMountRef.current = false;

      if (urlSearch && createSearchFilters) {
        setSearchTerm(urlSearch);
        setLocalSearchTerm(urlSearch);
        const initialFilters = createSearchFilters(urlSearch, urlField);
        setFilters(initialFilters, 'replace');
      }
    }
  }, [urlSearch, urlField, setFilters, createSearchFilters]);

  // 테이블 변경 핸들러
  const handleTableChange = (
    pagination: any,
    filters: any,
    sorter: any,
    extra: any,
  ) => {
    // 정렬 변경 시 페이지를 1로 설정
    const newPagination =
      extra.action === 'sort' ? { ...pagination, current: 1 } : pagination;

    if (tableProps.onChange) {
      tableProps.onChange(newPagination, filters, sorter, extra);
    }

    const params = new URLSearchParams(searchParams.toString());

    // 페이지네이션 정보 업데이트
    if (newPagination.current !== 1) {
      params.set('current', newPagination.current.toString());
    } else {
      params.delete('current');
    }

    if (newPagination.pageSize !== 10) {
      params.set('pageSize', newPagination.pageSize.toString());
    } else {
      params.delete('pageSize');
    }

    // 정렬 정보 업데이트
    if (sorter.field && sorter.order) {
      params.set('sorters[0][field]', sorter.field);
      params.set('sorters[0][order]', sorter.order);
    } else {
      params.delete('sorters[0][field]');
      params.delete('sorters[0][order]');
    }

    // 검색 파라미터 유지
    if (searchTerm) {
      params.set('search', searchTerm);
    }
    if (searchField !== 'all') {
      params.set('field', searchField);
    }

    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  };

  const defaultOnRow = useCallback(
    (record: T) => ({
      onClick: () => record.id && show(resource, record.id),
      style: { cursor: 'pointer' },
    }),
    [resource, show],
  );

  return (
    <>
      {searchFields && (
        <Space style={{ marginBottom: 16 }}>
          <Select
            value={searchField}
            style={{ width: 120, maxWidth: '100%' }}
            onChange={handleFieldChange}
            options={[{ value: 'all', label: '전체' }, ...searchFields]}
          />
          <Input.Search
            placeholder='검색어를 입력하세요'
            onSearch={handleSearch}
            style={{ width: 300, maxWidth: '100%' }}
            allowClear
            value={localSearchTerm}
            onChange={handleSearchInputChange}
          />
        </Space>
      )}

      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          columns={columns}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          size='small'
          onChange={handleTableChange}
          onRow={onRow || defaultOnRow}
        />
      </div>
    </>
  );
}
