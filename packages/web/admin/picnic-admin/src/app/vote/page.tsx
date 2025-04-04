'use client';

import {
  List,
  useTable,
  DateField,
  ShowButton,
  EditButton,
  DeleteButton,
  CreateButton,
} from '@refinedev/antd';
import { CrudFilters, useNavigation } from '@refinedev/core';
import { Space, Table, Select, Tag } from 'antd';
import React from 'react';

import {
  VOTE_CATEGORIES,
  VOTE_STATUS,
  STATUS_TAG_COLORS,
  STATUS_COLORS,
  getVoteStatus,
  type VoteStatus,
  type VoteCategory,
  type VoteRecord,
} from '@/utils/vote';
import { formatDate } from '@/utils/date';
import MultiLanguageDisplay from '@/components/common/MultiLanguageDisplay';
import TableImage from '@/components/common/TableImage';

export default function VoteList() {
  const [categoryFilter, setCategoryFilter] =
    React.useState<VoteCategory | null>(null);
  const [statusFilter, setStatusFilter] = React.useState<VoteStatus | null>(
    null,
  );

  const { show } = useNavigation();

  // 필터 체인지 핸들러
  const handleCategoryChange = (value: VoteCategory | null) => {
    setCategoryFilter(value);
  };

  const handleStatusChange = (value: VoteStatus | null) => {
    setStatusFilter(value);
  };

  const { tableProps } = useTable<VoteRecord>({
    filters: {
      permanent: [
        {
          field: 'deleted_at',
          operator: 'null',
          value: true,
        },
      ],
      initial: React.useMemo(() => {
        const filters: CrudFilters = [];

        // 카테고리 필터 추가
        if (categoryFilter) {
          filters.push({
            field: 'vote_category',
            operator: 'eq',
            value: categoryFilter,
          });
        }

        // 상태 필터 추가
        const now = new Date().toISOString();
        if (statusFilter) {
          if (statusFilter === VOTE_STATUS.UPCOMING) {
            filters.push({
              operator: 'gt',
              field: 'start_at',
              value: now,
            });
          } else if (statusFilter === VOTE_STATUS.ONGOING) {
            filters.push({
              operator: 'lte',
              field: 'start_at',
              value: now,
            });
            filters.push({
              operator: 'gte',
              field: 'stop_at',
              value: now,
            });
          } else if (statusFilter === VOTE_STATUS.COMPLETED) {
            filters.push({
              operator: 'lt',
              field: 'stop_at',
              value: now,
            });
          }
        }

        return filters;
      }, [categoryFilter, statusFilter]),
    },
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
    queryOptions: {
      refetchOnWindowFocus: false,
    },
  });

  return (
    <List headerButtons={<CreateButton />}>
      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 160 }}
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
        scroll={{ x: 'max-content' }}
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
        pagination={{
          ...tableProps.pagination,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50'],
          showTotal: (total) => `총 ${total}개 항목`,
        }}
      >
        <Table.Column dataIndex='id' title='ID' width={60} />
        <Table.Column
          dataIndex='title'
          title={'제목'}
          render={(value: any) => <MultiLanguageDisplay value={value} />}
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
          dataIndex='main_image'
          title='메인 이미지'
          render={(value: string | undefined) => (
            <TableImage
              src={value}
              alt='메인 이미지'
              width={120}
              height={80}
              objectFit='contain'
            />
          )}
        />
        <Table.Column
          title='상태'
          render={(_, record: VoteRecord) => {
            const status = getVoteStatus(record.start_at, record.stop_at);
            let label = '';
            if (status === VOTE_STATUS.UPCOMING) label = '투표 예정';
            else if (status === VOTE_STATUS.ONGOING) label = '투표 중';
            else if (status === VOTE_STATUS.COMPLETED) label = '투표 완료';

            return (
              <Tag color={STATUS_TAG_COLORS[status]} key={status}>
                {label}
              </Tag>
            );
          }}
        />
        <Table.Column
          title='투표 기간'
          render={(_, record: VoteRecord) => {
            if (!record.start_at || !record.stop_at) return '-';
            return `${formatDate(record.start_at, 'datetime')} ~ ${formatDate(
              record.stop_at,
              'datetime',
            )}`;
          }}
        />
        <Table.Column
          dataIndex={['created_at']}
          title={'생성일'}
          render={(value: any) => (
            <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
          )}
        />
      </Table>
    </List>
  );
}
