'use client';

import React, { useEffect, useState, useMemo } from 'react';
import { useMediaQuery } from 'react-responsive';
import { useNavigation, useList, useMany } from '@refinedev/core';
import { getCdnImageUrl } from '@/lib/image';
import { VoteRecord, VOTE_STATUS, getVoteStatus, STATUS_TAG_COLORS } from '@/lib/vote';
import { 
  Space, 
  Tag, 
  Typography, 
  Card, 
  Descriptions,
  Divider,
  theme as antdTheme,
  Empty
} from 'antd';
import {
  CalendarOutlined,
  ClockCircleOutlined,
  UserOutlined,
  GiftOutlined,
  StarTwoTone,
} from '@ant-design/icons';
import { 
  DateField, 
  ImageField,
  TagField,
  NumberField,
} from '@refinedev/antd';
import Link from 'next/link';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import type { ComponentProps } from 'react';
import ArtistCard from '@/app/artist/components/ArtistCard';

const { Title, Text } = Typography;

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

interface VoteDetailProps {
  record?: VoteRecord;
  loading?: boolean;
}

// 투표 항목 카드 컴포넌트 분리 - 렌더링 최적화
const VoteItemCard = React.memo(({ 
  item, 
  index, 
  token, 
  onArtistClick 
}: { 
  item: any; 
  index: number; 
  token: any;
  onArtistClick: (artistId: string | number) => void;
}) => {
  return (
    <Card
      key={item.id || index}
      hoverable
      style={{ 
        height: '100%',
        background: index === 0 
          ? `linear-gradient(to bottom, ${token.colorPrimaryBg}, ${token.colorBgContainer})` 
          : token.colorBgContainer,
        border: `1px solid ${index === 0 ? token.colorPrimaryBorder : token.colorBorderSecondary}`,
        borderRadius: token.borderRadiusLG,
      }}
      onClick={() => {
        if (item.artist_id) {
          onArtistClick(item.artist_id);
        }
      }}
    >
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 16,
          alignItems: 'center',
        }}
      >
        {/* 순위 표시 */}
        {index === 0 && (
          <Tag
            color="gold"
            style={{
              position: 'absolute',
              top: 8,
              right: 8,
              zIndex: 1,
            }}
          >
            1위
          </Tag>
        )}

        {/* 아티스트 정보 */}
        {item.artist && (
          <ArtistCard
            artist={item.artist}
            voteInfo={{ voteTotal: item.vote_total }}
            onClick={() => item.artist_id && onArtistClick(item.artist_id)}
          />
        )}

        {/* 투표 수 */}
        <div style={{ width: '100%', textAlign: 'center' }}>
          <Divider plain style={{ margin: '8px 0' }}>
            <Text strong style={{ color: token.colorTextSecondary }}>
              <UserOutlined /> 투표 수
            </Text>
          </Divider>
          <Title level={4} style={{ margin: 0, color: token.colorPrimary }}>
            <NumberField
              value={item.vote_total || 0}
              options={{ notation: 'compact' }}
              strong
            />
          </Title>
        </div>
      </div>
    </Card>
  );
});

VoteItemCard.displayName = 'VoteItemCard';

