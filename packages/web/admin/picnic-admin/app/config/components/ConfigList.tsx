'use client';

import {
  List,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Space, Input, message } from 'antd';
import { useState, useEffect, useCallback } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { Config } from '@/lib/types/config';
import { supabaseBrowserClient } from '@/lib/supabase/client';

export default function ConfigList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  
  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const [loading, setLoading] = useState<boolean>(false);
  const [dataSource, setDataSource] = useState<Config[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
  });
  
  const { show } = useNavigation();

  // 데이터 로드 함수
  const loadData = useCallback(async () => {
    setLoading(true);
    
    try {
      // Supabase 쿼리 작성
      let query = supabaseBrowserClient
        .from('config')
        .select('id, key, value, created_at, updated_at', { count: 'exact' });
      
      // 검색어가 있으면 필터 추가
      if (searchTerm) {
        // 키와 값 필드에서 검색
        query = query.or(`key.ilike.%${searchTerm}%,value.ilike.%${searchTerm}%`);
      }
      
      // 정렬 추가
      query = query.order('key', { ascending: true });
      
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
    >
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder="설정 키 또는 값 검색"
          onSearch={handleSearch}
          defaultValue={searchTerm}
          style={{ width: 350, maxWidth: '100%' }}
          allowClear
        />
      </Space>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          rowKey='id'
          dataSource={dataSource}
          loading={loading}
          onChange={handleTableChange}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => {
              if (record.id) {
                show('config', record.id);
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
          scroll={{ x: 'max-content' }}
          size="small"
        >
          <Table.Column
            dataIndex='id'
            title='ID'
            width={80}
          />
          <Table.Column 
            dataIndex='key' 
            title='키' 
            width={150} 
          />
          <Table.Column 
            dataIndex='value' 
            title='값' 
            ellipsis={{
              showTitle: true,
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            width={200}
            render={(_, record: any) => (
              <Space direction="vertical" size="small">
                <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
                <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
} 