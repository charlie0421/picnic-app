'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Tooltip } from 'antd';
import { useNavigation, BaseRecord, useMany } from '@refinedev/core';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { Post } from './components/types';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';

export default function PostList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();

  // URL에서 검색어 가져오기
  const initialSearchTerm = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState<string>(initialSearchTerm);

  // URL에서 정렬 정보 가져오기
  const initialSortField = searchParams.get('sort');
  const initialSortOrder = searchParams.get('order') as 'asc' | 'desc';
  const initialSorters =
    initialSortField && initialSortOrder
      ? [{ field: initialSortField, order: initialSortOrder }]
      : [{ field: 'created_at', order: 'desc' as const }];

  const { show } = useNavigation();
  const { resource } = useResource();

  // Refine useTable 훅 사용
  const { tableProps, sorters, setSorters, current, pageSize, setFilters } =
    useTable({
      resource: 'posts',
      syncWithLocation: true,
      sorters: {
        initial: initialSorters,
        mode: 'server',
      },
      pagination: {
        mode: 'server',
        current: Number(searchParams.get('current')) || 1,
        pageSize: Number(searchParams.get('pageSize')) || 10,
      },
      // 검색 기능 활용
      meta: {
        search: searchTerm
          ? {
              query: searchTerm,
              fields: ['title'],
            }
          : undefined,
        idField: 'post_id',
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

    // 페이지네이션 정보 업데이트
    if (tableProps.pagination && typeof tableProps.pagination !== 'boolean') {
      if (tableProps.pagination.current) {
        params.set('current', tableProps.pagination.current.toString());
      }

      if (tableProps.pagination.pageSize) {
        params.set('pageSize', tableProps.pagination.pageSize.toString());
      }
    }

    // 정렬 정보 업데이트
    if (sorters && sorters.length > 0) {
      params.set('sort', sorters[0].field as string);
      params.set('order', sorters[0].order as string);
    }

    // URL 변경
    const newUrl = `${pathname}?${params.toString()}`;
    router.replace(newUrl, { scroll: false });
  }, [
    searchTerm,
    tableProps.pagination,
    sorters,
    pathname,
    router,
    searchParams,
  ]);

  // 컴포넌트 마운트 시 URL에서 정렬 정보 가져오기
  useEffect(() => {
    const sortField = searchParams.get('sort');
    const sortOrder = searchParams.get('order');

    if (sortField && sortOrder) {
      setSorters([{ field: sortField, order: sortOrder as 'asc' | 'desc' }]);
    }
  }, [searchParams, setSorters]);

  // 작성자 정보 가져오기
  const { data: userProfilesData } = useMany({
    resource: 'user_profiles',
    ids: tableProps?.dataSource?.map((item: any) => item.user_id) || [],
    queryOptions: {
      enabled: tableProps?.dataSource && tableProps.dataSource.length > 0,
    },
    meta: {
      idField: 'user_id',
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource='posts' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시글 목록'}
      >
        <Space style={{ marginBottom: 16 }}>
          <Input.Search
            placeholder='제목 검색'
            onSearch={handleSearch}
            defaultValue={searchTerm}
            style={{ width: 300 }}
            allowClear
          />
        </Space>

        <Table
          {...tableProps}
          rowKey='post_id'
          scroll={{ x: 'max-content' }}
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('posts', record.post_id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column
            dataIndex='post_id'
            title='ID'
            width={100}
            ellipsis={true}
          />
          <Table.Column dataIndex='title' title='제목' sorter />
          <Table.Column
            dataIndex='user_id'
            title='작성자'
            width={150}
            render={(user_id: string, record: any) => {
              // 익명 게시글인 경우
              if (record.is_anonymous) {
                return <Tag color='blue'>익명</Tag>;
              }

              // user_profiles 데이터에서 해당 사용자 찾기
              const userProfile = userProfilesData?.data?.find(
                (item) => item.user_id === user_id,
              );

              if (userProfile) {
                return (
                  <Tooltip title={`ID: ${user_id}`}>
                    {userProfile.nickname || userProfile.name || user_id}
                  </Tooltip>
                );
              }

              return user_id;
            }}
          />
          <Table.Column
            dataIndex='view_count'
            title='조회수'
            width={100}
            sorter
          />
          <Table.Column
            dataIndex='reply_count'
            title='댓글수'
            width={100}
            sorter
          />
          <Table.Column
            dataIndex='is_anonymous'
            title='익명 여부'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'blue' : 'default'}>
                {value ? '익명' : '실명'}
              </Tag>
            )}
          />
          <Table.Column
            dataIndex='is_hidden'
            title='숨김 여부'
            width={120}
            render={(value: boolean) => (
              <Tag color={value ? 'red' : 'green'}>
                {value ? '숨김' : '표시'}
              </Tag>
            )}
          />
          <Table.Column
            dataIndex='created_at'
            title='생성일'
            width={200}
            sorter
            render={(value) => (
              <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