const VoteDetail: React.FC<VoteDetailProps> = ({ record, loading }) => {
  const { show } = useNavigation();
  const isMobile = useMediaQuery({ maxWidth: 768 });
  const { token } = antdTheme.useToken();

  // 연결된 리워드 목록 상태 관리
  const [linkedRewards, setLinkedRewards] = useState<any[]>([]);

  // vote_reward 데이터 조회
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
  const rewardIds = useMemo(() => {
    if (!voteRewardData?.data || !record?.id) {
      return [];
    }

    // 만약 데이터가 빈 배열이면 여기서 종료
    if (voteRewardData.data.length === 0) {
      return [];
    }

    // vote_id로 필터링
    const filteredData = voteRewardData.data.filter((item) => {
      const itemVoteId =
        typeof item.vote_id === 'string'
          ? parseInt(item.vote_id, 10)
          : item.vote_id;
      const recordId =
        typeof record.id === 'string' ? parseInt(record.id, 10) : record.id;
      return itemVoteId === recordId;
    });

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

    return uniqueRewardIds;
  }, [voteRewardData?.data, record?.id]);

  // 리워드 상세 정보 조회
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
      // 리워드 데이터 포맷팅 및 정렬
      const formattedRewards = rewardsData.data
        .map((reward) => ({
          id: reward.id,
          title: reward.title,
          order: reward.order,
          thumbnail: reward.thumbnail,
        }))
        .sort((a, b) => {
          if (a.order !== undefined && b.order !== undefined) {
            return a.order - b.order;
          }
          return 0;
        });

      setLinkedRewards(formattedRewards);
    } else {
      setLinkedRewards([]);
    }
  }, [rewardsData]);

  // 리워드 데이터 로딩 상태 및 데이터 여부 확인
  const isRewardLoading = isVoteRewardLoading || (isRewardsLoading && rewardIds.length > 0);
  const hasRewardData = !isVoteRewardLoading && rewardIds.length > 0;

  // 투표 항목 필터링 및 정렬
  const filteredVoteItems = useMemo(() => {
    return record?.vote_item
      ?.filter((item: any) => !item.deleted_at)
      ?.sort((a: any, b: any) => b.vote_total - a.vote_total) || [];
  }, [record?.vote_item]);

  // 투표 상태 확인
  const voteStatus = useMemo(() => {
    return record ? getVoteStatus(record.start_at, record.stop_at) : null;
  }, [record?.start_at, record?.stop_at]);

  // 카테고리 관련 값 추출
  const category = record?.vote_category || record?.category || '';

  // 아티스트 클릭 핸들러
  const handleArtistClick = (artistId: string | number) => {
    if (artistId) {
      show('artist', artistId);
    }
  };

  if (loading || !record) {
    return null; // 로딩은 상위 컴포넌트에서 처리
  }

  return (
    <div className="vote-detail" style={{ color: token.colorText }}>
      {/* 메인 이미지 */}
      {record.main_image && (
        <div style={{ marginBottom: 24 }}>
          <ImageField
            value={getCdnImageUrl(record.main_image) || '/images/placeholder.jpg'}
            title={record.title?.ko || '투표 이미지'}
            width={isMobile ? 300 : 500}
            height={isMobile ? 180 : 250}
            style={{ 
              objectFit: 'cover', 
              borderRadius: 8,
              boxShadow: `0 4px 12px ${token.colorBgContainerDisabled}`
            }}
          />
        </div>
      )}

      {/* 기본 정보 */}
      <Descriptions 
        title={<Title level={4} style={{ color: token.colorText }}>기본 정보</Title>}
        bordered 
        column={1} 
        layout={isMobile ? "vertical" : "horizontal"}
        style={{ 
          marginBottom: 24,
          background: token.colorBgContainer,
          borderRadius: token.borderRadiusLG,
          overflow: 'hidden'
        }}
      >
        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>제목</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          <MultiLanguageDisplay
            value={
              record.title as ComponentProps<
                typeof MultiLanguageDisplay
              >['value']
            }
          />
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>카테고리</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          <TagField value={getCategoryName(category)} color={getCategoryColor(category)} />
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>연결된 리워드</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          {isRewardLoading ? (
            <Text type='secondary'>리워드 정보를 불러오는 중...</Text>
          ) : !hasRewardData ? (
            <Text type='secondary'>연결된 리워드가 없습니다</Text>
          ) : linkedRewards.length > 0 ? (
            <Space wrap>
              {linkedRewards.map((reward) => (
                <Link key={reward.id} href={`/reward/show/${reward.id}`}>
                  <Tag 
                    color='blue' 
                    style={{ 
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 4
                    }}
                  >
                    <GiftOutlined /> {reward.title?.ko || `리워드 #${reward.id}`}
                  </Tag>
                </Link>
              ))}
            </Space>
          ) : (
            <Text type='secondary'>연결된 리워드를 불러올 수 없습니다</Text>
          )}
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>노출 시작일</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          <Space>
            <StarTwoTone style={{ color: token.colorPrimary }} />
            {record.visible_at ? (
              <DateField
                value={record.visible_at}
              format='YYYY-MM-DD HH:mm'
              locales='ko'
            />
          ) : (
            <Text type='secondary'>설정되지 않음</Text>
          )}
          </Space>
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>투표 시작일</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          <Space>
          <CalendarOutlined style={{ color: token.colorPrimary }} />
          {record.start_at ? (
              <DateField
                value={record.start_at}
                format='YYYY-MM-DD HH:mm'
                locales='ko'
              />
            ) : (
              <Text type='secondary'>설정되지 않음</Text>
            )}
          </Space>
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>투표 종료일</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          <Space>
          <CalendarOutlined style={{ color: token.colorWarningTextActive }} />
            {record.stop_at ? (
              <DateField
                value={record.stop_at}
                format='YYYY-MM-DD HH:mm'
                locales='ko'
              />
            ) : (
              <Text type='secondary'>설정되지 않음</Text>
            )}
          </Space>
        </Descriptions.Item>

        <Descriptions.Item 
          label={<Text style={{ color: token.colorTextSecondary }}>투표 상태</Text>}
          labelStyle={{ background: token.colorBgLayout }}
        >
          {voteStatus && (
            <TagField 
              value={
                voteStatus === VOTE_STATUS.UPCOMING
                  ? '예정됨'
                  : voteStatus === VOTE_STATUS.ONGOING
                  ? '진행 중'
                  : '종료됨'
              } 
              color={STATUS_TAG_COLORS[voteStatus]} 
            />
          )}
        </Descriptions.Item>
      </Descriptions>

      {/* 투표 항목 */}
      <Card 
        title={<Title level={4} style={{ margin: 0, color: token.colorText }}>투표 항목</Title>}
        variant="borderless"
        style={{ 
          marginBottom: 24,
          background: token.colorBgContainer,
          borderRadius: token.borderRadiusLG,
          boxShadow: `0 2px 8px ${token.colorBgContainerDisabled}`
        }}
      >
        {filteredVoteItems.length === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="등록된 투표 항목이 없습니다"
            style={{ color: token.colorTextSecondary }}
          />
        ) : (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fill, minmax(280px, 1fr))',
              gap: 16,
              padding: 8,
            }}
          >
            {filteredVoteItems.map((item: any, index: number) => (
              <VoteItemCard 
                key={item.id || index}
                item={item}
                index={index}
                token={token}
                onArtistClick={handleArtistClick}
              />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
};

export default React.memo(VoteDetail);
