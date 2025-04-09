'use client';

import { DateField, TextField } from '@refinedev/antd';
import {
  Typography,
  Divider,
  theme,
  Grid,
  Space,
} from 'antd';
import { Artist, ArtistGroup } from '@/lib/types/artist';
import { getCdnImageUrl } from '@/lib/image';
import ArtistGroupDisplay from '@/app/artist/components/ArtistGroupDisplay';
import {
  UserOutlined,
  CalendarOutlined,
  IdcardOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { COLORS } from '@/lib/theme';
import { useEffect, useState } from 'react';
import { dataProvider } from '@/providers/data-provider';
import Image from 'next/image';

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

interface ArtistDetailProps {
  record?: Artist;
  loading?: boolean;
}

const ArtistDetail: React.FC<ArtistDetailProps> = ({ record, loading }) => {
  const { token } = theme.useToken();
  const screens = useBreakpoint();
  const isMobile = !screens.md;
  const [artistGroup, setArtistGroup] = useState<ArtistGroup | null>(null);
  const [groupLoading, setGroupLoading] = useState(false);

  // 아티스트 그룹 정보 가져오기
  useEffect(() => {
    // group_id 또는 artist_group_id 필드 확인
    const groupId = record?.group_id || record?.artist_group_id;

    if (groupId) {
      setGroupLoading(true);

      // 데이터 가져오기
      dataProvider
        .getOne({
          resource: 'artist_group',
          id: groupId,
          meta: {
            select:
              'id, name, image, debut_yy, debut_mm, debut_dd, created_at, updated_at',
          },
        })
        .then((result) => {
          if (result && result.data) {
            // name이 문자열인 경우 객체로 변환 (API 응답 형식 변환)
            const groupData = result.data;
            if (groupData.name && typeof groupData.name === 'string') {
              try {
                groupData.name = JSON.parse(groupData.name);
              } catch (e) {
                groupData.name = { ko: groupData.name };
              }
            }

            setArtistGroup(groupData as ArtistGroup);
          } else {
            setArtistGroup(null);
          }
        })
        .catch((error) => {
          setArtistGroup(null);
        })
        .finally(() => {
          setGroupLoading(false);
        });
    } else {
      setArtistGroup(null);
    }
  }, [record]);

  if (!record && !loading) {
    return <div>아티스트 정보를 찾을 수 없습니다.</div>;
  }

  return (
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

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'이름 (한국어)'}
          </Title>
          <TextField
            value={
              typeof record?.name === 'object'
                ? record?.name?.ko
                : record?.name || '-'
            }
          />
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'이름 (English)'}
          </Title>
          <TextField
            value={
              typeof record?.name === 'object' ? record?.name?.en || '-' : '-'
            }
          />
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'이름 (日本語)'}
          </Title>
          <TextField
            value={
              typeof record?.name === 'object' ? record?.name?.ja || '-' : '-'
            }
          />
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'이름 (中文)'}
          </Title>
          <TextField
            value={
              typeof record?.name === 'object' ? record?.name?.zh || '-' : '-'
            }
          />
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            <IdcardOutlined style={{ marginRight: '8px' }} />
            프로필 이미지
          </Title>
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          {record?.image ? (
            <div style={{ marginBottom: '10px', textAlign: 'center' }}>
              <Image
                src={getCdnImageUrl(record.image, 300)}
                alt='프로필 이미지'
                width={300}
                height={300}
                style={getImageStyle(token, { maxHeight: '300px' })}
                onError={(e) => {
                  e.currentTarget.style.display = 'none';
                  e.currentTarget.parentElement!.innerText = '-';
                }}
              />
            </div>
          ) : (
            <div>이미지 없음</div>
          )}
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            <CalendarOutlined style={{ marginRight: '8px' }} />
            생년월일
          </Title>
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'생년월일'}
          </Title>
          <TextField
            value={
              record?.birth_date
                ? record.birth_date
                : record?.yy && record?.mm && record?.dd
                ? `${record.yy}-${record.mm}-${record.dd}`
                : '-'
            }
          />
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'성별'}
          </Title>
          <TextField
            value={
              record?.gender === 'M'
                ? '남성'
                : record?.gender === 'F'
                ? '여성'
                : '-'
            }
          />
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            <TeamOutlined style={{ marginRight: '8px' }} />
            아티스트 그룹 정보
          </Title>
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          {artistGroup ? (
            <ArtistGroupDisplay
              group={artistGroup}
              showImage={true}
            />
          ) : (
            <div>그룹 정보 없음</div>
          )}
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            시스템 정보
          </Title>
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'생성일'}
          </Title>
          <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
        </div>

        <div className='info-section' style={getSectionStyle(token)}>
          <Title level={5} style={getTitleStyle(token)}>
            {'수정일'}
          </Title>
          <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </div>
      </div>
    </div>
  );
};

export default ArtistDetail; 