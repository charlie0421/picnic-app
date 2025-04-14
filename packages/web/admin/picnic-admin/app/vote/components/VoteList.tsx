'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { CrudFilters, useNavigation, useMany, useList } from '@refinedev/core';
import { Space, Table, Select, Tag, Tooltip, Badge, Avatar } from 'antd';
import React, { useEffect, useState } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { Image } from 'antd';
import { GiftOutlined } from '@ant-design/icons';

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

// 상수 확장
const FILTER_STATUS = {
  ALL: 'all',
  ...VOTE_STATUS,
};

type FilterStatusType = typeof FILTER_STATUS[keyof typeof FILTER_STATUS];

// 상수 확장
const FILTER_CATEGORY = {
  ALL: 'all',
  // 기존 카테고리는 VOTE_CATEGORIES 배열에서 사용
};

type FilterCategoryType = typeof FILTER_CATEGORY['ALL'] | VoteCategory;

export default function VoteList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  
  // URL에서 파라미터 가져오기
  const urlCategory = searchParams.get('category') as FilterCategoryType || FILTER_CATEGORY.ALL;
  const urlStatus = searchParams.get('status') as FilterStatusType || FILTER_STATUS.ALL;
  
  const [categoryFilter, setCategoryFilter] =
    React.useState<FilterCategoryType>(urlCategory);
  const [statusFilter, setStatusFilter] =
    React.useState<FilterStatusType>(urlStatus);
  const [filteredData, setFilteredData] = useState<VoteRecord[]>([]);

  const { show } = useNavigation();

  // 추가: vote_id 목록을 저장할 state
  const [voteIds, setVoteIds] = useState<number[]>([]);
  
  // 추가: vote_reward 데이터를 저장할 state
  const [voteRewardMap, setVoteRewardMap] = useState<Record<number, any[]>>({});

  // URL 파라미터 업데이트
  const updateUrlParams = (params: { category?: FilterCategoryType; status?: FilterStatusType }) => {
    const urlParams = new URLSearchParams(searchParams.toString());
    
    // 카테고리 필터 업데이트
    if (params.category !== undefined) {
      if (params.category === FILTER_CATEGORY.ALL) {
        urlParams.delete('category');
      } else {
        urlParams.set('category', params.category);
      }
    }
    
    // 상태 필터 업데이트
    if (params.status !== undefined) {
      if (params.status === FILTER_STATUS.ALL) {
        urlParams.delete('status');
      } else {
        urlParams.set('status', params.status);
      }
    }
    
    router.push(`${pathname}?${urlParams.toString()}`);
  };

  // 컴포넌트 마운트 시 URL에서 파라미터 복원
  useEffect(() => {
    if (urlCategory !== categoryFilter) {
      setCategoryFilter(urlCategory);
    }
    if (urlStatus !== statusFilter) {
      setStatusFilter(urlStatus);
    }
  }, [urlCategory, urlStatus, categoryFilter, statusFilter]);

  // 필터 체인지 핸들러
  const handleCategoryChange = (value: FilterCategoryType) => {
    setCategoryFilter(value);
    updateUrlParams({ category: value });
  };

  const handleStatusChange = (value: FilterStatusType) => {
    setStatusFilter(value);
    updateUrlParams({ status: value });
  };

  const { tableProps } = useTable<VoteRecord>({
    resource: 'vote',
    syncWithLocation: false, // 동기화를 끄고 수동으로 처리
    sorters: {
      initial: [
        {
          field: 'id',
          order: 'desc',
        },
      ],
    },
    filters: {
      permanent: [
        {
          field: 'deleted_at',
          operator: 'null',
          value: true,
        },
      ],
    },
    meta: {
      select: '*', // vote_reward 관계 제거
    },
    queryOptions: {
      refetchOnWindowFocus: false,
    },
  });

  // 투표 데이터가 로드되면 ID 목록 추출
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      const ids: number[] = [];
      
      // ID가 유효한 숫자인 경우만 추가
      tableProps.dataSource.forEach(vote => {
        if (vote.id !== undefined && typeof vote.id === 'number') {
          ids.push(vote.id);
        }
      });
      
      setVoteIds(ids);
    }
  }, [tableProps.dataSource]);
  
  // vote_reward 데이터 조회
  const { data: voteRewardData } = useList({
    resource: 'vote_reward',
    filters: [
      {
        field: 'vote_id',
        operator: 'in', 
        value: voteIds,
      }
    ],
    meta: {
      select: '*',
    },
    queryOptions: {
      enabled: voteIds.length > 0,
    },
  });

  // reward_id 목록 추출
  const [rewardIds, setRewardIds] = useState<number[]>([]);
  
  useEffect(() => {
    if (voteRewardData && voteRewardData.data) {
      const ids: number[] = [];
      voteRewardData.data.forEach(item => {
        if (item.reward_id && typeof item.reward_id === 'number') {
          // 중복 확인 후 추가
          if (!ids.includes(item.reward_id)) {
            ids.push(item.reward_id);
          }
        }
      });
      setRewardIds(ids);
    }
  }, [voteRewardData]);
  
  // reward 데이터 조회
  const { data: rewardData } = useMany({
    resource: 'reward',
    ids: rewardIds,
    queryOptions: {
      enabled: rewardIds.length > 0,
    },
  });
  
  // vote_reward 데이터 정리
  useEffect(() => {
    console.log('voteRewardData:', voteRewardData);
    console.log('rewardData:', rewardData);
    
    if (voteRewardData?.data && rewardData?.data) {
      // vote_id를 키로 하는 맵 생성
      const rewardMap: Record<number, any[]> = {};
      
      // reward 데이터를 id로 맵핑
      const rewardById: Record<number, any> = {};
      rewardData.data.forEach(reward => {
        if (reward.id && typeof reward.id === 'number') {
          rewardById[reward.id] = reward;
        }
      });
      
      // vote_reward 데이터 처리
      voteRewardData.data.forEach(item => {
        console.log('Processing vote_reward item:', item);
        const voteId = item.vote_id;
        const rewardId = item.reward_id;
        
        if (!rewardMap[voteId]) {
          rewardMap[voteId] = [];
        }
        
        // reward 정보가 있는 경우만 추가
        if (rewardId && rewardById[rewardId]) {
          rewardMap[voteId].push({
            ...item,
            reward: rewardById[rewardId]
          });
        }
      });
      
      console.log('Final rewardMap:', rewardMap);
      setVoteRewardMap(rewardMap);
    }
  }, [voteRewardData, rewardData]);

  // 클라이언트 측 필터링
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      let filtered = [...tableProps.dataSource];
      
      // 카테고리 필터 적용
      if (categoryFilter && categoryFilter !== FILTER_CATEGORY.ALL) {
        filtered = filtered.filter(item => 
          item.vote_category === categoryFilter
        );
      }
      
      // 상태 필터 적용
      if (statusFilter && statusFilter !== FILTER_STATUS.ALL) {
        const now = new Date();
        
        if (statusFilter === VOTE_STATUS.UPCOMING) {
          filtered = filtered.filter(item => {
            if (!item.start_at) return false;
            const startAt = new Date(item.start_at);
            return now < startAt;
          });
        } else if (statusFilter === VOTE_STATUS.ONGOING) {
          filtered = filtered.filter(item => {
            if (!item.start_at || !item.stop_at) return false;
            const startAt = new Date(item.start_at);
            const stopAt = new Date(item.stop_at);
            return now >= startAt && now <= stopAt;
          });
        } else if (statusFilter === VOTE_STATUS.COMPLETED) {
          filtered = filtered.filter(item => {
            if (!item.stop_at) return false;
            const stopAt = new Date(item.stop_at);
            return now > stopAt;
          });
        }
      }
      
      setFilteredData(filtered);
    } else {
      setFilteredData([]);
    }
  }, [tableProps.dataSource, categoryFilter, statusFilter]);
  
  // 필터링된 데이터로 tableProps 수정
  const modifiedTableProps = {
    ...tableProps,
    dataSource: filteredData,
  };

  // 카테고리 옵션 생성
  const categoryOptions = [
    { label: '전체', value: FILTER_CATEGORY.ALL },
    ...(VOTE_CATEGORIES || []),
  ];

  return (
    <List 
      breadcrumb={false}
      headerButtons={<CreateButton />}
    >
      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 160, maxWidth: '100%' }}
          placeholder='카테고리 선택'
          options={categoryOptions}
          value={categoryFilter}
          onChange={handleCategoryChange}
        />
        <Select
          style={{ width: 120, maxWidth: '100%' }}
          placeholder='투표 상태'
          options={[
            { label: '전체', value: FILTER_STATUS.ALL },
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
          {...modifiedTableProps}
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
            width={150}
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
          {/* 연결된 리워드 칼럼 추가 */}
          <Table.Column
            title='리워드'
            align='center'
            width={200}
            render={(_, record: any) => {
              const voteId = record.id;
              const rewards = voteRewardMap[voteId] || [];
              
              // 리워드가 없는 경우
              if (rewards.length === 0) {
                return '-';
              }
              
              // 첫 번째 리워드의 이름 표시
              const firstReward = rewards[0].reward;
              
              return (
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                  {rewards.length > 1 && (
                    <Tag color="#1890ff" style={{ marginBottom: '4px' }}>
                      +{rewards.length - 1}
                    </Tag>
                  )}
                  <span style={{ maxWidth: '140px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    <MultiLanguageDisplay languages={['ko']} value={firstReward.title} />
                  </span>
                </div>
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