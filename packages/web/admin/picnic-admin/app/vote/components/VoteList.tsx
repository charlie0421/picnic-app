'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { CrudFilters, useNavigation } from '@refinedev/core';
import { Space, Table, Select, Tag } from 'antd';
import React from 'react';
import { Image } from 'antd';

import {
  VOTE_CATEGORIES,
  VOTE_STATUS,
  STATUS_TAG_COLORS,
  STATUS_COLORS,
  getVoteStatus,
  type VoteStatus,
  type VoteCategory,
  type VoteRecord,
} from '@/lib/vote';
import { formatDate } from '@/lib/date';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import { getCdnImageUrl } from '@/lib/image';

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
    <List 
      breadcrumb={false}
      headerButtons={<CreateButton />}
    >
      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 160, maxWidth: '100%' }}
          placeholder='카테고리 선택'
          allowClear
          options={VOTE_CATEGORIES}
          value={categoryFilter}
          onChange={handleCategoryChange}
        />
        <Select
          style={{ width: 120, maxWidth: '100%' }}
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

      <div style={{ width: '100%', overflowX: 'auto' }}>
        <Table
          {...tableProps}
          rowKey='id'
          scroll={{ x: 'max-content' }}
          size="small"
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
            align='center'
            ellipsis={{ showTitle: true }}
            render={(value: any) => <MultiLanguageDisplay languages={['ko']} value={value} />}
          />
          <Table.Column
            dataIndex='vote_category'
            title='카테고리'
            align='center'
            width={100}
            responsive={['sm']}
            render={(value: VoteCategory) => {
              const category = VOTE_CATEGORIES?.find((c) => c.value === value);
              return category?.label || value;
            }}
          />
          <Table.Column
            dataIndex='main_image'
            title='메인 이미지'
            align='center'
            width={130}
            responsive={['md']}
            render={(value: string | undefined) => {
              if (!value) return '-';
              return (
              <Image
                src={getCdnImageUrl(value, 100)}
                alt='메인 이미지'
                width={100}
                height={60}
                preview={false}
                />
              );
            }}
          />
          <Table.Column
            title='상태'
            align='center'
            width={100}
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
            title='투표 노출'
            align='center'
            width={160}
            responsive={['md']}
            render={(_, record: VoteRecord) => {
              if (!record.visible_at) return '-';
              return `${formatDate(record.visible_at, 'date')}`;  
            }}
          />

          <Table.Column
            title='투표 기간'
            align='center'
            width={180}
            responsive={['lg']}
            render={(_, record: VoteRecord) => {
              if (!record.start_at || !record.stop_at) return '-';
              return (
                <Space direction="vertical" size="small">
                  <DateField value={record.start_at} format='YYYY-MM-DD' />
                  |
                  <DateField value={record.stop_at} format='YYYY-MM-DD' />
                </Space>
              )
            }}
          />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title={'생성일/수정일'}
            align='center'
            width={140}
            responsive={['xl']}
            render={(_, record: any) => (
              <Space direction="vertical" size="small">
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