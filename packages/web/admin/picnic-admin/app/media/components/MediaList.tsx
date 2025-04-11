'use client';

import {
  List,
  useTable,
  DateField,
} from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Typography, Card, Space } from 'antd';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';
import { Image } from 'antd';

const { Link } = Typography;

export default function MediaList() {
  const { show } = useNavigation();

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

  return (
    <List>
      <Table
        {...tableProps}
        rowKey='id'
        onRow={(record) => {
          return {
            style: {
              cursor: 'pointer'
            },
            onClick: () => {
              if (record.id) {
                show('media', record.id);
              }
            },
          };
        }}
        pagination={{
          ...tableProps.pagination,
          showSizeChanger: true,
          pageSizeOptions: ['10', '20', '50'],
          showTotal: (total) => `총 ${total}개 항목`,
        }}
      >
        <Table.Column dataIndex='id' title={'ID'} />
        <Table.Column
          dataIndex='title'
          title={'제목'}
          align='center'
          width={200}
          render={(value: Record<string, string>) => {
            if (!value) return '-';
            return value.ko || Object.values(value)[0] || '-';
          }}
        />
        <Table.Column
          dataIndex={['video_id', 'thumbnail_url']}
          title={'썸네일'}
          align='center'
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
                    variant='outlined'
                    style={{ width: 200 }}
                  >
                    <Image
                      src={youtubeThumbnailUrl}
                      alt='유튜브 썸네일'
                      width={160}
                      height={90}
                    />
                  </Card>
                )}

                {dbThumbnailUrl && dbThumbnailUrl !== youtubeThumbnailUrl && (
                  <Card
                    size='small'
                    title='DB 썸네일'
                    variant='outlined'
                    style={{ width: 200 }}
                  >
                    <Image
                      src={dbThumbnailUrl}
                      alt='DB 썸네일'
                      width={160}
                      height={90}
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
          align='center'
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
          align='center'
          render={(value: string, record: any) => {
            const videoId = record.video_id;
            if (!videoId) return '-';

            // 비디오 ID로 유튜브 링크 생성
            const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;
            return (
              <Link href={videoUrl} target='_blank'>
                <Typography.Text style={{ maxWidth: 250 }}>
                  {videoUrl}
                </Typography.Text>
              </Link>
            );
          }}
        />
        <Table.Column
          dataIndex={['created_at', 'updated_at']}
          title={'생성일/수정일'}
          sorter={true} 
          align='center'
          render={(_, record: any) => (
            <Space direction="vertical">
              <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
              <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
            </Space>
          )}
        />
      </Table>
    </List>
  );
} 