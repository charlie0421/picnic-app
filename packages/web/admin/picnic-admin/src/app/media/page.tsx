'use client';

import { DateField, List, useTable } from '@refinedev/antd';
import { useNavigation, BaseRecord } from '@refinedev/core';
import { Space, Table, Image, Typography, Card, Divider } from 'antd';
import { getImageUrl } from '@/utils/image';

const { Link } = Typography;

export default function MediaList() {
  const { tableProps } = useTable({
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    meta: {
      select: '*, created_at',
    },
  });
  const { show } = useNavigation();

  return (
    <List>
      <Table
        {...tableProps}
        rowKey='id'
        onRow={(record: BaseRecord) => ({
          onClick: () => {
            if (record.id) {
              show('media', record.id);
            }
          },
          style: { cursor: 'pointer' },
        })}
      >
        <Table.Column dataIndex='id' title={'ID'} />
        <Table.Column
          dataIndex='title'
          title={'제목'}
          render={(value: Record<string, string>) => {
            if (!value) return '-';
            return value.ko || Object.values(value)[0] || '-';
          }}
        />
        <Table.Column
          dataIndex={['video_id', 'thumbnail_url']}
          title={'썸네일'}
          render={(_, record: any) => {
            const videoId = record.video_id;
            const dbThumbnailUrl = record.thumbnail_url;

            // 유튜브 썸네일 URL 생성
            const youtubeThumbnailUrl = videoId
              ? `https://img.youtube.com/vi/${videoId}/0.jpg`
              : null;

            return (
              <Space
                direction='vertical'
                size='small'
                style={{ width: '100%' }}
              >
                {youtubeThumbnailUrl && (
                  <Card
                    size='small'
                    title='유튜브 썸네일'
                    bordered
                    style={{ width: 200 }}
                  >
                    <Image
                      src={youtubeThumbnailUrl}
                      alt='유튜브 썸네일'
                      width={160}
                      height={90}
                      style={{ objectFit: 'cover' }}
                    />
                  </Card>
                )}

                {dbThumbnailUrl && dbThumbnailUrl !== youtubeThumbnailUrl && (
                  <Card
                    size='small'
                    title='DB 썸네일'
                    bordered
                    style={{ width: 200 }}
                  >
                    <Image
                      src={getImageUrl(dbThumbnailUrl)}
                      alt='DB 썸네일'
                      width={160}
                      height={90}
                      style={{ objectFit: 'cover' }}
                    />
                  </Card>
                )}

                {!youtubeThumbnailUrl && !dbThumbnailUrl && '-'}
              </Space>
            );
          }}
        />
        <Table.Column
          dataIndex='video_id'
          title={'비디오 ID'}
          render={(value: string) => {
            if (!value) return '-';
            return (
              <Link
                href={`https://www.youtube.com/watch?v=${value}`}
                target='_blank'
              >
                {value}
              </Link>
            );
          }}
        />
        <Table.Column
          dataIndex='video_url'
          title={'유튜브 링크'}
          render={(value: string, record: any) => {
            const videoId = record.video_id;
            if (!videoId) return '-';

            // 비디오 ID로 유튜브 링크 생성
            const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;
            return (
              <Link href={videoUrl} target='_blank'>
                <Typography.Text ellipsis style={{ maxWidth: 250 }}>
                  {videoUrl}
                </Typography.Text>
              </Link>
            );
          }}
        />
        <Table.Column
          dataIndex={['created_at']}
          title={'생성일'}
          sorter={true}
          render={(value: any) => (
            <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
          )}
        />
      </Table>
    </List>
  );
}
