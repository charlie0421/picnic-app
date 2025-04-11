'use client';

import { CreateButton, DateField, List, useTable } from '@refinedev/antd';
import { Table, Space, Input, Tag, Avatar, Switch, Select } from 'antd';
import { useNavigation, CrudFilters } from '@refinedev/core';
import { useState } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { UserProfile } from './types';
import { message } from 'antd';

// UUID 유효성 검사 정규식
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface UserProfileListProps {
  resource?: string;
}

export function UserProfileList({ resource = 'user_profiles' }: UserProfileListProps) {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [searchField, setSearchField] = useState<string>('all');
  const { show } = useNavigation();
  const { resource: resourceInfo } = useResource();

  // Refine useTable 훅 사용
  const { tableProps, setFilters } = useTable<UserProfile>({
    resource,
    syncWithLocation: true,
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
    },
    onSearch: (values) => {
      const filters: CrudFilters = [];
      
      if (searchTerm) {
        if (searchField === 'all' || searchField === 'nickname') {
          filters.push({
            field: 'nickname',
            operator: 'contains',
            value: searchTerm,
          });
        }
        
        if (searchField === 'all' || searchField === 'email') {
          filters.push({
            field: 'email',
            operator: 'contains',
            value: searchTerm,
          });
        }
        
        if (searchField === 'all' || searchField === 'id') {
          // UUID 타입에는 contains 연산자를 사용하지 않고 정확한 값 비교
          // 유효한 UUID 형식인 경우만 검색 필터에 포함
          if (UUID_REGEX.test(searchTerm)) {
            filters.push({
              field: 'id',
              operator: 'eq',
              value: searchTerm,
            });
          }
        }
      }
      
      return filters;
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
      ],
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
    
    const filters: CrudFilters = [];
    
    if (value) {
      if (searchField === 'all' || searchField === 'nickname') {
        filters.push({
          field: 'nickname',
          operator: 'contains',
          value,
        });
      }
      
      if (searchField === 'all' || searchField === 'email') {
        filters.push({
          field: 'email',
          operator: 'contains',
          value,
        });
      }
      
      if (searchField === 'all' || searchField === 'id') {
        // UUID 타입에는 contains 연산자를 사용하지 않고 정확한 값 비교
        // 유효한 UUID 형식인 경우만 검색 필터에 포함
        if (UUID_REGEX.test(value)) {
          filters.push({
            field: 'id',
            operator: 'eq',
            value,
          });
        } else if (searchField === 'id' && value) {
          // ID 필드만 선택된 경우 유효하지 않은 UUID 형식이면 경고 메시지 표시
          message.warning('UUID 형식이 올바르지 않습니다. 예: 123e4567-e89b-12d3-a456-426614174000');
          return; // 검색 중단
        }
      }
    }
    
    setFilters(filters, 'replace');
  };

  const handleFieldChange = (value: string) => {
    setSearchField(value);
    if (searchTerm) {
      // 검색 필드가 변경되면 검색 다시 실행
      handleSearch(searchTerm);
    }
  };

  return (
    <List 
      breadcrumb={false}
      headerButtons={<CreateButton />}
      title="유저관리"
    >
      <Space style={{ marginBottom: 16 }}>
        <Select
          defaultValue="all"
          style={{ width: 120 }}
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
          style={{ width: 300 }}
          allowClear
          defaultValue={searchTerm}
        />
      </Space>

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
          render={(avatar_url, record: UserProfile) => (
            <Space>
              <Avatar src={avatar_url} size="large" />
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
          render={(created_at) => (
            <DateField value={created_at} format="YYYY-MM-DD HH:mm:ss" />
          )}
        />
        
        <Table.Column
          dataIndex="deleted_at"
          title="상태"
          render={(deleted_at) => (
            <Tag color={deleted_at ? 'error' : 'success'}>
              {deleted_at ? '탈퇴' : '활성'}
            </Tag>
          )}
        />
      </Table>
    </List>
  );
} 