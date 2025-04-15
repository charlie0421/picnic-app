'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form, Select } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { QnAList } from './components';
import { QnA } from '../../lib/types/qna';

const { Option } = Select;

export default function QnAListPage() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 검색어 가져오기
  const initialSearchTerm = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState<string>(initialSearchTerm);

  // URL에서 상태 필터 가져오기
  const initialStatus = searchParams.get('status') || '';
  const [statusFilter, setStatusFilter] = useState<string>(initialStatus);

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
  const { tableProps, tableQueryResult, sorters, setSorters, filters, setFilters } = useTable<QnA>({
    resource: 'qnas',
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
            fields: ['title', 'question', 'answer'],
          }
        : undefined,
      idField: 'qna_id',
      select: '*,qnas_created_by_fkey(*),qnas_answered_by_fkey(*)'
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

    // 상태 필터 업데이트
    if (statusFilter) {
      params.set('status', statusFilter);
    } else {
      params.delete('status');
    }

    // 정렬 정보 업데이트
    if (sorters && sorters.length > 0) {
      params.set('sort', sorters[0].field as string);
      params.set('order', sorters[0].order as string);
    }

    // URL 변경
    const newUrl = `${pathname}?${params.toString()}`;
    router.replace(newUrl, { scroll: false });
  }, [searchTerm, statusFilter, sorters, pathname, router, searchParams]);

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

  // QnA 상태 옵션
  const statusOptions = [
    { label: '전체', value: '' },
    { label: '대기중', value: 'PENDING' },
    { label: '답변완료', value: 'ANSWERED' },
    { label: '보관', value: 'ARCHIVED' },
  ];

  return (
    <AuthorizePage resource='qnas' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || 'Q&A'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='QnA 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
            defaultValue={initialSearchTerm}
          />
          
          <Select
            placeholder="상태 선택"
            style={{ width: 150 }}
            value={statusFilter}
            onChange={(value) => setStatusFilter(value)}
            allowClear
          >
            {statusOptions.map(option => (
              <Option key={option.value} value={option.value}>{option.label}</Option>
            ))}
          </Select>
        </Space>

        <QnAList tableProps={tableProps} />
      </List>
    </AuthorizePage>
  );
} 