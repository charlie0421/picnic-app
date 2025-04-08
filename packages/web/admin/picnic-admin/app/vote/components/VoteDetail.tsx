'use client';

import { TextField, DateField } from '@refinedev/antd';
import { Typography, Grid, theme, Tag } from 'antd';
import {
  UserOutlined,
  TeamOutlined,
  UsergroupAddOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useNavigation } from '@refinedev/core';
import Image from 'next/image';

import { getImageUrl } from '@/lib/image';
import { type VoteRecord } from '@/lib/vote';
import { formatDate } from '@/lib/date';
import {
  getCardStyle,
  getSectionStyle,
  getSectionHeaderStyle,
  getTitleStyle,
  getImageStyle,
  getDateSectionStyle,
} from '@/lib/ui';
import { COLORS } from '@/lib/theme';
import ArtistCard from '@/app/artist/components/ArtistCard';

const { Title } = Typography;
const { useBreakpoint } = Grid;

interface VoteDetailProps {
  record?: VoteRecord;
  loading?: boolean;
}

const headerTitleStyle = {
  margin: 0,
  color: COLORS.primary,
  fontWeight: 'bold',
};

const VoteDetail: React.FC<VoteDetailProps> = ({ record, loading }) => {
  const screens = useBreakpoint();
  const isMobile = !screens.md;
  const { show } = useNavigation();

  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record && !loading) {
    return <div>투표 정보를 찾을 수 없습니다.</div>;
  }

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: isMobile ? 'column' : 'row',
        gap: '16px',
      }}
    >
      {/* 투표 정보 */}
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

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'제목  (한국어)'}
          </Title>
          <TextField value={record?.title?.ko} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'제목 (English)'}
          </Title>
          <TextField value={record?.title?.en} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'제목 (日本語)'}
          </Title>
          <TextField value={record?.title?.ja} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'제목 (中文)'}
          </Title>
          <TextField value={record?.title?.zh} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'카테고리'}
          </Title>
          <TextField value={record?.vote_category} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'메인 이미지'}
          </Title>
          {record?.main_image ? (
            <div style={{ marginBottom: '10px', textAlign: 'center' }}>
              <Image
                src={`${getImageUrl(record.main_image)}?w=300`}
                alt='메인 이미지'
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
            <TextField value='-' />
          )}
        </div>

        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
            시간 정보
          </Title>
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'공개일'}
          </Title>
          <TextField value={formatDate(record?.visible_at)} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'시작일'}
          </Title>
          <TextField value={formatDate(record?.start_at)} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'종료일'}
          </Title>
          <TextField value={formatDate(record?.stop_at)} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'생성일'}
          </Title>
          <TextField value={formatDate(record?.created_at)} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'수정일'}
          </Title>
          <TextField value={formatDate(record?.updated_at)} />
        </div>

        <div
          className='info-section'
          style={{ ...getSectionStyle(token), marginTop: '16px' }}
        >
          <Title level={5} style={getTitleStyle(token)}>
            {'삭제일'}
          </Title>
          <TextField value={formatDate(record?.deleted_at)} />
        </div>
      </div>

      {/* 투표 아이템 정보 */}
      <div
        style={{
          flex: 2,
          borderTop: `1px solid ${token.colorBorderSecondary}`,
          paddingTop: '20px',
          marginTop: isMobile ? '16px' : '0px',
          ...getCardStyle(token, isMobile, {
            paddingLeft: isMobile ? '24px' : '44px',
          }),
        }}
      >
        <div style={getSectionHeaderStyle(token)}>
          <Title level={4} style={headerTitleStyle}>
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
    </div>
  );
};

export default VoteDetail;
