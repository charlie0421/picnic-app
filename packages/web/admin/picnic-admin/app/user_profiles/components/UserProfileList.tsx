'use client';

import { CreateButton, DateField, List } from '@refinedev/antd';
import { Space, Tag, Avatar, Switch, message } from 'antd';
import type { SortOrder } from 'antd/es/table/interface';
import type { Breakpoint } from 'antd/es/_util/responsiveObserver';
import { useNavigation, CrudFilters } from '@refinedev/core';
import { UserProfile } from '../../../lib/types/user_profiles';
import { DataTable } from '../../components/common/DataTable';

// UUID 유효성 검사 정규식
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface UserProfileListProps {
  resource?: string;
}

export function UserProfileList({
  resource = 'user_profiles',
}: UserProfileListProps) {
  const { show } = useNavigation();

  // 검색 필터 생성 함수
  const createSearchFilters = (value: string, field: string): CrudFilters => {
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
        message.warning(
          'UUID 형식이 올바르지 않습니다. 예: 123e4567-e89b-12d3-a456-426614174000',
        );
        return [];
      }
    }

    return filters;
  };

  const columns = [
    {
      dataIndex: 'id',
      title: 'ID',
      width: 80,
      ellipsis: true,
      render: (value: string) => value && value.substring(0, 8) + '...',
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
    },
    {
      dataIndex: 'avatar_url',
      title: '프로필',
      width: 160,
      render: (avatar_url: string, record: UserProfile) => (
        <Space>
          <Avatar src={avatar_url} size='small' />
          <div>
            <div>{record.nickname || '-'}</div>
            <div style={{ fontSize: '12px', color: '#666' }}>
              {record.email || '-'}
            </div>
          </div>
        </Space>
      ),
    },
    {
      dataIndex: 'star_candy',
      title: '스타캔디',
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
      width: 120,
      responsive: ['sm' as Breakpoint],
      render: (star_candy: number, record: UserProfile) => (
        <Space>
          <span>{star_candy}</span>
          {record.star_candy_bonus > 0 && (
            <Tag color='green'>+{record.star_candy_bonus}</Tag>
          )}
        </Space>
      ),
    },
    {
      dataIndex: 'gender',
      title: '성별/나이 공개',
      responsive: ['md' as Breakpoint],
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
      render: (gender: string, record: UserProfile) => (
        <Space>
          <Tag color={gender ? 'blue' : 'default'}>
            {gender || '미설정'}
          </Tag>
          <Space direction='vertical' size={2}>
            <span>
              성별 공개:{' '}
              <Switch
                size='small'
                disabled
                checked={record.open_gender}
              />
            </span>
            <span>
              나이 공개:{' '}
              <Switch size='small' disabled checked={record.open_ages} />
            </span>
          </Space>
        </Space>
      ),
    },
    {
      dataIndex: 'is_admin',
      title: '관리자',
      width: 80,
      responsive: ['lg' as Breakpoint],
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
      render: (is_admin: boolean) => (
        <Tag color={is_admin ? 'red' : 'default'}>
          {is_admin ? '관리자' : '일반'}
        </Tag>
      ),
    },
    {
      dataIndex: 'created_at',
      title: '가입일',
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
      width: 120,
      responsive: ['lg' as Breakpoint],
      render: (created_at: string) => (
        <DateField value={created_at} format='YYYY-MM-DD' />
      ),
    },
    {
      dataIndex: 'deleted_at',
      title: '상태',
      width: 120,
      sorter: true,
      sortDirections: ['ascend', 'descend'] as SortOrder[],
      render: (deleted_at: string) => (
        <Space direction="vertical" size={1}>
          <Tag color={deleted_at ? 'error' : 'success'}>
            {deleted_at ? '탈퇴' : '활성'}
          </Tag>
          {deleted_at && (
            <div style={{ fontSize: '12px', color: '#666' }}>
              <DateField value={deleted_at} format='YYYY-MM-DD HH:mm' />
            </div>
          )}
        </Space>
      ),
    },
  ];

  return (
    <List breadcrumb={false} headerButtons={<CreateButton />} title='유저관리'>
      <DataTable<UserProfile>
        resource={resource}
        columns={columns}
        searchFields={[
          { value: 'nickname', label: '닉네임' },
          { value: 'email', label: '이메일' },
          { value: 'id', label: 'ID' },
        ]}
        createSearchFilters={createSearchFilters}
      />
    </List>
  );
}
