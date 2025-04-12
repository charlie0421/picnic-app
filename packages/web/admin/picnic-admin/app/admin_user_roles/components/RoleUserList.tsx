'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useMany, useResource } from '@refinedev/core';
import { Table, Space, Tag, Input } from 'antd';
import { useState, useEffect } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { AdminUserRole, AdminRole } from '@/lib/types/permission';

export default function RoleUserList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  
  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<AdminUserRole>({
    resource: 'admin_user_roles',
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
      select: '*, role_id, user_id',
      search: searchTerm
        ? { query: searchTerm, fields: ['role_id', 'user_id'] }
        : undefined,
    },
  });

  // URL 파라미터 업데이트
  const updateUrlParams = (search: string) => {
    const params = new URLSearchParams(searchParams.toString());
    
    if (!search) {
      params.delete('search');
    } else {
      params.set('search', search);
    }
    
    router.push(`${pathname}?${params.toString()}`);
  };

  // 컴포넌트 마운트 시 URL에서 검색어 복원
  useEffect(() => {
    if (urlSearch) {
      setSearchTerm(urlSearch);
    }
  }, [urlSearch]);

  // 역할 정보 가져오기
  const { data: rolesData } = useMany({
    resource: 'admin_roles',
    ids: tableProps?.dataSource?.map((item) => item.role_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  // 사용자 정보 가져오기
  const { data: usersData } = useMany({
    resource: 'user_profiles',
    ids: tableProps?.dataSource?.map((item) => item.user_id) ?? [],
    queryOptions: {
      enabled: !!tableProps?.dataSource,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
    updateUrlParams(value);
  };

  return (
    <List
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title={resource?.meta?.list?.label}
    >
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder='검색...'
          onSearch={handleSearch}
          defaultValue={searchTerm}
          style={{ width: 200, maxWidth: '100%' }}
          allowClear
        />
      </Space>
      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('admin_user_roles', record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
          scroll={{ x: 'max-content' }}
          size="small"
        >
          <Table.Column dataIndex='id' title='ID' align='center' sorter width={80} />
          <Table.Column
            dataIndex='role_id'
            title='역할'
            align='center'
            sorter
            width={120}
            ellipsis={{ showTitle: true }}
            render={(value) => {
              const role = rolesData?.data?.find((item) => item.id === value);
              return role ? <Tag color='blue'>{role.name}</Tag> : value;
            }}
          />
          <Table.Column
            dataIndex='user_id'
            title='사용자'
            align='center'
            sorter
            width={160}
            ellipsis={{ showTitle: true }}
            render={(value) => {
              const user = usersData?.data?.find((item) => item.id === value);
              return user ? user.email || user.id : value;
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            sorter
            width={140}
            responsive={['md']}
            render={(_, record: AdminUserRole) => (
              <Space direction='vertical' size="small">
                <DateField
                  value={record.created_at}
                  format='YYYY-MM-DD'
                />
                <DateField
                  value={record.updated_at}
                  format='YYYY-MM-DD'
                />
              </Space>
            )}
          />
        </Table>
      </div>
    </List>
  );
} 