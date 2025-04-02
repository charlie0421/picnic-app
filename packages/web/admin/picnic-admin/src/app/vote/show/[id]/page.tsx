'use client';

import { DateField, MarkdownField, Show, TextField } from '@refinedev/antd';
import { useOne, useShow } from '@refinedev/core';
import { Typography, Grid, theme, Tag } from 'antd';
import {
  UserOutlined,
  TeamOutlined,
  UsergroupAddOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';

// 공통 유틸리티 가져오기
import { getImageUrl } from '@/utils/image';
import { type VoteRecord } from '@/utils/vote';
import { formatDate } from '@/utils/date';
import {
  getCardStyle,
  getSectionStyle,
  getSectionHeaderStyle,
  getTitleStyle,
  getImageStyle,
  getDateSectionStyle,
} from '@/utils/ui';
import { COLORS } from '@/utils/theme';

const { Title } = Typography;
const { useBreakpoint } = Grid;

const headerTitleStyle = {
  margin: 0,
  color: COLORS.primary,
  fontWeight: 'bold',
};

export default function VoteShow() {
  const { queryResult } = useShow<VoteRecord>({
    meta: {
      select:
        'id, title, main_image, vote_category, start_at, stop_at, created_at, updated_at, deleted_at, vote_item(id, artist_id, vote_total, artist(id, name, image, birth_date, yy, mm, dd, artist_group(id, name, image, debut_yy, debut_mm, debut_dd)), created_at, updated_at, deleted_at)',
    },
  });
  const { data, isLoading } = queryResult;
  const screens = useBreakpoint();
  const isMobile = !screens.md;

  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  const record = data?.data;

  const { data: voteData, isLoading: voteIsLoading } = useOne({
    resource: 'vote',
    id: record?.id || '',
    queryOptions: {
      enabled: !!record,
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
        {/* 투표 정보 */}
        <div
          style={{
            flex: 1,
            ...getCardStyle(isMobile, {
              paddingRight: isMobile ? '24px' : '44px',
            }),
          }}
        >
          <div style={getSectionHeaderStyle()}>
            <Title level={4} style={headerTitleStyle}>
              기본 정보
            </Title>
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'아이디'}
            </Title>
            <TextField value={record?.id} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'제목  (한국어)'}
            </Title>
            <TextField value={record?.title?.ko} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'제목 (English)'}
            </Title>
            <TextField value={record?.title?.en} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'제목 (日本語)'}
            </Title>
            <TextField value={record?.title?.ja} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'제목 (中文)'}
            </Title>
            <TextField value={record?.title?.zh} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'카테고리'}
            </Title>
            <TextField value={record?.vote_category} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'메인 이미지'}
            </Title>
            {record?.main_image ? (
              <div style={{ marginBottom: '10px', textAlign: 'center' }}>
                <img
                  src={getImageUrl(record.main_image)}
                  alt='메인 이미지'
                  style={getImageStyle({ maxHeight: '300px' })}
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

          <div style={getSectionHeaderStyle()}>
            <Title level={4} style={headerTitleStyle}>
              시간 정보
            </Title>
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'생성일'}
            </Title>
            <TextField value={formatDate(record?.created_at)} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
              {'수정일'}
            </Title>
            <TextField value={formatDate(record?.updated_at)} />
          </div>

          <div
            className='info-section'
            style={{ ...getSectionStyle(), marginTop: '16px' }}
          >
            <Title level={5} style={getTitleStyle()}>
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
            ...getCardStyle(isMobile, {
              paddingLeft: isMobile ? '24px' : '44px',
            }),
          }}
        >
          <div style={getSectionHeaderStyle()}>
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
              ?.sort((a: any, b: any) => b.vote_total - a.vote_total)
              .map((item: any, index: number) => (
                <div
                  key={item.id}
                  style={{
                    padding: '15px',
                    border: `1px solid ${token.colorBorderSecondary}`,
                    borderRadius: '8px',
                    background: token.colorBgElevated,
                    boxShadow: `0 2px 8px rgba(0, 0, 0, ${
                      token.colorBgMask === '#000000' ? 0.15 : 0.08
                    })`,
                  }}
                >
                  <div
                    style={{
                      textAlign: 'center',
                      fontSize: '1.5em',
                      fontWeight: 'bold',
                      color: COLORS.primary,
                      marginBottom: '15px',
                      padding: '10px',
                      backgroundColor: token.colorPrimaryBg,
                      borderRadius: '4px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    {index + 1}위
                    <Tag
                      color='blue'
                      style={{
                        marginLeft: '10px',
                        color: COLORS.secondary,
                      }}
                    >
                      {item.vote_total?.toLocaleString() || 0} 표
                    </Tag>
                  </div>
                  <div style={{ marginTop: '10px' }}>
                    <div
                      style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '10px',
                      }}
                    >
                      <div style={{ textAlign: 'center' }}>
                        {item.artist?.image ? (
                          <img
                            src={getImageUrl(item.artist.image)}
                            alt='아티스트 이미지'
                            style={{
                              width: '100px',
                              height: '100px',
                              objectFit: 'cover',
                              borderRadius: '50%',
                              border: `2px solid ${COLORS.primary}`,
                              boxShadow: `0 2px 8px rgba(0, 0, 0, ${
                                token.colorBgMask === '#000000' ? 0.15 : 0.08
                              })`,
                            }}
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                              if (
                                e.currentTarget.nextElementSibling instanceof
                                HTMLElement
                              ) {
                                e.currentTarget.nextElementSibling.style.display =
                                  'block';
                              }
                            }}
                          />
                        ) : (
                          <div
                            style={{
                              width: '100px',
                              height: '100px',
                              margin: '0 auto',
                              backgroundColor: '#f5f5f5',
                              borderRadius: '50%',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                            }}
                          >
                            <UserOutlined
                              style={{ fontSize: '48px', color: '#bfbfbf' }}
                            />
                          </div>
                        )}
                      </div>
                      <div style={{ marginTop: '10px' }}>
                        <div
                          style={{
                            fontSize: '16px',
                            fontWeight: 'bold',
                            textAlign: 'center',
                            marginBottom: '12px',
                          }}
                        >
                          {item.artist?.name?.ko || '-'}
                          {item.artist?.name?.en && (
                            <span
                              style={{
                                marginLeft: '4px',
                                color: '#8c8c8c',
                                fontWeight: 'normal',
                              }}
                            >
                              ({item.artist.name.en})
                            </span>
                          )}
                        </div>

                        {/* 생일 정보 */}
                        {(item.artist?.birth_date || item.artist?.yy) && (
                          <div
                            style={{
                              margin: '8px 0',
                              padding: '8px',
                              backgroundColor: token.colorFillTertiary,
                              borderRadius: '4px',
                              border: `1px solid ${token.colorBorderSecondary}`,
                            }}
                          >
                            <div
                              style={{
                                fontSize: '13px',
                                color: token.colorTextSecondary,
                              }}
                            >
                              생일 🎂:{' '}
                              {item.artist.birth_date
                                ? dayjs(item.artist.birth_date).format(
                                    'YYYY-MM-DD',
                                  )
                                : `${item.artist.yy}${
                                    item.artist.mm
                                      ? `.${item.artist.mm
                                          .toString()
                                          .padStart(2, '0')}`
                                      : ''
                                  }${
                                    item.artist.dd
                                      ? `.${item.artist.dd
                                          .toString()
                                          .padStart(2, '0')}`
                                      : ''
                                  }`}
                            </div>
                          </div>
                        )}

                        {/* 그룹 정보 */}
                        {item.artist?.artist_group && (
                          <div
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: '8px',
                              margin: '8px 0 4px 0',
                              padding: '8px',
                              backgroundColor: token.colorFillTertiary,
                              borderRadius: '4px',
                              border: `1px solid ${token.colorBorderSecondary}`,
                            }}
                          >
                            {item.artist.artist_group.image ? (
                              <img
                                src={getImageUrl(
                                  item.artist.artist_group.image,
                                )}
                                alt='그룹 이미지'
                                style={{
                                  width: '30px',
                                  height: '30px',
                                  objectFit: 'cover',
                                  borderRadius: '4px',
                                }}
                                onError={(e) => {
                                  e.currentTarget.style.display = 'none';
                                  if (
                                    e.currentTarget
                                      .nextElementSibling instanceof HTMLElement
                                  ) {
                                    e.currentTarget.nextElementSibling.style.display =
                                      'block';
                                  }
                                }}
                              />
                            ) : null}
                            <div
                              style={{
                                width: '30px',
                                height: '30px',
                                backgroundColor: '#f0f0f0',
                                borderRadius: '4px',
                                display: item.artist.artist_group.image
                                  ? 'none'
                                  : 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                border: `1px solid ${token.colorBorderSecondary}`,
                                boxShadow: `0 2px 4px rgba(0, 0, 0, 0.05)`,
                              }}
                            >
                              <UsergroupAddOutlined
                                style={{
                                  fontSize: '18px',
                                  color: token.colorPrimary,
                                }}
                              />
                            </div>
                            <div>
                              <div style={{ fontWeight: 'bold' }}>
                                {item.artist.artist_group.name?.ko || '-'}
                                {item.artist.artist_group.name?.en && (
                                  <span
                                    style={{
                                      marginLeft: '4px',
                                      color: '#8c8c8c',
                                      fontWeight: 'normal',
                                    }}
                                  >
                                    ({item.artist.artist_group.name.en})
                                  </span>
                                )}
                              </div>
                              {item.artist.artist_group.debut_yy && (
                                <div
                                  style={{
                                    fontSize: '12px',
                                    color: token.colorTextSecondary,
                                    marginTop: '2px',
                                  }}
                                >
                                  데뷔: {item.artist.artist_group.debut_yy}
                                  {item.artist.artist_group.debut_mm &&
                                    `.${item.artist.artist_group.debut_mm
                                      .toString()
                                      .padStart(2, '0')}`}
                                  {item.artist.artist_group.debut_dd &&
                                    `.${item.artist.artist_group.debut_dd
                                      .toString()
                                      .padStart(2, '0')}`}
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

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
    </Show>
  );
}
