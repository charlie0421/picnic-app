'use client';

import { DateField, Show, TextField } from '@refinedev/antd';
import { useShow, useOne } from '@refinedev/core';
import { Typography, Image, Divider, theme, Grid } from 'antd';
import { Artist, ArtistGroup } from '@/types/artist';
import { getImageUrl } from '@/utils/image';
import { useParams } from 'next/navigation';
import ArtistGroupDisplay from '@/components/artist/ArtistGroupDisplay';
import {
  UserOutlined,
  CalendarOutlined,
  IdcardOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { COLORS } from '@/utils/theme';

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

export default function ArtistShow() {
  // URL에서 id 파라미터 가져오기
  const params = useParams();
  const id = params?.id?.toString();
  const { token } = theme.useToken();
  const screens = useBreakpoint();
  const isMobile = !screens.md;

  const { queryResult } = useShow<Artist>({
    resource: 'artist',
    id: id,
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;

  // 아티스트 그룹 정보 가져오기
  const { data: groupData, isLoading: groupIsLoading } = useOne<ArtistGroup>({
    resource: 'artist_group',
    id: record?.group_id || '',
    queryOptions: {
      enabled: !!record?.group_id,
    },
  });

  return (
    <Show isLoading={isLoading}>
      <div
        style={{
          display: 'flex',
          flexDirection: isMobile ? 'column' : 'row',
          gap: '16px',
        }}
      >
        {/* 왼쪽 영역: 아티스트 기본 정보 */}
        <div
          style={{
            flex: 1,
            ...getCardStyle(token, isMobile),
          }}
        >
          <div style={getSectionHeaderStyle(token)}>
            <Title level={4} style={headerTitleStyle}>
              <UserOutlined style={{ marginRight: '8px' }} />
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
              성별
            </Title>
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(token), marginTop: '16px' }}
          >
            <TextField value={record?.gender || '-'} />
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
        </div>

        {/* 오른쪽 영역: 날짜 정보 및 그룹 정보 */}
        <div
          style={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            gap: '16px',
          }}
        >
          {/* 날짜 정보 */}
          <div
            style={{
              ...getCardStyle(token, isMobile),
            }}
          >
            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                <CalendarOutlined style={{ marginRight: '8px' }} />
                날짜 정보
              </Title>
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'생년월일'}
              </Title>
              <TextField
                value={
                  record?.yy && record?.mm && record?.dd
                    ? `${record.yy}년 ${record.mm}월 ${record.dd}일`
                    : '-'
                }
              />
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'데뷔일'}
              </Title>
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

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              <Title level={5} style={getTitleStyle(token)}>
                {'생성일'}
              </Title>
              <DateField value={record?.created_at} format='YYYY-MM-DD' />
            </div>
          </div>

          {/* 그룹 정보 */}
          <div
            style={{
              ...getCardStyle(token, isMobile),
            }}
          >
            <div style={getSectionHeaderStyle(token)}>
              <Title level={4} style={headerTitleStyle}>
                <TeamOutlined style={{ marginRight: '8px' }} />
                그룹 정보
              </Title>
            </div>

            <div
              className='info-section'
              style={{ ...getSectionStyle(token), marginTop: '16px' }}
            >
              {groupIsLoading ? (
                <TextField value='로딩 중...' />
              ) : groupData?.data ? (
                <ArtistGroupDisplay group={groupData.data} />
              ) : (
                <TextField value='-' />
              )}
            </div>
          </div>
        </div>
      </div>
    </Show>
  );
}
