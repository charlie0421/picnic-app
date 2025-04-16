'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form, Select } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { FAQList } from './components';
import { FAQ } from '../../lib/types/faq';

const { Option } = Select;

export default function FAQListPage() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 검색어 가져오기
  const initialSearchTerm = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState<string>(initialSearchTerm);

  // URL에서 카테고리 가져오기
  const initialCategory = searchParams.get('category') || '';
  const [category, setCategory] = useState<string>(initialCategory);

  // URL에서 정렬 정보 가져오기
  const initialSortField = searchParams.get('sort');
  const initialSortOrder = searchParams.get('order') as 'asc' | 'desc';
  const initialSorters =
    initialSortField && initialSortOrder
      ? [{ field: initialSortField, order: initialSortOrder }]
      : [{ field: 'order_number', order: 'asc' as const }];

  const { resource } = useResource();
  const [form] = Form.useForm();

  // Refine useTable 훅 사용
  const {
    tableProps,
    tableQueryResult,
    sorters,
    setSorters,
    filters,
    setFilters,
  } = useTable<FAQ>({
    resource: 'faqs',
    syncWithLocation: true,
    sorters: {
      initial: initialSorters,
      mode: 'server',
    },
    filters: {
      mode: 'server',
      initial: [
        ...(searchTerm
          ? [
              {
                field: 'search',
                operator: 'contains' as const,
                value: searchTerm,
              },
            ]
          : []),
        ...(category
          ? [
              {
                field: 'category',
                operator: 'eq' as const,
                value: category,
              },
            ]
          : []),
      ],
    },
    pagination: {
      pageSize: 10,
    },
    meta: {
      search: searchTerm
        ? {
            query: searchTerm,
            fields: ['question', 'answer'],
          }
        : undefined,
      select: '*,faqs_created_by_fkey(*)',
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
          operator: 'contains' as const,
          value: searchValue,
        },
        ...(category
          ? [
              {
                field: 'category',
                operator: 'eq' as const,
                value: category,
              },
            ]
          : []),
      ];
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

    // 카테고리 업데이트
    if (category) {
      params.set('category', category);
    } else {
      params.delete('category');
    }

    // 정렬 정보 업데이트
    if (sorters && sorters.length > 0) {
      params.set('sort', sorters[0].field as string);
      params.set('order', sorters[0].order as string);
    }

    // URL 변경
    const newUrl = `${pathname}?${params.toString()}`;
    router.replace(newUrl, { scroll: false });
  }, [searchTerm, category, sorters, pathname, router, searchParams]);

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
    applyFilters(value, category);
  };

  // 카테고리 변경 핸들러
  const handleCategoryChange = (value: string) => {
    setCategory(value);
    applyFilters(searchTerm, value);
  };

  // 필터 적용 함수
  const applyFilters = (search: string, cat: string) => {
    const filterItems = [];

    if (search) {
      filterItems.push({
        field: 'search',
        operator: 'contains' as const,
        value: search,
      });
    }

    if (cat) {
      filterItems.push({
        field: 'category',
        operator: 'eq' as const,
        value: cat,
      });
    }

    setFilters(filterItems);
  };

  // 에러 처리
  if (tableQueryResult.error) {
    return (
      <Alert
        message='데이터 로딩 오류'
        description={tableQueryResult.error.message}
        type='error'
        showIcon
      />
    );
  }

  // FAQ 카테고리 목록 (실제로는 데이터베이스에서 가져와야 함)
  const categoryOptions = [
    { label: '전체', value: '' },
    { label: '일반', value: '일반' },
    { label: '계정', value: '계정' },
    { label: '서비스', value: '서비스' },
    { label: '결제', value: '결제' },
    { label: '기타', value: '기타' },
  ];

  return (
    <AuthorizePage resource='faqs' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || 'FAQ'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='FAQ 검색'
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
            defaultValue={initialSearchTerm}
          />

          <Select
            placeholder='카테고리 선택'
            style={{ width: 150 }}
            value={category}
            onChange={handleCategoryChange}
            allowClear
          >
            {categoryOptions.map((option) => (
              <Option key={option.value} value={option.value}>
                {option.label}
              </Option>
            ))}
          </Select>
        </Space>

        <FAQList tableProps={tableProps} />
      </List>
    </AuthorizePage>
  );
}
