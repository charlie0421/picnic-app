'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { useMany, useNavigation, useResource } from '@refinedev/core';
import { Table, Input, Space, Image, Tag, Checkbox, Select, TablePaginationConfig } from 'antd';
import { useState, useEffect } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';
import { Artist } from '@/lib/types/artist';
import { genderOptions } from '@/lib/types/user_profiles';
import { supabaseBrowserClient } from '@/lib/supabase/client';

export default function ArtistList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  const currentPage = parseInt(searchParams.get('current') || '1');
  const pageSize = parseInt(searchParams.get('pageSize') || '10');

  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [searchQuery, setSearchQuery] = useState<string>(urlSearch);
  const [searchResults, setSearchResults] = useState<Artist[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [filters, setFilters] = useState({
    is_solo: searchParams.get('is_solo') === 'true',
    is_kpop: searchParams.get('is_kpop') === 'true',
    is_musical: searchParams.get('is_musical') === 'true',
    birthMonth: searchParams.get('birth_month') ? parseInt(searchParams.get('birth_month')!) : undefined,
  });
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps, tableQueryResult } = useTable<Artist>({
    resource: 'artist',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    meta: {
      select: '*, group_id',
    },
  });

  // URL 파라미터 업데이트
  const updateUrlParams = (search: string, page: number = 1, size: number = 10) => {
    const params = new URLSearchParams(searchParams.toString());

    if (!search) {
      params.delete('search');
    } else {
      params.set('search', search);
    }

    // 필터 상태를 URL에 반영
    if (filters.is_solo) params.set('is_solo', 'true');
    else params.delete('is_solo');

    if (filters.is_kpop) params.set('is_kpop', 'true');
    else params.delete('is_kpop');

    if (filters.is_musical) params.set('is_musical', 'true');
    else params.delete('is_musical');

    if (filters.birthMonth) params.set('birth_month', filters.birthMonth.toString());
    else params.delete('birth_month');

    // 페이지네이션 파라미터 추가
    params.set('current', page.toString());
    params.set('pageSize', size.toString());

    router.push(`${pathname}?${params.toString()}`);
  };

  // 검색어 입력 시
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  // 검색 실행
  const handleSearch = async (value: string, page: number = currentPage, size: number = pageSize) => {
    const trimmedValue = value.trim();
    setSearchQuery(trimmedValue);
    updateUrlParams(trimmedValue, page, size);

    // 필터 조건을 OR로 적용
    const filterConditions = [];
    if (filters.is_solo) filterConditions.push('is_solo.eq.true');
    if (filters.is_kpop) filterConditions.push('is_kpop.eq.true');
    if (filters.is_musical) filterConditions.push('is_musical.eq.true');

    // 총 개수 조회
    let countQuery = supabaseBrowserClient.from('artist').select('*', { count: 'exact', head: true });

    if (filterConditions.length > 0) {
      countQuery = countQuery.or(filterConditions.join(','));
    }

    if (filters.birthMonth) {
      countQuery = countQuery.eq('mm', filters.birthMonth);
    }

    if (trimmedValue) {
      countQuery = countQuery.or(
        `name->>ko.ilike.%${trimmedValue}%,` +
          `name->>en.ilike.%${trimmedValue}%,` +
          `name->>ja.ilike.%${trimmedValue}%,` +
          `name->>zh.ilike.%${trimmedValue}%,` +
          `name->>id.ilike.%${trimmedValue}%`,
      );
    }

    const { count } = await countQuery;
    setTotalCount(count || 0);

    // 데이터 조회
    let query = supabaseBrowserClient.from('artist').select('*');

    if (filterConditions.length > 0) {
      query = query.or(filterConditions.join(','));
    }

    if (filters.birthMonth) {
      query = query.eq('mm', filters.birthMonth);
    }

    if (trimmedValue) {
      query = query.or(
        `name->>ko.ilike.%${trimmedValue}%,` +
          `name->>en.ilike.%${trimmedValue}%,` +
          `name->>ja.ilike.%${trimmedValue}%,` +
          `name->>zh.ilike.%${trimmedValue}%,` +
          `name->>id.ilike.%${trimmedValue}%`,
      );
    }

    query = query.order('created_at', { ascending: false });

    // 페이지네이션 적용
    const from = (page - 1) * size;
    const to = from + size - 1;
    query = query.range(from, to);

    const { data, error } = await query;

    if (!error && data) {
      setSearchResults(data);
    } else {
      console.error('Query error:', error);
      setSearchResults([]);
    }
  };

  // 검색 버튼 클릭 시
  const handleSearchSubmit = (value: string) => {
    handleSearch(value);
  };

  // URL에서 필터 상태 복원
  useEffect(() => {
    const isSolo = searchParams.get('is_solo') === 'true';
    const isKpop = searchParams.get('is_kpop') === 'true';
    const isMusical = searchParams.get('is_musical') === 'true';
    const birthMonth = searchParams.get('birth_month') ? parseInt(searchParams.get('birth_month')!) : undefined;

    setFilters({
      is_solo: isSolo,
      is_kpop: isKpop,
      is_musical: isMusical,
      birthMonth,
    });
  }, [searchParams]);

  // 필터 변경 시 검색 실행
  useEffect(() => {
    handleSearch(searchQuery);
  }, [filters.is_solo, filters.is_kpop, filters.is_musical, filters.birthMonth]);

  // URL 파라미터가 변경될 때마다 검색 실행
  useEffect(() => {
    const newSearch = searchParams.get('search') || '';
    const newFilters = {
      is_solo: searchParams.get('is_solo') === 'true',
      is_kpop: searchParams.get('is_kpop') === 'true',
      is_musical: searchParams.get('is_musical') === 'true',
      birthMonth: searchParams.get('birth_month') ? parseInt(searchParams.get('birth_month')!) : undefined,
    };
    const newPage = parseInt(searchParams.get('current') || '1');
    const newPageSize = parseInt(searchParams.get('pageSize') || '10');

    setSearchTerm(newSearch);
    setSearchQuery(newSearch);
    setFilters(newFilters);
    handleSearch(newSearch, newPage, newPageSize);
  }, [searchParams]);

  const finalTableProps = {
    ...tableProps,
    dataSource: searchResults,
    pagination: {
      ...tableProps.pagination,
      total: totalCount,
      current: currentPage,
      pageSize: pageSize,
      showSizeChanger: true,
      pageSizeOptions: ['10', '20', '50', '100'],
      showTotal: (total: number) => `총 ${total}개 항목`,
      onChange: (page: number, pageSize: number) => {
        handleSearch(searchQuery, page, pageSize);
      },
    },
  };

  // 아티스트 그룹 정보 가져오기
  const { data: groupsData, isLoading: groupsIsLoading } = useMany({
    resource: 'artist_group',
    ids:
      (searchResults
        ?.map((item: Artist) => {
          const groupId = item?.group_id;
          return groupId ? String(groupId) : undefined;
        })
        .filter(Boolean) as string[]) ?? [],
    queryOptions: {
      enabled: !!searchResults?.length,
    },
  });

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resource?.meta?.list?.label}
    >
      <Space direction='vertical' style={{ width: '100%', marginBottom: 16 }}>
        <Space>
          <Input.Search
            placeholder='아티스트 이름 검색'
            onSearch={handleSearchSubmit}
            value={searchTerm}
            onChange={handleSearchChange}
            style={{ width: 300, maxWidth: '100%' }}
            allowClear
          />
          <Select
            placeholder="생년월일 월 선택"
            allowClear
            style={{ width: 150 }}
            value={filters.birthMonth}
            onChange={(value) => setFilters({ ...filters, birthMonth: value })}
            options={Array.from({ length: 12 }, (_, i) => ({
              value: i + 1,
              label: `${i + 1}월`,
            }))}
          />
        </Space>
        <Space>
          <Checkbox
            checked={filters.is_solo}
            onChange={(e) =>
              setFilters({ ...filters, is_solo: e.target.checked })
            }
          >
            솔로
          </Checkbox>
          <Checkbox
            checked={filters.is_kpop}
            onChange={(e) =>
              setFilters({ ...filters, is_kpop: e.target.checked })
            }
          >
            K-POP
          </Checkbox>
          <Checkbox
            checked={filters.is_musical}
            onChange={(e) =>
              setFilters({ ...filters, is_musical: e.target.checked })
            }
          >
            뮤지컬
          </Checkbox>
        </Space>
      </Space>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...finalTableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('artist', record.id),
          })}
          size='small'
        >
          <Table.Column
            dataIndex='id'
            title='ID'
            align='center'
            sorter
            width={80}
          />

          <Table.Column
            dataIndex={['name']}
            title='이름'
            align='center'
            width={200}
            render={(value: Record<string, string>) => (
              <MultiLanguageDisplay languages={['ko']} value={value} />
            )}
          />

          <Table.Column
            dataIndex='image'
            title='이미지'
            align='center'
            width={120}
            responsive={['md']}
            render={(value: string) =>
              value && (
                <div style={{ width: 80, height: 80, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Image
                    src={getCdnImageUrl(value, 80)}
                    alt='아티스트 이미지'
                    width={80}
                    height={80}
                    preview={false}
                    style={{ objectFit: 'cover' }}
                  />
                </div>
              )
            }
          />

          <Table.Column
            dataIndex='gender'
            title='성별'
            align='center'
            sorter
            width={100}
            responsive={['sm']}
            render={(value: string) => {
              const option = genderOptions.find((opt) => opt.value === value);
              return option ? option.label : value || '-';
            }}
          />

          <Table.Column
            dataIndex='group_id'
            title='그룹'
            align='center'
            sorter
            width={150}
            render={(value) => {
              if (groupsIsLoading) {
                return <>로딩 중...</>;
              }

              if (!value) {
                return <span>-</span>;
              }

              const group = groupsData?.data?.find(
                (item) => Number(item.id) === Number(value),
              );

              if (!group) {
                return <span>-</span>;
              }

              return (
                <Space
                  style={{ cursor: 'pointer' }}
                  onClick={(e) => {
                    e.stopPropagation();
                    show('artist_group', value);
                  }}
                >
                  {group.image && (
                    <div style={{ width: 40, height: 40, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Image
                        src={getCdnImageUrl(group.image, 40)}
                        alt='그룹 이미지'
                        width={40}
                        height={40}
                        preview={false}
                        style={{ objectFit: 'cover' }}
                      />
                    </div>
                  )}
                  <span>{group.name?.ko || '-'}</span>
                </Space>
              );
            }}
          />

          <Table.Column
            dataIndex='birth_date'
            title='생년월일'
            align='center'
            sorter
            width={120}
            responsive={['lg']}
            render={(value: string) => value || '-'}
          />

          <Table.Column
            dataIndex='debut_date'
            title='데뷔일'
            align='center'
            sorter
            width={120}
            render={(value: string) => value || '-'}
          />

          <Table.Column
            dataIndex='is_solo'
            title='솔로'
            align='center'
            width={80}
            render={(value: boolean) => (
              <Tag color={value ? 'green' : 'default'}>
                {value ? '예' : '아니오'}
              </Tag>
            )}
          />

          <Table.Column
            dataIndex='is_kpop'
            title='K-POP'
            align='center'
            width={80}
            render={(value: boolean) => (
              <Tag color={value ? 'purple' : 'default'}>
                {value ? '예' : '아니오'}
              </Tag>
            )}
          />

          <Table.Column
            dataIndex='is_musical'
            title='뮤지컬'
            align='center'
            width={80}
            render={(value: boolean) => (
              <Tag color={value ? 'orange' : 'default'}>
                {value ? '예' : '아니오'}
              </Tag>
            )}
          />

          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            sorter
            width={140}
            responsive={['lg']}
            render={(_, record: Artist) => (
              <Space direction='vertical' size='small'>
                <DateField value={record.created_at} format='YYYY-MM-DD' />
                <DateField value={record.updated_at} format='YYYY-MM-DD' />
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
}
