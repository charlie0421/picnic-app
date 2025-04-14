'use client';

import React, { useEffect, useState } from 'react';
import { useMediaQuery } from 'react-responsive';
import {
  useNavigation,
  useShow,
  useOne,
  useList,
  useMany,
} from '@refinedev/core';
import { getCdnImageUrl } from '@/lib/image';
import { VoteRecord, VOTE_STATUS, getVoteStatus } from '@/lib/vote';
import {
  TableProps,
  Alert,
  Space,
  Tag,
  theme,
  Typography,
  Divider,
  Card,
  Button,
  Tooltip,
} from 'antd';
import {
  getCardStyle,
  getSectionStyle,
  getSectionHeaderStyle,
  getTitleStyle,
} from '@/lib/ui';
import {
  CalendarOutlined,
  ClockCircleOutlined,
  UserOutlined,
  PlusOutlined,
  EditOutlined,
} from '@ant-design/icons';
import { TextField, DateField } from '@refinedev/antd';
import dayjs from '@/lib/dayjs';
import { formatDate } from '@/lib/date';
import Image from 'next/image';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import type { ComponentProps } from 'react';
import ArtistCard from '@/app/artist/components/ArtistCard';
import Link from 'next/link';

const { Title, Text } = Typography;

/**
 * 투표 카테고리에 따른 컬러 정의
 */
const getCategoryColor = (category: string) => {
  switch (category) {
    case 'DAILY':
      return '#4CAF50';
    case 'WEEKLY':
      return '#2196F3';
    case 'MONTHLY':
      return '#9C27B0';
    case 'EVENT':
      return '#FF9800';
    default:
      return '#757575';
  }
};

interface VoteDetailProps {
  record?: VoteRecord;
  loading?: boolean;
}

