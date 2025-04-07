'use client';

import {
  DateField,
  Show,
  TextField,
  EditButton,
  DeleteButton,
} from '@refinedev/antd';
import { useShow, useMany, useNavigation } from '@refinedev/core';
import { Typography, Image, Divider, theme, Grid, Space, Button } from 'antd';
import { ArtistGroup, Artist } from '@/types/artist';
import { getImageUrl } from '@/utils/image';
import { useParams } from 'next/navigation';
import { dataProvider } from '@/providers/data-provider';
import { useState, useEffect } from 'react';
import {
  UserOutlined,
  TeamOutlined,
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import { COLORS } from '@/utils/theme';
import dayjs from 'dayjs';
import { Skeleton, Tooltip, Tag, Descriptions } from 'antd';
import ArtistCard from '@/components/artist/ArtistCard';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title } = Typography;
const { useBreakpoint } = Grid;

// 카드 스타일 생성 함수
const getCardStyle = (token: any, isMobile = false, extraStyles = {}) => {
  const shadowColor = `rgba(0, 0, 0, ${
    token.colorBgMask === '#000000' ? 0.15 : 0.08
  })`;

  return {
    background: token.colorBgContainer,
    borderRadius: '12px',
    boxShadow: `0 4px 12px ${shadowColor}`,
    padding: '24px',
    border: `1px solid ${token.colorBorderSecondary}`,
    color: token.colorText,
    marginBottom: isMobile ? '20px' : '0',
    ...extraStyles,
  };
};

// 섹션 스타일 생성 함수
const getSectionStyle = (token: any, extraStyles = {}) => {
  return {
    marginBottom: '16px',
    background: token.colorBgElevated,
    padding: '12px',
    borderRadius: '8px',
    border: `1px solid ${token.colorBorderSecondary}`,
    ...extraStyles,
  };
};

// 섹션 헤더 스타일 생성 함수
const getSectionHeaderStyle = (token: any, extraStyles = {}) => {
  return {
    marginBottom: '20px',
    ...extraStyles,
  };
};

// 제목 스타일 생성 함수
const getTitleStyle = (token: any, extraStyles = {}) => {
  return {
    margin: '0 0 8px 0',
    color: COLORS.primary,
    ...extraStyles,
  };
};

// 이미지 스타일 생성 함수
const getImageStyle = (token: any, extraStyles = {}): React.CSSProperties => {
  const shadowColor = `rgba(0, 0, 0, ${
    token.colorBgMask === '#000000' ? 0.15 : 0.08
  })`;

  return {
    maxWidth: '100%',
    objectFit: 'contain' as const,
    borderRadius: '8px',
    boxShadow: `0 2px 8px ${shadowColor}`,
    border: `1px solid ${token.colorBorderSecondary}`,
    ...extraStyles,
  };
};

const headerTitleStyle = {
  margin: 0,
  color: COLORS.primary,
  fontWeight: 'bold',
};

