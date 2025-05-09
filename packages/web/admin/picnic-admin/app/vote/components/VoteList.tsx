'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
  TagField,
} from '@refinedev/antd';
import { useNavigation, useMany, useList } from '@refinedev/core';
import {
  Space,
  Table,
  Select,
  Tag,
  Avatar,
  Card,
  Typography,
  theme as antdTheme,
  Skeleton,
} from 'antd';
import React, { useEffect, useState } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';

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
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import { getCdnImageUrl } from '@/lib/image';

// 상수 확장
const FILTER_STATUS = {
  ALL: 'all',
  ...VOTE_STATUS,
};

type FilterStatusType = (typeof FILTER_STATUS)[keyof typeof FILTER_STATUS];

// 상수 확장
const FILTER_CATEGORY = {
  ALL: 'all',
  // 기존 카테고리는 VOTE_CATEGORIES 배열에서 사용
};

type FilterCategoryType = (typeof FILTER_CATEGORY)['ALL'] | VoteCategory;

// 영역 필터 상수 추가
const FILTER_AREA = {
  ALL: 'all',
  KPOP: 'kpop',
  MUSICAL: 'musical',
} as const;

type FilterAreaType = (typeof FILTER_AREA)[keyof typeof FILTER_AREA];

// 카테고리에 맞는 한글 이름 반환
const getCategoryName = (category: string) => {
  switch (category) {
    case 'birthday':
      return '생일';
    case 'debut':
      return '데뷔';
    case 'achieve':
      return '누적';
    default:
      return category || '카테고리 없음';
  }
};

const getAreaName = (area: string | undefined) => {
  switch (area) {
    case 'kpop':
      return 'K-POP';
    case 'musical':
      return '뮤지컬';
    default:
      return '영역 없음';
  }
};

/**
 * 투표 카테고리에 따른 컬러 정의
 */
const getCategoryColor = (category: string) => {
  switch (category) {
    case 'birthday':
    case 'DAILY':
      return '#4CAF50';
    case 'debut':
    case 'WEEKLY':
      return '#2196F3';
    case 'achieve':
    case 'MONTHLY':
      return '#9C27B0';
    case 'EVENT':
      return '#FF9800';
    default:
      return '#757575';
  }
};

const getAreaColor = (area: string | undefined) => {
  switch (area) {
    case 'kpop':
      return '#FF1493'; // 핫 핑크
    case 'musical':
      return '#4169E1'; // 로얄 블루
    default:
      return '#8B8B8B'; // 회색
  }
};

