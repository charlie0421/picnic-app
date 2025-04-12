'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { useNavigation, useResource, CrudFilters } from '@refinedev/core';
import { Table, Space, Input, Image, message } from 'antd';
import { useState, useEffect, useCallback } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';
import { ArtistGroup } from '@/lib/types/artist';
import { supabaseBrowserClient } from '@/lib/supabase/client';

export default function ArtistGroupList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  
  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [loading, setLoading] = useState<boolean>(false);
  const [dataSource, setDataSource] = useState<ArtistGroup[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
  });
  
  const { show } = useNavigation();
  const { resource } = useResource();

  // 데이터 로드 함수
  const loadData = useCallback(async () => {
    setLoading(true);
    
    try {
      // Supabase 쿼리 작성
      let query = supabaseBrowserClient
        .from('artist_group')
        .select('*', { count: 'exact' });
      
      // 검색어가 있으면 필터 추가
      if (searchTerm) {
        // JSONB 필드 검색을 위한 필터 (4개 언어 지원)
        query = query.or(`name->>ko.ilike.%${searchTerm}%,name->>en.ilike.%${searchTerm}%,name->>ja.ilike.%${searchTerm}%,name->>zh.ilike.%${searchTerm}%`);
      }
      
      // 정렬 추가
      query = query.order('created_at', { ascending: false });
      
      // 페이지네이션 추가
      const from = (pagination.current - 1) * pagination.pageSize;
      const to = from + pagination.pageSize - 1;
      query = query.range(from, to);
      
      // 쿼리 실행
      const { data, error, count } = await query;
      
      if (error) {
        throw error;
      }
      
      // 데이터 설정
      setDataSource(data || []);
      if (count !== null) {
        setTotal(count);
      }
    } catch (error) {
      console.error('데이터 로드 중 오류 발생:', error);
      message.error('데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  }, [searchTerm, pagination]);
  
  // 페이지 변경 핸들러
  const handleTableChange = useCallback((pagination: any) => {
    setPagination({
      current: pagination.current,
      pageSize: pagination.pageSize,
    });
  }, []);

  // URL 파라미터 업데이트
  const updateUrlParams = useCallback((search: string) => {
    const params = new URLSearchParams(searchParams.toString());
    
    if (!search) {
      params.delete('search');
    } else {
      params.set('search', search);
    }
    
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }, [searchParams, pathname, router]);

  // 검색 실행 함수
  const handleSearch = useCallback((value: string) => {
    console.log("검색 실행:", value);
    setSearchTerm(value);
    setPagination({ ...pagination, current: 1 }); // 검색시 첫 페이지로 이동
    updateUrlParams(value);
  }, [updateUrlParams, pagination]);

  // URL 파라미터 변경 시 검색 상태 업데이트
  useEffect(() => {
    const currentUrlSearch = searchParams.get('search') || '';
    if (currentUrlSearch !== searchTerm) {
      console.log("URL 검색어 변경:", currentUrlSearch);
      setSearchTerm(currentUrlSearch);
    }
  }, [searchParams, searchTerm]);

  // 검색어 또는 페이지네이션 변경 시 데이터 다시 로드
  useEffect(() => {
    loadData();
  }, [loadData]);

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resource?.meta?.list?.label}
    >
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder='아티스트 그룹 이름 검색 (다국어 지원)'
          onSearch={handleSearch}
          defaultValue={searchTerm}
          style={{ width: 350, maxWidth: '100%' }}
          allowClear
        />
      </Space>
      <Table
        rowKey='id'
        dataSource={dataSource}
        loading={loading}
        scroll={{ x: 'max-content' }}
        onChange={handleTableChange}
        onRow={(record) => ({
          style: { cursor: 'pointer' },
          onClick: () => {
            if (record.id) {
              show('artist_group', record.id);
            }
          },
        })}
        pagination={{
          current: pagination.current,
          pageSize: pagination.pageSize,
          total: total,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50'],
          showTotal: (total) => `총 ${total}개 항목`,
        }}
      >
        <Table.Column dataIndex='id' title='ID' align='center' />
        <Table.Column
          dataIndex={['name']}
          title='이름'
          align='center'
          render={(value: Record<string, string>) => (
            <MultiLanguageDisplay languages={['ko']} value={value} />
          )}
        />
        <Table.Column
          dataIndex='image'
          title='이미지'
          align='center'
          width={130}
          render={(value: string | undefined) => {
            if (!value) return '-';
            return (
              <Image
                src={getCdnImageUrl(value, 100)}
                alt='아티스트 그룹 이미지'
                width={100}
                height={100}
                preview={false}
              />
            );
          }}
        />
        <Table.Column
          dataIndex='debut_date'
          title='데뷔일'
          align='center'
          render={(value) => {
            if (!value) return '-';
            return dayjs(value).format('YYYY년 MM월 DD일');
          }}
        />
        <Table.Column
          dataIndex={['created_at', 'updated_at']}
          title='생성일/수정일'
          align='center'
          render={(_, record: ArtistGroup) => (
            <Space direction='vertical'>
              <DateField
                value={record.created_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
              <DateField
                value={record.updated_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
            </Space>
          )}
        />
      </Table>
    </List>
  );
} 