'use client';

import { DateField, TextField } from '@refinedev/antd';
import { Typography, theme, Grid, Space, Tag, Divider } from 'antd';
import { ArtistGroup, Artist } from '@/lib/types/artist';
import { getCdnImageUrl } from '@/lib/image';
import { useState, useEffect } from 'react';
import { UserOutlined, TeamOutlined } from '@ant-design/icons';
import { COLORS } from '@/lib/theme';
import dayjs from 'dayjs';
import ArtistCard from '@/app/artist/components/ArtistCard';
import Image from 'next/image';
import { useMany } from '@refinedev/core';
import { dataProvider } from '@/providers/data-provider';

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

interface ArtistGroupDetailProps {
  record?: ArtistGroup;
  loading?: boolean;
}

const ArtistGroupDetail: React.FC<ArtistGroupDetailProps> = ({
  record,
  loading,
}) => {
  const { token } = theme.useToken();
  const [artists, setArtists] = useState<Artist[]>([]);
  const screens = useBreakpoint();
  const isMobile = !screens.md;

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

  if (!record && !loading) {
    return <div>아티스트 그룹 정보를 찾을 수 없습니다.</div>;
  }

  return (
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

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'인도네시아어 (🇮🇩)'}
          </Title>
          <TextField value={record?.name?.id || '-'} />
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
            <Image
              src={getCdnImageUrl(record.image)}
              alt={record?.name?.ko || '그룹 이미지'}
              width={200}
              height={200}
              style={{
                objectFit: 'cover',
                borderRadius: '8px',
              }}
            />
          ) : (
            <TextField value='-' />
          )}
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            <TeamOutlined style={{ marginRight: '8px' }} />
            데뷔일
          </Title>
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <TextField
            value={
              record?.debut_yy
                ? `${record.debut_yy}년 ${record.debut_mm || ''}${
                    record.debut_mm ? '월' : ''
                  } ${record.debut_dd || ''}${record.debut_dd ? '일' : ''}`
                : '-'
            }
          />
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            시스템 정보
          </Title>
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'생성일'}
          </Title>
          <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'수정일'}
          </Title>
          <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </div>
      </div>

      {/* 멤버 목록 */}
      <div
        style={{
          flex: 1,
          ...getCardStyle(token, isMobile, {
            paddingLeft: isMobile ? '24px' : '44px',
          }),
        }}
      >
        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            <UserOutlined style={{ marginRight: '8px' }} />
            멤버 목록
          </Title>
        </div>

        <div style={{ marginTop: '16px' }}>
          {artistsIsLoading ? (
            <div>로딩 중...</div>
          ) : artists && artists.length > 0 ? (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: isMobile
                  ? '1fr'
                  : 'repeat(auto-fill, minmax(200px, 1fr))',
                gap: '16px',
              }}
            >
              {artists.map((artist) => (
                <ArtistCard key={artist.id} artist={artist} />
              ))}
            </div>
          ) : (
            <div>멤버가 없습니다.</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ArtistGroupDetail;