export default function VoteList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const { token } = antdTheme.useToken();

  // URL에서 파라미터 가져오기
  const urlCategory =
    (searchParams.get('category') as FilterCategoryType) || FILTER_CATEGORY.ALL;
  const urlStatus =
    (searchParams.get('status') as FilterStatusType) || FILTER_STATUS.ALL;
  const urlArea =
    (searchParams.get('area') as FilterAreaType) || FILTER_AREA.ALL;

  const [categoryFilter, setCategoryFilter] =
    React.useState<FilterCategoryType>(urlCategory);
  const [statusFilter, setStatusFilter] =
    React.useState<FilterStatusType>(urlStatus);
  const [areaFilter, setAreaFilter] = React.useState<FilterAreaType>(urlArea);
  const [filteredData, setFilteredData] = useState<VoteRecord[]>([]);

  const { show, edit } = useNavigation();

  // 추가: vote_id 목록을 저장할 state
  const [voteIds, setVoteIds] = useState<number[]>([]);

  // 추가: vote_reward 데이터를 저장할 state
  const [voteRewardMap, setVoteRewardMap] = useState<Record<number, any[]>>({});

  // URL 파라미터 업데이트
  const updateUrlParams = (params: {
    category?: FilterCategoryType;
    status?: FilterStatusType;
    area?: FilterAreaType;
  }) => {
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

    // 영역 필터 업데이트
    if (params.area !== undefined) {
      if (params.area === FILTER_AREA.ALL) {
        urlParams.delete('area');
      } else {
        urlParams.set('area', params.area);
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
    if (urlArea !== areaFilter) {
      setAreaFilter(urlArea);
    }
  }, [
    urlCategory,
    urlStatus,
    urlArea,
    categoryFilter,
    statusFilter,
    areaFilter,
  ]);

  // 필터 체인지 핸들러
  const handleCategoryChange = (value: FilterCategoryType) => {
    setCategoryFilter(value);
    updateUrlParams({ category: value });
  };

  const handleStatusChange = (value: FilterStatusType) => {
    setStatusFilter(value);
    updateUrlParams({ status: value });
  };

  const handleAreaChange = (value: FilterAreaType) => {
    setAreaFilter(value);
    updateUrlParams({ area: value });
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

  const isLoading = !!tableProps.loading;

  // 투표 데이터가 로드되면 ID 목록 추출
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      const ids: number[] = [];

      // ID가 유효한 숫자인 경우만 추가
      tableProps.dataSource.forEach((vote) => {
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
      },
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
      voteRewardData.data.forEach((item) => {
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
    if (voteRewardData?.data && rewardData?.data) {
      // vote_id를 키로 하는 맵 생성
      const rewardMap: Record<number, any[]> = {};

      // reward 데이터를 id로 맵핑
      const rewardById: Record<number, any> = {};
      rewardData.data.forEach((reward) => {
        if (reward.id && typeof reward.id === 'number') {
          rewardById[reward.id] = reward;
        }
      });

      // vote_reward 데이터 처리
      voteRewardData.data.forEach((item) => {
        const voteId = item.vote_id;
        const rewardId = item.reward_id;

        if (!rewardMap[voteId]) {
          rewardMap[voteId] = [];
        }

        // reward 정보가 있는 경우만 추가
        if (rewardId && rewardById[rewardId]) {
          rewardMap[voteId].push({
            ...item,
            reward: rewardById[rewardId],
          });
        }
      });

      setVoteRewardMap(rewardMap);
    }
  }, [voteRewardData, rewardData]);

  // 클라이언트 측 필터링
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      let filtered = [...tableProps.dataSource];

      // 카테고리 필터 적용
      if (categoryFilter !== FILTER_CATEGORY.ALL) {
        const categoryField = 'vote_category';
        filtered = filtered.filter(
          (item) =>
            item[categoryField] === categoryFilter ||
            item.category === categoryFilter,
        );
      }

      // 상태 필터 적용
      if (statusFilter !== FILTER_STATUS.ALL) {
        filtered = filtered.filter((item) => {
          const status = getVoteStatus(item.start_at, item.stop_at);
          return status === statusFilter;
        });
      }

      // 영역 필터 적용
      if (areaFilter !== FILTER_AREA.ALL) {
        filtered = filtered.filter((item) => item.area === areaFilter);
      }

      setFilteredData(filtered);
    } else {
      setFilteredData([]);
    }
  }, [tableProps.dataSource, categoryFilter, statusFilter, areaFilter]);

  // 테이블 데이터 설정
  const dataSource = React.useMemo(() => {
    return filteredData.map((item: VoteRecord) => {
      // 투표 상태 계산
      const status = getVoteStatus(item.start_at, item.stop_at);

      // vote_reward 데이터가 있는지 확인
      const id = item.id ? Number(item.id) : 0;
      const hasRewards = id > 0 && voteRewardMap[id]?.length > 0;

      return {
        ...item,
        status,
        hasRewards,
      };
    });
  }, [filteredData, voteRewardMap]);

  // Empty State 함수
  const renderEmptyState = () => (
    <Card
      style={{
        textAlign: 'center',
        padding: '40px 0',
        background: token.colorBgContainer,
        border: `1px solid ${token.colorBorderSecondary}`,
        borderRadius: token.borderRadiusLG,
        boxShadow: `0 2px 8px ${token.colorBgContainerDisabled}`,
      }}
    >
      <Typography.Title level={4} style={{ color: token.colorTextSecondary }}>
        필터 조건에 맞는 투표가 없습니다
      </Typography.Title>
      <Typography.Paragraph style={{ color: token.colorTextSecondary }}>
        다른 필터 조건을 선택하거나 새 투표를 생성해보세요
      </Typography.Paragraph>
      <CreateButton type='primary' size='large'>
        투표 생성하기
      </CreateButton>
    </Card>
  );

  return (
    <List
      headerButtons={[
        <CreateButton key='create' type='primary'>
          투표 생성
        </CreateButton>,
      ]}
    >
      {/* 필터 컴포넌트 */}
      <Card
        size='small'
        style={{
          marginBottom: '16px',
          background: token.colorBgContainer,
          borderRadius: token.borderRadiusLG,
        }}
      >
        <Space wrap style={{ padding: '8px' }}>
          <Space>
            <Typography.Text strong style={{ color: token.colorTextSecondary }}>
              카테고리:
            </Typography.Text>
            <Select
              value={categoryFilter}
              onChange={handleCategoryChange}
              style={{ width: 120 }}
              options={[
                { label: '전체', value: FILTER_CATEGORY.ALL },
                ...(VOTE_CATEGORIES || []),
              ]}
              disabled={isLoading}
            />
          </Space>
          <Space>
            <Typography.Text strong style={{ color: token.colorTextSecondary }}>
              상태:
            </Typography.Text>
            <Select
              value={statusFilter}
              onChange={handleStatusChange}
              style={{ width: 120 }}
              options={[
                { label: '전체', value: FILTER_STATUS.ALL },
                { label: '예정됨', value: VOTE_STATUS.UPCOMING },
                { label: '진행 중', value: VOTE_STATUS.ONGOING },
                { label: '종료됨', value: VOTE_STATUS.COMPLETED },
              ]}
              disabled={isLoading}
            />
          </Space>
          <Space>
            <Typography.Text strong style={{ color: token.colorTextSecondary }}>
              영역:
            </Typography.Text>
            <Select
              value={areaFilter}
              onChange={handleAreaChange}
              style={{ width: 120 }}
              options={[
                { label: '전체', value: FILTER_AREA.ALL },
                { label: 'K-POP', value: FILTER_AREA.KPOP },
                { label: '뮤지컬', value: FILTER_AREA.MUSICAL },
              ]}
              disabled={isLoading}
            />
          </Space>
        </Space>
      </Card>

      {isLoading ? (
        <Card>
          <Skeleton active paragraph={{ rows: 10 }} />
        </Card>
      ) : filteredData.length === 0 ? (
        renderEmptyState()
      ) : (
        <Table
          {...tableProps}
          dataSource={dataSource}
          rowKey='id'
          style={{
            background: token.colorBgContainer,
            borderRadius: token.borderRadiusLG,
            overflow: 'hidden',
          }}
          onRow={(record) => ({
            onClick: () => {
              if (record.id) {
                show('vote', record.id);
              }
            },
            style: { cursor: 'pointer' },
          })}
        >
          <Table.Column
            title='ID'
            dataIndex='id'
            key='id'
            sorter={(a, b) => a.id - b.id}
            render={(value) => (
              <Typography.Text strong style={{ color: token.colorPrimary }}>
                {value}
              </Typography.Text>
            )}
          />

          <Table.Column
            title='썸네일'
            dataIndex='main_image'
            key='main_image'
            render={(value) =>
              value ? (
                <Avatar
                  src={getCdnImageUrl(value)}
                  shape='square'
                  size={48}
                  style={{
                    borderRadius: token.borderRadiusSM,
                    border: `1px solid ${token.colorBorderSecondary}`,
                  }}
                />
              ) : (
                <Avatar
                  shape='square'
                  size={48}
                  style={{
                    background: token.colorFillTertiary,
                    color: token.colorTextSecondary,
                    borderRadius: token.borderRadiusSM,
                  }}
                >
                  이미지 없음
                </Avatar>
              )
            }
          />

          <Table.Column
            title='제목'
            dataIndex='title'
            key='title'
            render={(value) => (
              <MultiLanguageDisplay
                value={value}
                languages={['ko']}
                style={{ fontWeight: 'bold' }}
              />
            )}
            sorter={(a, b) => {
              const titleA = a.title?.ko || '';
              const titleB = b.title?.ko || '';
              return titleA.localeCompare(titleB);
            }}
          />

          <Table.Column
            title='카테고리'
            dataIndex='vote_category'
            key='vote_category'
            render={(value, record: any) => {
              const category = value || record.category;
              return (
                <TagField
                  value={getCategoryName(category)}
                  color={getCategoryColor(category)}
                />
              );
            }}
          />

          <Table.Column
            title='영역'
            dataIndex='area'
            render={(area) => (
              <Tag
                color={getAreaColor(area)}
                style={{ fontSize: '14px', padding: '4px 8px' }}
              >
                {getAreaName(area)}
              </Tag>
            )}
          />

          <Table.Column
            title='상태'
            dataIndex='status'
            key='status'
            render={(value: VoteStatus) => (
              <TagField
                value={
                  value === VOTE_STATUS.UPCOMING
                    ? '예정됨'
                    : value === VOTE_STATUS.ONGOING
                    ? '진행 중'
                    : '종료됨'
                }
                color={STATUS_TAG_COLORS[value]}
              />
            )}
            sorter={(a, b) => {
              const statusOrder: Record<string, number> = {
                [VOTE_STATUS.UPCOMING]: 1,
                [VOTE_STATUS.ONGOING]: 2,
                [VOTE_STATUS.COMPLETED]: 3,
              };
              return statusOrder[a.status] - statusOrder[b.status];
            }}
          />

          <Table.Column
            title='리워드'
            dataIndex='hasRewards'
            key='hasRewards'
            render={(value, record: any) => {
              const rewardRecords = voteRewardMap[record.id as number] || [];

              if (rewardRecords.length === 0) {
                return <Tag color='default'>없음</Tag>;
              }

              return (
                <Space
                  direction='vertical'
                  size='small'
                  style={{ width: '100%' }}
                >
                  <div
                    style={{ maxWidth: 150, maxHeight: 48, overflow: 'hidden' }}
                  >
                    {rewardRecords.slice(0, 1).map((item, index) => (
                      <Typography.Text
                        key={index}
                        ellipsis={{
                          tooltip:
                            item.reward?.title?.ko ||
                            `리워드 #${item.reward_id}`,
                        }}
                        style={{
                          display: 'block',
                          fontSize: '12px',
                          color: token.colorTextSecondary,
                          cursor: 'pointer',
                        }}
                      >
                        {item.reward?.title?.ko || `리워드 #${item.reward_id}`}
                      </Typography.Text>
                    ))}
                    {rewardRecords.length > 1 && (
                      <Typography.Text
                        style={{
                          display: 'block',
                          fontSize: '12px',
                          color: token.colorTextSecondary,
                          fontStyle: 'italic',
                        }}
                      >
                        외 {rewardRecords.length - 1}개...
                      </Typography.Text>
                    )}
                  </div>
                </Space>
              );
            }}
          />

          <Table.Column
            title='투표 시작일'
            dataIndex='start_at'
            key='start_at'
            render={(value) => (
              <DateField
                value={value}
                format='YYYY-MM-DD HH:mm'
                style={{ color: token.colorTextSecondary }}
              />
            )}
            sorter={(a, b) => {
              const dateA = a.start_at ? new Date(a.start_at).getTime() : 0;
              const dateB = b.start_at ? new Date(b.start_at).getTime() : 0;
              return dateA - dateB;
            }}
          />

          <Table.Column
            title='투표 종료일'
            dataIndex='stop_at'
            key='stop_at'
            render={(value) => (
              <DateField
                value={value}
                format='YYYY-MM-DD HH:mm'
                style={{ color: token.colorTextSecondary }}
              />
            )}
            sorter={(a, b) => {
              const dateA = a.stop_at ? new Date(a.stop_at).getTime() : 0;
              const dateB = b.stop_at ? new Date(b.stop_at).getTime() : 0;
              return dateA - dateB;
            }}
          />
        </Table>
      )}
    </List>
  );
}
