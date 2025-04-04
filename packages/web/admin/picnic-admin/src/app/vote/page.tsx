'use client';

import {
  DateField,
  DeleteButton,
  EditButton,
  List,
  MarkdownField,
  ShowButton,
  useTable,
  CreateButton,
} from '@refinedev/antd';
import {
  type BaseRecord,
  useMany,
  CrudFilters,
  CrudFilter,
  useNavigation,
} from '@refinedev/core';
import { Space, Table, Select, Tag, Row, Col } from 'antd';
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
import { formatDate, DATE_FORMATS } from '@/utils/date';
import MultiLanguageDisplay from '@/components/common/MultiLanguageDisplay';
import TableImage from '@/components/common/TableImage';

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
    <List headerButtons={<CreateButton />}>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={24} md={24}>
          <Space wrap style={{ marginBottom: 16 }}>
            <Select
              style={{ width: '100%', minWidth: 120 }}
              placeholder='카테고리 선택'
              allowClear
              options={VOTE_CATEGORIES}
              value={categoryFilter}
              onChange={handleCategoryChange}
            />
            <Select
              style={{ width: '100%', minWidth: 120 }}
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
        </Col>
      </Row>

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
        style={{
          color: 'inherit',
          width: '100%',
          overflowX: 'auto',
        }}
      >
        <Table.Column
          dataIndex='id'
          title='ID'
          className='text-inherit'
          width={60}
        />
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
