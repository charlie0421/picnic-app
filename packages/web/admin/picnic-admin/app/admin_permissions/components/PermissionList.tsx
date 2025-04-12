'use client';

import { List, useTable, DateField, CreateButton } from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Table, Space, Tag, Input } from 'antd';
import { useState, useEffect } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { AdminPermission } from '@/lib/types/permission';

export default function PermissionList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  
  // URL에서 search 파라미터 가져오기
  const urlSearch = searchParams.get('search') || '';
  
  const [searchTerm, setSearchTerm] = useState<string>(urlSearch);
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<AdminPermission>({
    resource: 'admin_permissions',
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
      search: searchTerm
        ? { query: searchTerm, fields: ['resource', 'action', 'description'] }
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
            onClick: () => show('admin_permissions', record.id),
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
          <Table.Column dataIndex='id' title='ID' sorter width={80} />
          <Table.Column
            dataIndex='resource'
            title='리소스'
            align='center'
            sorter
            width={120}
            render={(value) => <Tag color='blue'>{value}</Tag>}
          />
          <Table.Column
            dataIndex='action'
            title='액션'
            align='center'
            sorter
            width={100}
            render={(value) => {
              let color = 'green';
              if (value === 'delete') color = 'red';
              else if (value === 'update') color = 'orange';
              else if (value === 'create') color = 'blue';
              else if (value === '*') color = 'magenta';
              return <Tag color={color}>{value}</Tag>;
            }}
          />
          <Table.Column
            dataIndex='description'
            title='설명'
            align='center'
            sorter
            ellipsis={{ showTitle: true }}
            responsive={['md']}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            width={140}
            responsive={['lg']}
            render={(_, record: AdminPermission) => (
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