const VoteDetail: React.FC<VoteDetailProps> = ({ record, loading }) => {
  const { token } = theme.useToken();
  const { show } = useNavigation();
  const isMobile = useMediaQuery({ maxWidth: 768 });

  // 연결된 리워드 목록 상태 관리
  const [linkedRewards, setLinkedRewards] = useState<any[]>([]);

  // vote_reward 데이터 조회 - ID 기반 필터링 사용
  const { data: voteRewardData, isLoading: isVoteRewardLoading } = useList({
    resource: 'vote_reward',
    filters: [
      {
        field: 'vote_id',
        operator: 'eq',
        value: record?.id,
      },
    ],
    pagination: {
      pageSize: 100,
    },
    queryOptions: {
      enabled: !!record?.id,
    },
  });

  // 고유한 reward_id 추출
  const rewardIds = React.useMemo(() => {
    if (!voteRewardData?.data || !record?.id) return [];

    // 디버깅을 위한 로그
    console.log('vote_id:', record.id, '타입:', typeof record.id);
    console.log('vote_reward 원본 데이터:', voteRewardData.data);

    // 타입 안전하게 변환하여 필터링
    const numericVoteId =
      typeof record.id === 'string' ? parseInt(record.id, 10) : record.id;

    // vote_id로 필터링
    const filteredData = voteRewardData.data.filter((item) => {
      const itemVoteId =
        typeof item.vote_id === 'string'
          ? parseInt(item.vote_id, 10)
          : item.vote_id;
      return itemVoteId === numericVoteId;
    });

    console.log('vote_id로 필터링된 데이터:', filteredData);

    // 유효한 reward_id만 추출하고 중복 제거
    const uniqueRewardIds: number[] = [];

    filteredData.forEach((item) => {
      const rewardId =
        typeof item.reward_id === 'string'
          ? parseInt(item.reward_id, 10)
          : item.reward_id;
      if (
        !isNaN(rewardId) &&
        rewardId > 0 &&
        !uniqueRewardIds.includes(rewardId)
      ) {
        uniqueRewardIds.push(rewardId);
      }
    });

    console.log('추출된 유효한 리워드 IDs:', uniqueRewardIds);
    return uniqueRewardIds;
  }, [voteRewardData?.data, record?.id]);

  // 리워드 상세 정보 조회 (useMany 사용)
  const { data: rewardsData, isLoading: isRewardsLoading } = useMany({
    resource: 'reward',
    ids: rewardIds,
    queryOptions: {
      enabled: rewardIds.length > 0,
    },
  });

  // 리워드 데이터 처리
  useEffect(() => {
    if (rewardsData?.data) {
      console.log('조회된 리워드 데이터:', rewardsData.data);

      // 리워드 데이터 포맷팅
      const formattedRewards = rewardsData.data.map((reward) => ({
        id: reward.id,
        title: reward.title,
        order: reward.order,
        thumbnail: reward.thumbnail,
      }));

      // 순서 값이 있으면 순서대로 정렬
      const sortedRewards = formattedRewards.sort((a, b) => {
        if (a.order !== undefined && b.order !== undefined) {
          return a.order - b.order;
        }
        return 0;
      });

      console.log('최종 연결된 리워드 목록:', sortedRewards);
      setLinkedRewards(sortedRewards);
    } else {
      setLinkedRewards([]);
    }
  }, [rewardsData]);

  // 투표 항목 정보 조회
  const { data: voteItemsData, isLoading: isVoteItemsLoading } = useList({
    resource: 'vote_item',
    filters: [
      {
        field: 'vote_id',
        operator: 'eq',
        value: record?.id,
      },
    ],
    pagination: {
      pageSize: 100,
    },
    queryOptions: {
      enabled: !!record?.id,
    },
  });

  // 로딩 중이거나 데이터가 없는 경우 처리
  if (loading || !record) {
    return (
      <div style={{ padding: 24 }}>
        <Alert message='투표 정보를 불러오는 중입니다...' type='info' />
      </div>
    );
  }

  // 투표 상태 확인
  const voteStatus = getVoteStatus(record.start_at, record.stop_at);

  return (
    <div style={{ padding: isMobile ? 16 : 24 }}>
      {/* 메인 이미지 */}
      <div
        style={{
          marginBottom: 24,
          position: 'relative',
          width: '100%',
          height: isMobile ? 200 : 300,
        }}
      >
        {record.main_image ? (
          <Image
            src={getCdnImageUrl(record.main_image) || '/images/placeholder.jpg'}
            alt={record.title?.ko || '투표 이미지'}
            fill
            style={{ objectFit: 'cover', borderRadius: 8 }}
          />
        ) : (
          <div
            style={{
              width: '100%',
              height: '100%',
              backgroundColor: '#f5f5f5',
              borderRadius: 8,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              color: '#999',
            }}
          >
            이미지가 없습니다
          </div>
        )}
      </div>

      <Card style={getCardStyle(token)}>
        {/* 기본 정보 */}
        <div style={getSectionStyle(token)}>
          <div style={getSectionHeaderStyle(token)}>
            <Title level={4} style={getTitleStyle(token)}>
              기본 정보
            </Title>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {/* 제목 */}
            <div>
              <Text type='secondary'>제목</Text>
              <div style={{ marginTop: 4 }}>
                <MultiLanguageDisplay
                  value={
                    record.title as ComponentProps<
                      typeof MultiLanguageDisplay
                    >['value']
                  }
                />
              </div>
            </div>

            {/* 카테고리 */}
            <div>
              <Text type='secondary'>카테고리</Text>
              <div style={{ marginTop: 4 }}>
                <Tag color={getCategoryColor(record.category || '')}>
                  {record.category || '카테고리 없음'}
                </Tag>
              </div>
            </div>

            {/* 리워드 연결 */}
            <div>
              <Text type='secondary'>연결된 리워드</Text>
              <div style={{ marginTop: 4 }}>
                {isVoteRewardLoading || isRewardsLoading ? (
                  <Text type='secondary'>리워드 정보를 불러오는 중...</Text>
                ) : linkedRewards.length > 0 ? (
                  <Space wrap>
                    {linkedRewards.map((reward) => (
                      <Tooltip
                        key={reward.id}
                        title={reward.title?.ko || '리워드'}
                      >
                        <Link href={`/reward/show/${reward.id}`}>
                          <Tag color='blue' style={{ cursor: 'pointer' }}>
                            {reward.title?.ko || `리워드 #${reward.id}`}
                          </Tag>
                        </Link>
                      </Tooltip>
                    ))}
                  </Space>
                ) : (
                  <Text type='secondary'>연결된 리워드가 없습니다</Text>
                )}
              </div>
            </div>

            {/* 노출 날짜 */}
            <div>
              <Text type='secondary'>노출 날짜</Text>
              <div style={{ marginTop: 4 }}>
                <Space>
                  {record.visible_at && (
                    <Tag icon={<CalendarOutlined />} color='success'>
                      시작: {formatDate(record.visible_at)}
                    </Tag>
                  )}
                </Space>
              </div>
            </div>

            {/* 투표 기간 */}
            <div>
              <Text type='secondary'>투표 기간</Text>
              <div style={{ marginTop: 4 }}>
                <Space>
                  {record.start_at && (
                    <Tag icon={<ClockCircleOutlined />} color='success'>
                      {formatDate(record.start_at)}
                    </Tag>
                  )}
                  {record.stop_at && (
                    <Tag icon={<ClockCircleOutlined />} color='error'>
                      {formatDate(record.stop_at)}
                    </Tag>
                  )}
                </Space>
              </div>
            </div>

            {/* 투표 상태 */}
            <div>
              <Text type='secondary'>투표 상태</Text>
              <div style={{ marginTop: 4 }}>
                <Tag
                  color={
                    voteStatus === VOTE_STATUS.UPCOMING
                      ? 'blue'
                      : voteStatus === VOTE_STATUS.ONGOING
                      ? 'green'
                      : voteStatus === VOTE_STATUS.COMPLETED
                      ? 'default'
                      : 'default'
                  }
                >
                  {voteStatus === VOTE_STATUS.UPCOMING
                    ? '예정됨'
                    : voteStatus === VOTE_STATUS.ONGOING
                    ? '진행 중'
                    : voteStatus === VOTE_STATUS.COMPLETED
                    ? '종료됨'
                    : '알 수 없음'}
                </Tag>
              </div>
            </div>
          </div>
        </div>

        <Divider />

        {/* 투표 아이템 정보 */}
        <div
          style={{
            ...getCardStyle(token, isMobile, {
              paddingLeft: isMobile ? '24px' : '44px',
            }),
          }}
        >
          <div style={getSectionHeaderStyle(token)}>
            <Title level={4} style={getTitleStyle(token)}>
              투표 아이템
            </Title>
          </div>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: isMobile
                ? 'repeat(auto-fill, minmax(250px, 1fr))'
                : 'repeat(auto-fill, minmax(300px, 1fr))',
              gap: '20px',
              marginTop: '16px',
            }}
          >
            {record?.vote_item
              ?.filter((item: any) => !item.deleted_at)
              ?.sort((a: any, b: any) => b.vote_total - a.vote_total)
              .map((item: any, index: number) => (
                <div
                  key={item.id}
                  style={{
                    position: 'relative',
                  }}
                >
                  {/* 아티스트 카드 컴포넌트 사용 */}
                  <ArtistCard
                    artist={item.artist}
                    onClick={() => show('artists', item.artist?.id)}
                    voteInfo={{
                      rank: index + 1,
                      voteTotal: item.vote_total,
                    }}
                  />

                  <div
                    style={{
                      marginTop: '16px',
                      fontSize: '0.9em',
                      color: token.colorTextSecondary,
                      padding: '10px',
                      background: token.colorBgContainer,
                      borderRadius: '4px',
                      border: `1px solid ${token.colorBorderSecondary}`,
                    }}
                  >
                    <div>생성일: {formatDate(item.created_at, 'datetime')}</div>
                    <div>수정일: {formatDate(item.updated_at, 'datetime')}</div>
                    <div>삭제일: {formatDate(item.deleted_at, 'datetime')}</div>
                    <div
                      style={{
                        marginTop: '10px',
                        color: token.colorTextTertiary,
                      }}
                    >
                      아티스트 ID: {item.artist_id}
                    </div>
                  </div>
                </div>
              ))}
          </div>
        </div>
      </Card>
    </div>
  );
};

export default VoteDetail;
