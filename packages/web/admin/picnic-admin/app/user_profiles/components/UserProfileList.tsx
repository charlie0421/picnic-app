'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Avatar, Switch, Select, message } from 'antd';
import { useNavigation, CrudFilters } from '@refinedev/core';
import { useState, useEffect, useCallback, useRef } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { UserProfile } from '../../../lib/types/user_profiles';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface UserProfileListProps {
  resource?: string;
}

export function UserProfileList({ resource = 'user_profiles' }: UserProfileListProps) {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const { show } = useNavigation();
  
  // URL에서 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  const urlField = searchParams.get('field') || 'all';
  
  // 초기 마운트 여부를 추적하는 ref
  const initialMountRef = useRef(true);
  
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [localSearchTerm, setLocalSearchTerm] = useState<string>(urlSearch);
  const [searchField, setSearchField] = useState<string>(urlField);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  // URL 파라미터 업데이트 (검색 상태를 초기화하지 않도록 개선)
  const updateUrlParams = useCallback((params: { search?: string; field?: string }) => {
    const urlParams = new URLSearchParams(searchParams.toString());
    
    // 검색어 업데이트
    if (params.search !== undefined) {
      if (!params.search) {
        urlParams.delete('search');
      } else {
        urlParams.set('search', params.search);
      }
    }
    
    // 검색 필드 업데이트
    if (params.field !== undefined) {
      if (params.field === 'all') {
        urlParams.delete('field');
      } else {
        urlParams.set('field', params.field);
      }
    }
    
    router.push(`${pathname}?${urlParams.toString()}`, { 
      scroll: false,
    });
  }, [searchParams, pathname, router]);

  // 검색 필터 생성 함수
  const createSearchFilters = useCallback((value: string, field: string): CrudFilters => {
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
        message.warning('UUID 형식이 올바르지 않습니다. 예: 123e4567-e89b-12d3-a456-426614174000');
        return [];
      }
    }
    
    return filters;
  }, []);

  // Refine useTable 훅 사용
  const { tableProps, setFilters } = useTable<UserProfile>({
    resource,
    // syncWithLocation으로 인한 검색 상태 초기화 방지
    syncWithLocation: false,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    filters: {
      mode: 'server',
      initial: createSearchFilters(urlSearch, urlField),
    },
    onSearch: (values) => {
      return createSearchFilters(searchTerm, searchField);
    },
    meta: {
      // Supabase에서 필드별로 다른 검색 연산자 사용
      fields: (() => {
        if (searchField === 'all') return ['nickname', 'email'];
        if (searchField === 'id') return ['id'];
        return [searchField];
      })(),
      operators: [
        {
          kind: 'contains',
          operator: 'ilike',
          value: `%:value%`,
        },
        {
          kind: 'eq',
          operator: 'eq',
          value: `:value`,
        },
        {
          kind: 'or',
          operator: 'or',
        },
      ],
    },
  });

  // 검색어 입력 핸들러 - 로컬 상태만 업데이트
  const handleSearchInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setLocalSearchTerm(value);
  }, []);

  // 검색 실행 함수
  const executeSearch = useCallback((value: string) => {
    setIsSearching(true);
    setSearchTerm(value);
    updateUrlParams({ search: value });
    
    const filters = createSearchFilters(value, searchField);
    if (filters.length > 0) {
      setFilters(filters, 'replace');
    } else if (!value) {
      // 검색어가 비어있으면 필터 초기화
      setFilters([], 'replace');
    }
    
    setIsSearching(false);
  }, [searchField, setFilters, updateUrlParams, createSearchFilters]);

  // 검색 버튼 클릭 핸들러
  const handleSearch = useCallback((value: string) => {
    executeSearch(value);
  }, [executeSearch]);

  const handleFieldChange = useCallback((value: string) => {
    setSearchField(value);
    updateUrlParams({ field: value });
    
    if (searchTerm) {
      // 검색 필드가 변경되면 현재 검색어로 검색 다시 실행
      executeSearch(searchTerm);
    }
  }, [searchTerm, updateUrlParams, executeSearch]);

  // 컴포넌트 마운트 시와 URL 파라미터 변경 시 상태 초기화
  useEffect(() => {
    if (initialMountRef.current) {
      // 첫 마운트 시에만 실행
      initialMountRef.current = false;
      
      // URL 파라미터에서 값을 가져와 초기 필터 설정
      if (urlSearch) {
        const initialFilters = createSearchFilters(urlSearch, urlField);
        if (initialFilters.length > 0) {
          setFilters(initialFilters, 'replace');
        }
      }
      
      return;
    }
    
    // URL 파라미터에서 값을 가져와 컴포넌트 상태 설정
    // 검색중이 아닐 때만 URL 변경에 따라 상태 업데이트
    if (!isSearching) {
      const currentUrlSearch = searchParams.get('search') || '';
      const currentUrlField = searchParams.get('field') || 'all';
      
      // 상태가 실제로 변경될 때만 업데이트
      if (currentUrlSearch !== searchTerm) {
        setSearchTerm(currentUrlSearch);
        setLocalSearchTerm(currentUrlSearch);
      }
      
      if (currentUrlField !== searchField) {
        setSearchField(currentUrlField);
      }
      
      // URL 파라미터에 검색어가 있을 때만 필터 적용
      if (currentUrlSearch && (currentUrlSearch !== searchTerm || currentUrlField !== searchField)) {
        const filters = createSearchFilters(currentUrlSearch, currentUrlField);
        if (filters.length > 0) {
          setFilters(filters, 'replace');
        }
      } else if (!currentUrlSearch && searchTerm) {
        // URL 파라미터에서 검색어가 제거되었으면 필터도 초기화
        setFilters([], 'replace');
      }
    }
  }, [searchParams, setFilters, createSearchFilters, urlSearch, urlField, searchTerm, searchField, isSearching]);

  return (
    <List 
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title="유저관리"
    >
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
          placeholder="검색어를 입력하세요"
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
          rowKey="id"
          scroll={{ x: 'max-content' }}
          onRow={(record: UserProfile) => ({
            style: { cursor: 'pointer' },
            onClick: () => show(resource, record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          size="small"
        >
          <Table.Column 
            dataIndex="id" 
            title="ID" 
            width={80}
            ellipsis={true}
            render={(value) => value && value.substring(0, 8) + '...'}
          />
          
          <Table.Column
            dataIndex="avatar_url"
            title="프로필"
            width={160}
            render={(avatar_url, record: UserProfile) => (
              <Space>
                <Avatar src={avatar_url} size="small" />
                <div>
                  <div>{record.nickname || '-'}</div>
                  <div style={{ fontSize: '12px', color: '#666' }}>{record.email || '-'}</div>
                </div>
              </Space>
            )}
          />
          
          <Table.Column
            dataIndex="star_candy"
            title="스타캔디"
            sorter
            width={120}
            responsive={['sm']}
            render={(star_candy, record: UserProfile) => (
              <Space>
                <span>{star_candy}</span>
                {record.star_candy_bonus > 0 && (
                  <Tag color="green">+{record.star_candy_bonus}</Tag>
                )}
              </Space>
            )}
          />
          
          <Table.Column
            dataIndex="gender"
            title="성별/나이 공개"
            responsive={['md']}
            render={(gender, record: UserProfile) => (
              <Space>
                <Tag color={gender ? 'blue' : 'default'}>
                  {gender || '미설정'}
                </Tag>
                <Space direction="vertical" size={2}>
                  <span>성별 공개: <Switch size="small" disabled checked={record.open_gender} /></span>
                  <span>나이 공개: <Switch size="small" disabled checked={record.open_ages} /></span>
                </Space>
              </Space>
            )}
          />
          
          <Table.Column
            dataIndex="is_admin"
            title="관리자"
            width={80}
            responsive={['lg']}
            render={(is_admin) => (
              <Tag color={is_admin ? 'red' : 'default'}>
                {is_admin ? '관리자' : '일반'}
              </Tag>
            )}
          />
          
          <Table.Column
            dataIndex="created_at"
            title="가입일"
            sorter
            width={120}
            responsive={['lg']}
            render={(created_at) => (
              <DateField value={created_at} format="YYYY-MM-DD" />
            )}
          />
          
          <Table.Column
            dataIndex="deleted_at"
            title="상태"
            width={80}
            render={(deleted_at) => (
              <Tag color={deleted_at ? 'error' : 'success'}>
                {deleted_at ? '탈퇴' : '활성'}
              </Tag>
            )}
          />
        </Table>
      </div>
    </List>
  );
} 