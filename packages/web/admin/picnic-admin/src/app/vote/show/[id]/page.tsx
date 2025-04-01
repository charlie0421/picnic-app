'use client';

import { DateField, MarkdownField, Show, TextField } from '@refinedev/antd';
import { useOne, useShow } from '@refinedev/core';
import { Typography } from 'antd';

const { Title } = Typography;

export default function VoteShow() {
  const { queryResult } = useShow({
    meta: {
      select:
        'id, title,created_at,updated_at,deleted_at,vote_item(id,artist_id,vote_total,artist(id,name,image),created_at,updated_at,deleted_at)',
    },
  });
  const { data, isLoading } = queryResult;

  const record = data?.data;

  const { data: voteData, isLoading: voteIsLoading } = useOne({
    resource: 'vote',
    id: record?.vote?.id || '',
    queryOptions: {
      enabled: !!record,
    },
  });

  return (
    <Show isLoading={isLoading}>
      <div style={{ display: 'flex' }}>
        {/* 왼쪽: Vote 정보 */}
        <div style={{ flex: 1, paddingRight: '20px' }}>
          <Title level={5}>{'ID'}</Title>
          <TextField value={record?.id} />

          <Title level={5}>{'제목  (한국어)'}</Title>
          <TextField value={record?.title?.ko} />

          <Title level={5}>{'제목 (English)'}</Title>
          <TextField value={record?.title?.en} />

          <Title level={5}>{'제목 (日本語)'}</Title>
          <TextField value={record?.title?.ja} />

          <Title level={5}>{'제목 (中文)'}</Title>
          <TextField value={record?.title?.zh} />

          <Title level={5}>{'카테고리'}</Title>
          <TextField value={record?.vote_category} />

          <Title level={5}>{'생성일'}</Title>
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

          <Title level={5}>{'수정일'}</Title>
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
          <Title level={5}>{'삭제일'}</Title>
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

        {/* 오른쪽: Vote Item 정보 */}
        <div
          style={{ flex: 2, paddingLeft: '20px', borderLeft: '1px solid #eee' }}
        >
          <Title level={5}>{'투표 아이템'}</Title>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
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
                    border: '1px solid #eee',
                    borderRadius: '8px',
                  }}
                >
                  <div
                    style={{
                      textAlign: 'center',
                      fontSize: '1.5em',
                      fontWeight: 'bold',
                      color: '#1890ff',
                      marginBottom: '15px',
                      padding: '10px',
                      backgroundColor: '#f0f7ff',
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
                            }}
                          />
                        ) : (
                          '-'
                        )}
                      </div>
                      <div style={{ marginTop: '10px' }}>
                        <div>이름 (한국어): {item.artist?.name?.ko || '-'}</div>
                        <div>
                          이름 (English): {item.artist?.name?.en || '-'}
                        </div>
                        <div>이름 (日本語): {item.artist?.name?.ja || '-'}</div>
                        <div>이름 (中文): {item.artist?.name?.zh || '-'}</div>
                        <div
                          style={{
                            marginTop: '10px',
                            fontSize: '1.2em',
                            fontWeight: 'bold',
                            color: '#1890ff',
                          }}
                        >
                          투표 수: {(item.vote_total || 0).toLocaleString()}
                        </div>
                      </div>
                    </div>
                    <div
                      style={{
                        marginTop: '10px',
                        fontSize: '0.9em',
                        color: '#666',
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
                      <div style={{ marginTop: '10px', color: '#999' }}>
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