export default function ArtistGroupShow() {
  // URL에서 id 파라미터 가져오기
  const params = useParams();
  const id = params?.id?.toString();
  const { token } = theme.useToken();
  const [artists, setArtists] = useState<Artist[]>([]);
  const screens = useBreakpoint();
  const isMobile = !screens.md;

  const { queryResult } = useShow<ArtistGroup>({
    resource: 'artist_group',
    id: id,
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  // 아티스트 리스트 가져오기
  const { data: artistsData, isLoading: artistsIsLoading } = useMany({
    resource: 'artist',
    ids: [], // 비어있지만 useMany 훅을 준비함
    queryOptions: {
      enabled: !!record?.id,
      queryFn: async () => {
        const { data } = await dataProvider.getList({
          resource: 'artist',
          filters: [
            {
              field: 'group_id',
              operator: 'eq',
              value: record?.id,
            },
          ],
          meta: {
            select: '*',
          },
        });

        return { data: data || [] };
      },
    },
  });

  // 아티스트 데이터 설정
  useEffect(() => {
    if (artistsData?.data) {
      setArtists(artistsData.data as Artist[]);
    }
  }, [artistsData]);

  const { show, edit, list } = useNavigation();

  if (isLoading) {
    return (
      <AuthorizePage resource='artist_group' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='artist_group' action='show'>
      <Show
        title={
          <Space>
            <Button
              icon={<ArrowLeftOutlined />}
              onClick={() => list('artist-group')}
            >
              목록으로
            </Button>
            <Title level={5} style={{ margin: 0 }}>
              아티스트 그룹 상세
            </Title>
          </Space>
        }
        headerButtons={
          <Space>
            <EditButton
              icon={<EditOutlined />}
              resource='artist_group'
              recordItemId={record?.id}
            />
            <DeleteButton
              icon={<DeleteOutlined />}
              resource='artist_group'
              recordItemId={record?.id}
              onSuccess={() => list('artist-group')}
            />
          </Space>
        }
      >
        <div
          style={{
            display: 'flex',
            flexDirection: isMobile ? 'column' : 'row',
            gap: '16px',
          }}
        >
          {/* 그룹 기본 정보 */}
          <div
            style={{
              flex: 1,
              ...getCardStyle(token, isMobile, {
                paddingRight: isMobile ? '24px' : '44px',
              }),
            }}
          >
            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                기본 정보
              </Title>
            </div>

            <div className='info-section' style={getSectionStyle(token)}>
              <Title level={5} style={getTitleStyle(token)}>
                {'아이디'}
              </Title>
              <TextField value={record?.id} />
            </div>

            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                이름
              </Title>
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'한국어 (🇰🇷)'}
              </Title>
              <TextField value={record?.name?.ko || '-'} />
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'영어 (🇺🇸)'}
              </Title>
              <TextField value={record?.name?.en || '-'} />
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'일본어 (🇯🇵)'}
              </Title>
              <TextField value={record?.name?.ja || '-'} />
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'중국어 (🇨🇳)'}
              </Title>
              <TextField value={record?.name?.zh || '-'} />
            </div>

            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                이미지
              </Title>
            </div>

            <div
              className='info-section'
              style={{
                ...getSectionStyle(token),
                marginTop: '16px',
                textAlign: 'center',
              }}
            >
              {record?.image ? (
                <img
                  src={getImageUrl(record.image)}
                  alt={record?.name?.ko}
                  style={getImageStyle(token, { maxHeight: '300px' })}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    if (e.currentTarget.parentElement) {
                      e.currentTarget.parentElement.innerText = '-';
                    }
                  }}
                />
              ) : (
                <TextField value='-' />
              )}
            </div>

            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                데뷔일
              </Title>
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              {record?.debut_date ? (
                <TextField
                  value={dayjs(record.debut_date).format('YYYY년 MM월 DD일')}
                />
              ) : (
                <TextField value='-' />
              )}
            </div>

            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                등록일
              </Title>
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              {record?.created_at ? (
                <DateField
                  value={record.created_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              ) : (
                <TextField value='-' />
              )}
            </div>
          </div>

          {/* 멤버 정보 */}
          <div
            style={{
              flex: 1,
              ...getCardStyle(token, isMobile),
            }}
          >
            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                멤버 정보
              </Title>
            </div>

            {artistsIsLoading ? (
              <Skeleton active paragraph={{ rows: 5 }} />
            ) : artists && artists.length > 0 ? (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
                  gap: '16px',
                }}
              >
                {artists.map((artist: Artist) => (
                  <ArtistCard
                    key={artist.id}
                    artist={artist}
                    onClick={() => {
                      show('artist', artist.id);
                    }}
                  />
                ))}
              </div>
            ) : (
              <div style={getSectionStyle(token)}>
                <p style={{ textAlign: 'center' }}>등록된 멤버가 없습니다.</p>
              </div>
            )}
          </div>
        </div>
      </Show>
    </AuthorizePage>
  );
}
