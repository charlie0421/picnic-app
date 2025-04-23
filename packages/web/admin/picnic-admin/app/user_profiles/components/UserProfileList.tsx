'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import {
  Table,
  Space,
  Input,
  Tag,
  Avatar,
  Switch,
  Select,
  message,
} from 'antd';
import { useNavigation, CrudFilters } from '@refinedev/core';
import { useState, useEffect, useCallback, useRef } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { UserProfile } from '../../../lib/types/user_profiles';

// UUID 유효성 검사 정규식
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface UserProfileListProps {
  resource?: string;
}

export function UserProfileList({
  resource = 'user_profiles',
}: UserProfileListProps) {
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
      : [{ field: 'created_at', order: 'desc' as const }];

  // 초기 마운트 여부를 추적하는 ref
  const initialMountRef = useRef(true);

  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [localSearchTerm, setLocalSearchTerm] = useState<string>(urlSearch);
  const [searchField, setSearchField] = useState<string>(urlField);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  // 검색 필터 생성 함수
  const createSearchFilters = useCallback(
    (value: string, field: string): CrudFilters => {
      const filters: CrudFilters = [];

      if (!value) return [];

      if (field === 'all') {
        return [
          {
            operator: 'or',
            value: [
              {
                field: 'nickname',
                operator: 'contains',
                value,
              },
              {
                field: 'email',
                operator: 'contains',
                value,
              },
            ],
          },
        ];
      }

      if (field === 'nickname') {
        filters.push({
          field: 'nickname',
          operator: 'contains',
          value,
        });
      }

      if (field === 'email') {
        filters.push({
          field: 'email',
          operator: 'contains',
          value,
        });
      }

      if (field === 'id') {
        // UUID 타입에는 contains 연산자를 사용하지 않고 정확한 값 비교
        if (UUID_REGEX.test(value)) {
          filters.push({
            field: 'id',
            operator: 'eq',
            value,
          });
        } else if (value) {
          // 유효하지 않은 UUID 형식이면 메시지만 표시하고 빈 필터 반환
          message.warning(
            'UUID 형식이 올바르지 않습니다. 예: 123e4567-e89b-12d3-a456-426614174000',
          );
          return [];
        }
      }

      return filters;
    },
    [],
  );

  // Refine useTable 훅 사용
  const { tableProps, setFilters } = useTable<UserProfile>({
    resource,
    syncWithLocation: true,
    sorters: {
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
      initial: createSearchFilters(urlSearch, urlField),
    },
    meta: {
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
          { currentDataSource: [], action: 'paginate' }
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
    [searchField, setFilters, createSearchFilters, pathname, router, tableProps],
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
      
      if (urlSearch) {
        setSearchTerm(urlSearch);
        setLocalSearchTerm(urlSearch);
        const initialFilters = createSearchFilters(urlSearch, urlField);
        setFilters(initialFilters, 'replace');
      }
    }
  }, [urlSearch, urlField, setFilters, createSearchFilters]);

  // 테이블 변경 핸들러
  const handleTableChange = (pagination: any, filters: any, sorter: any, extra: any) => {
    // 정렬 변경 시 페이지를 1로 설정
    const newPagination = extra.action === 'sort' 
      ? { ...pagination, current: 1 }
      : pagination;

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

  // 행 클릭 핸들러 추가
  const handleRowClick = (record: UserProfile) => {
    show('user_profiles', record.id);
  };

  return (
    <List breadcrumb={false} headerButtons={<CreateButton />} title='유저관리'>
      <Space style={{ marginBottom: 16 }}>
        <Select
          value={searchField}
          style={{ width: 120, maxWidth: '100%' }}
          onChange={handleFieldChange}
          options={[
            { value: 'all', label: '전체' },
            { value: 'nickname', label: '닉네임' },
            { value: 'email', label: '이메일' },
            { value: 'id', label: 'ID' },
          ]}
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

      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            onClick: () => handleRowClick(record),
            style: { cursor: 'pointer' }
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          size='small'
          onChange={handleTableChange}
        >
          <Table.Column
            dataIndex='id'
            title='ID'
            width={80}
            ellipsis={true}
            render={(value) => value && value.substring(0, 8) + '...'}
            sorter={true}
            sortDirections={['ascend', 'descend']}
          />

          <Table.Column
            dataIndex='avatar_url'
            title='프로필'
            width={160}
            render={(avatar_url, record: UserProfile) => (
              <Space>
                <Avatar src={avatar_url} size='small' />
                <div>
                  <div>{record.nickname || '-'}</div>
                  <div style={{ fontSize: '12px', color: '#666' }}>
                    {record.email || '-'}
                  </div>
                </div>
              </Space>
            )}
          />

          <Table.Column
            dataIndex='star_candy'
            title='스타캔디'
            sorter={true}
            sortDirections={['ascend', 'descend']}
            width={120}
            responsive={['sm']}
            render={(star_candy, record: UserProfile) => (
              <Space>
                <span>{star_candy}</span>
                {record.star_candy_bonus > 0 && (
                  <Tag color='green'>+{record.star_candy_bonus}</Tag>
                )}
              </Space>
            )}
          />

          <Table.Column
            dataIndex='gender'
            title='성별/나이 공개'
            responsive={['md']}
            sorter={true}
            sortDirections={['ascend', 'descend']}
            render={(gender, record: UserProfile) => (
              <Space>
                <Tag color={gender ? 'blue' : 'default'}>
                  {gender || '미설정'}
                </Tag>
                <Space direction='vertical' size={2}>
                  <span>
                    성별 공개:{' '}
                    <Switch
                      size='small'
                      disabled
                      checked={record.open_gender}
                    />
                  </span>
                  <span>
                    나이 공개:{' '}
                    <Switch size='small' disabled checked={record.open_ages} />
                  </span>
                </Space>
              </Space>
            )}
          />

          <Table.Column
            dataIndex='is_admin'
            title='관리자'
            width={80}
            responsive={['lg']}
            sorter={true}
            sortDirections={['ascend', 'descend']}
            render={(is_admin) => (
              <Tag color={is_admin ? 'red' : 'default'}>
                {is_admin ? '관리자' : '일반'}
              </Tag>
            )}
          />

          <Table.Column
            dataIndex='created_at'
            title='가입일'
            sorter={true}
            sortDirections={['ascend', 'descend']}
            width={120}
            responsive={['lg']}
            render={(created_at) => (
              <DateField value={created_at} format='YYYY-MM-DD' />
            )}
          />

          <Table.Column
            dataIndex='deleted_at'
            title='상태'
            width={120}
            sorter={true}
            sortDirections={['ascend', 'descend']}
            render={(deleted_at) => (
              <Space direction="vertical" size={1}>
                <Tag color={deleted_at ? 'error' : 'success'}>
                  {deleted_at ? '탈퇴' : '활성'}
                </Tag>
                {deleted_at && (
                  <div style={{ fontSize: '12px', color: '#666' }}>
                    <DateField value={deleted_at} format='YYYY-MM-DD HH:mm' />
                  </div>
                )}
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
}
