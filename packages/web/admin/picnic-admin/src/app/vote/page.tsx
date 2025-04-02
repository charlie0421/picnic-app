'use client';

import {
  DateField,
  DeleteButton,
  EditButton,
  List,
  MarkdownField,
  ShowButton,
  useTable,
} from '@refinedev/antd';
import {
  type BaseRecord,
  useMany,
  CrudFilters,
  CrudFilter,
  useNavigation,
} from '@refinedev/core';
import { Space, Table, Select, Tag } from 'antd';
import dayjs from 'dayjs';
import React from 'react';

// 공통 유틸리티 가져오기
import { getImageUrl } from '@/utils/image';
import {
  VOTE_CATEGORIES,
  VOTE_STATUS,
  STATUS_COLORS,
  STATUS_TAG_COLORS,
  getVoteStatus,
  type VoteStatus,
  type VoteCategory,
  type VoteRecord,
} from '@/utils/vote';

type FilterValue = VoteCategory | null;

export default function VoteList() {
  // 로컬 상태로 필터 관리
  const [categoryFilter, setCategoryFilter] =
    React.useState<VoteCategory | null>(null);
  const [statusFilter, setStatusFilter] = React.useState<VoteStatus | null>(
    null,
  );

  // 페이지 이동을 위한 hook 추가
  const { show } = useNavigation();

  // 실제 필터 적용
  const { tableProps } = useTable<VoteRecord>({
    syncWithLocation: false, // URL 동기화 비활성화
    resource: 'vote',
    meta: {
      select: '*',
    },
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
    filters: {
      permanent: React.useMemo(() => {
        const filters: CrudFilters = [];

        // 삭제된 항목 제외 (삭제일이 null인 항목만 포함)
        filters.push({
          field: 'deleted_at',
          operator: 'null',
          value: true,
        });

        // 카테고리 필터 추가
        if (categoryFilter) {
          filters.push({
            field: 'vote_category',
            operator: 'eq',
            value: categoryFilter,
          });
        }

        // 상태 필터 추가
        const now = dayjs();
        if (statusFilter) {
          if (statusFilter === VOTE_STATUS.UPCOMING) {
            filters.push({
              operator: 'gt',
              field: 'start_at',
              value: now.toISOString(),
            });
          } else if (statusFilter === VOTE_STATUS.ONGOING) {
            filters.push({
              operator: 'lte',
              field: 'start_at',
              value: now.toISOString(),
            });
            filters.push({
              operator: 'gte',
              field: 'stop_at',
              value: now.toISOString(),
            });
          } else if (statusFilter === VOTE_STATUS.COMPLETED) {
            filters.push({
              operator: 'lt',
              field: 'stop_at',
              value: now.toISOString(),
            });
          }
        }

        return filters;
      }, [categoryFilter, statusFilter]),
    },
  });

  // 카테고리 필터 변경 핸들러
  const handleCategoryChange = (value: VoteCategory | null) => {
    setCategoryFilter(value);
  };

  // 상태 필터 변경 핸들러
  const handleStatusChange = (value: VoteStatus | null) => {
    setStatusFilter(value);
  };

  return (
    <List>
      <Space style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 120 }}
          placeholder='카테고리 선택'
          allowClear
          options={VOTE_CATEGORIES}
          value={categoryFilter}
          onChange={handleCategoryChange}
        />
        <Select
          style={{ width: 120 }}
          placeholder='투표 상태'
          allowClear
          options={[
            { label: '투표 예정', value: VOTE_STATUS.UPCOMING },
            { label: '투표 중', value: VOTE_STATUS.ONGOING },
            { label: '투표 완료', value: VOTE_STATUS.COMPLETED },
          ]}
          value={statusFilter}
          onChange={handleStatusChange}
        />
      </Space>

      <Table
        {...tableProps}
        rowKey='id'
        onRow={(record: VoteRecord) => {
          if (!record) return {};
          const status = getVoteStatus(record.start_at, record.stop_at);
          return {
            style: {
              backgroundColor: STATUS_COLORS[status],
              color: 'inherit',
              cursor: 'pointer',
            },
            onClick: () => {
              if (record.id) {
                show('vote', record.id);
              }
            },
          };
        }}
        style={{
          color: 'inherit',
        }}
      >
        <Table.Column dataIndex='id' title='ID' className='text-inherit' />
        <Table.Column
          dataIndex='title'
          title={'제목'}
          render={(value: any) => {
            if (!value) return '-';
            return (
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  color: 'inherit', // 시스템 텍스트 색상 사용
                }}
              >
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold' }}>🇰🇷</span>
                  <span>{value.ko || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold' }}>🇺🇸</span>
                  <span>{value.en || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold' }}>🇯🇵</span>
                  <span>{value.ja || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold' }}>🇨🇳</span>
                  <span>{value.zh || '-'}</span>
                </div>
              </div>
            );
          }}
        />
        <Table.Column
          dataIndex='vote_category'
          title='카테고리'
          render={(value: VoteCategory) => {
            const category = VOTE_CATEGORIES?.find((c) => c.value === value);
            return category?.label || value;
          }}
        />
        <Table.Column
          dataIndex='start_at'
          title='시작일'
          render={(value: string | undefined) =>
            value ? dayjs(value).format('YYYY-MM-DD HH:mm') : '-'
          }
        />
        <Table.Column
          dataIndex='stop_at'
          title='종료일'
          render={(value: string | undefined) =>
            value ? dayjs(value).format('YYYY-MM-DD HH:mm') : '-'
          }
        />
        <Table.Column
          dataIndex='main_image'
          title='메인 이미지'
          render={(value: string | undefined) => {
            if (!value) return '-';
            return (
              <img
                src={getImageUrl(value)}
                alt='메인 이미지'
                style={{
                  width: '80px',
                  height: '80px',
                  objectFit: 'cover',
                  borderRadius: '4px',
                }}
                onError={(e) => {
                  e.currentTarget.style.display = 'none';
                  e.currentTarget.parentElement!.innerText = '-';
                }}
              />
            );
          }}
        />
        <Table.Column
          title='상태'
          render={(_, record: VoteRecord) => {
            const status = getVoteStatus(record.start_at, record.stop_at);
            const statusText = {
              [VOTE_STATUS.UPCOMING]: '투표 예정',
              [VOTE_STATUS.ONGOING]: '투표 중',
              [VOTE_STATUS.COMPLETED]: '투표 완료',
            }[status];

            return <Tag color={STATUS_TAG_COLORS[status]}>{statusText}</Tag>;
          }}
        />
      </Table>
    </List>
  );
}
