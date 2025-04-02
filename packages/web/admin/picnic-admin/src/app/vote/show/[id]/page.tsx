'use client';

import { DateField, MarkdownField, Show, TextField } from '@refinedev/antd';
import { useOne, useShow } from '@refinedev/core';
import { Typography, Grid, theme } from 'antd';

// 공통 유틸리티 가져오기
import { getImageUrl } from '@/utils/image';
import { type VoteRecord } from '@/utils/vote';
import {
  getCardStyle,
  getSectionStyle,
  getSectionHeaderStyle,
  getTitleStyle,
  getImageStyle,
  getDateSectionStyle,
} from '@/utils/ui';

const { Title } = Typography;
const { useBreakpoint } = Grid;

export default function VoteShow() {
  const { queryResult } = useShow<VoteRecord>({
    meta: {
      select:
        'id, title, main_image, created_at, updated_at, deleted_at, vote_item(id, artist_id, vote_total, artist(id, name, image), created_at, updated_at, deleted_at)',
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
          gap: '24px',
        }}
      >
        {/* 투표 정보 */}
        <div
          style={{
            flex: 1,
            paddingRight: isMobile ? '0' : '20px',
            ...getCardStyle(isMobile),
          }}
        >
          <div style={getSectionHeaderStyle()}>
            <Title level={4} style={getTitleStyle({ margin: 0 })}>
              투표 기본 정보
            </Title>
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'ID'}
            </Title>
            <TextField value={record?.id} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'제목  (한국어)'}
            </Title>
            <TextField value={record?.title?.ko} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'제목 (English)'}
            </Title>
            <TextField value={record?.title?.en} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'제목 (日本語)'}
            </Title>
            <TextField value={record?.title?.ja} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'제목 (中文)'}
            </Title>
            <TextField value={record?.title?.zh} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'카테고리'}
            </Title>
            <TextField value={record?.vote_category} />
          </div>

          <div className='info-section' style={getSectionStyle()}>
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

          <div style={getDateSectionStyle()}>
            <Title level={4} style={getTitleStyle({ margin: 0 })}>
              날짜 정보
            </Title>
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'생성일'}
            </Title>
            {record?.created_at ? (
              <TextField
                value={new Date(record.created_at)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')}
              />
            ) : (
              <TextField value='-' />
            )}
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'수정일'}
            </Title>
            {record?.updated_at ? (
              <TextField
                value={new Date(record.updated_at)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')}
              />
            ) : (
              <TextField value='-' />
            )}
          </div>

          <div className='info-section' style={getSectionStyle()}>
            <Title level={5} style={getTitleStyle()}>
              {'삭제일'}
            </Title>
            {record?.deleted_at ? (
              <TextField
                value={new Date(record.deleted_at)
                  .toLocaleString('ko-KR', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false,
                  })
                  .replace(/\. /g, '-')
                  .replace(/:/g, ':')
                  .replace('.', '')}
              />
            ) : (
              <TextField value='-' />
            )}
          </div>
        </div>

        {/* 투표 아이템 정보 */}
        <div
          style={{
            flex: 2,
            paddingLeft: isMobile ? '0' : '20px',
            borderTop: isMobile
              ? `1px solid ${token.colorBorderSecondary}`
              : 'none',
            paddingTop: isMobile ? '20px' : '0',
            ...getCardStyle(isMobile),
          }}
        >
          <div style={getSectionHeaderStyle()}>
            <Title level={4} style={getTitleStyle({ margin: 0 })}>
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
                      color: token.colorPrimary,
                      marginBottom: '15px',
                      padding: '10px',
                      backgroundColor: token.colorPrimaryBg,
                      borderRadius: '4px',
                    }}
                  >
                    {index + 1}위
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
                            src={`${process.env.NEXT_PUBLIC_SUPABASE_CDN_URL}/${item.artist.image}?w=100`}
                            alt='아티스트 이미지'
                            style={{
                              width: '100px',
                              height: '100px',
                              objectFit: 'cover',
                              borderRadius: '50%',
                              border: `2px solid ${token.colorPrimary}`,
                              boxShadow: `0 2px 8px rgba(0, 0, 0, ${
                                token.colorBgMask === '#000000' ? 0.15 : 0.08
                              })`,
                            }}
                          />
                        ) : (
                          '-'
                        )}
                      </div>
                      <div style={{ marginTop: '10px' }}>
                        <div style={{ marginBottom: '4px' }}>
                          이름 (한국어): {item.artist?.name?.ko || '-'}
                        </div>
                        <div style={{ marginBottom: '4px' }}>
                          이름 (English): {item.artist?.name?.en || '-'}
                        </div>
                        <div style={{ marginBottom: '4px' }}>
                          이름 (日本語): {item.artist?.name?.ja || '-'}
                        </div>
                        <div style={{ marginBottom: '4px' }}>
                          이름 (中文): {item.artist?.name?.zh || '-'}
                        </div>
                        <div
                          style={{
                            marginTop: '10px',
                            fontSize: '1.2em',
                            fontWeight: 'bold',
                            color: token.colorPrimary,
                            padding: '8px',
                            background: token.colorPrimaryBg,
                            borderRadius: '4px',
                            textAlign: 'center',
                          }}
                        >
                          투표 수: {(item.vote_total || 0).toLocaleString()}
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
                      <div>
                        생성일:{' '}
                        {item.created_at
                          ? new Date(item.created_at).toLocaleString('ko-KR')
                          : '-'}
                      </div>
                      <div>
                        수정일:{' '}
                        {item.updated_at
                          ? new Date(item.updated_at).toLocaleString('ko-KR')
                          : '-'}
                      </div>
                      <div>
                        삭제일:{' '}
                        {item.deleted_at
                          ? new Date(item.deleted_at).toLocaleString('ko-KR')
                          : '-'}
                      </div>
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
                </div>
              ))}
          </div>
        </div>
      </div>
    </Show>
  );
}
