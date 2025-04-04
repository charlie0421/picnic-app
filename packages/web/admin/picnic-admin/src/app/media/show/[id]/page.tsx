'use client';

import {
  DateField,
  Show,
  TextField,
  DeleteButton,
  EditButton,
} from '@refinedev/antd';
import { useShow, useNavigation } from '@refinedev/core';
import {
  Card,
  Descriptions,
  Space,
  Typography,
  Image,
  Tabs,
  Divider,
  Skeleton,
  Button,
} from 'antd';
import { getImageUrl } from '@/utils/image';
import React from 'react';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';

const { Title, Link } = Typography;

export default function MediaShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const record = data?.data;

  // 유튜브 비디오 ID로부터 썸네일 URL 생성
  const youtubeThumbnailUrl = record?.video_id
    ? `https://img.youtube.com/vi/${record.video_id}/0.jpg`
    : null;

  // Tabs items 구성
  const tabItems = React.useMemo(() => {
    const items = [];

    if (youtubeThumbnailUrl) {
      items.push({
        key: '1',
        label: '유튜브 썸네일',
        children: (
          <Card
            variant='outlined'
            title='유튜브 자동 생성 썸네일'
            style={{ maxWidth: 600 }}
          >
            <div style={{ textAlign: 'left' }}>
              <Image
                src={youtubeThumbnailUrl}
                alt='유튜브 썸네일'
                style={{ maxWidth: '100%', maxHeight: 400 }}
              />
            </div>
            <Divider />
            <div
              style={{
                color: '#666',
                fontSize: '14px',
                textAlign: 'left',
              }}
            >
              <p>유튜브에서 자동으로 생성된 썸네일입니다.</p>
              <p>URL: {youtubeThumbnailUrl}</p>
            </div>
          </Card>
        ),
      });
    }

    if (record?.thumbnail_url && record.thumbnail_url !== youtubeThumbnailUrl) {
      items.push({
        key: '2',
        label: '데이터베이스 썸네일',
        children: (
          <Card
            variant='outlined'
            title='데이터베이스에 저장된 썸네일'
            style={{ maxWidth: 600 }}
          >
            <div style={{ textAlign: 'left' }}>
              <Image
                src={getImageUrl(record.thumbnail_url)}
                alt='데이터베이스 썸네일'
                style={{ maxWidth: '100%', maxHeight: 400 }}
              />
            </div>
            <Divider />
            <div
              style={{
                color: '#666',
                fontSize: '14px',
                textAlign: 'left',
              }}
            >
              <p>데이터베이스에 저장된 커스텀 썸네일입니다.</p>
              <p>경로: {record.thumbnail_url}</p>
            </div>
          </Card>
        ),
      });
    }

    return items;
  }, [youtubeThumbnailUrl, record]);

  // Descriptions items 구성
  const descriptionsItems = [
    {
      key: 'id',
      label: 'ID',
      children: <TextField value={record?.id} />,
    },
    {
      key: 'title-ko',
      label: '제목 (한국어)',
      children: <TextField value={record?.title?.ko} />,
    },
    {
      key: 'title-en',
      label: '제목 (영어)',
      children: <TextField value={record?.title?.en} />,
    },
    {
      key: 'title-ja',
      label: '제목 (일본어)',
      children: <TextField value={record?.title?.ja} />,
    },
    {
      key: 'title-zh',
      label: '제목 (중국어)',
      children: <TextField value={record?.title?.zh} />,
    },
    {
      key: 'video-id',
      label: '비디오 ID (YouTube)',
      children: <TextField value={record?.video_id} />,
    },
    {
      key: 'youtube-link',
      label: '유튜브 링크',
      children: (
        <Space direction='vertical' style={{ width: '100%' }}>
          <Typography.Link
            href={`https://www.youtube.com/watch?v=${record?.video_id}`}
            target='_blank'
          >
            {`https://www.youtube.com/watch?v=${record?.video_id}`}
          </Typography.Link>
          {record?.video_id && (
            <Card
              variant='outlined'
              title='유튜브 비디오 미리보기'
              style={{ maxWidth: 640, marginTop: 16 }}
            >
              <div
                style={{
                  position: 'relative',
                  paddingBottom: '56.25%',
                  height: 0,
                  overflow: 'hidden',
                }}
              >
                <iframe
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    maxWidth: '640px',
                  }}
                  src={`https://www.youtube.com/embed/${record?.video_id}`}
                  title='YouTube video player'
                  frameBorder='0'
                  allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
                  allowFullScreen
                ></iframe>
              </div>
            </Card>
          )}
        </Space>
      ),
    },
    {
      key: 'thumbnail',
      label: '썸네일',
      children: (
        <Tabs defaultActiveKey='1' style={{ width: '100%' }} items={tabItems} />
      ),
    },
    {
      key: 'created-at',
      label: '생성일',
      children: (
        <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      key: 'updated-at',
      label: '수정일',
      children: (
        <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  const { edit, list } = useNavigation();
  const id = record?.id;

  if (isLoading) {
    return <Skeleton active paragraph={{ rows: 10 }} />;
  }

  return (
    <div>
      <div
        style={{
          marginBottom: '16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Space>
          <Button icon={<ArrowLeftOutlined />} onClick={() => list('media')}>
            목록으로
          </Button>
          <Title level={5} style={{ margin: 0 }}>
            미디어 정보
          </Title>
        </Space>
        <Space>
          <Button
            type='primary'
            icon={<EditOutlined />}
            onClick={() => edit('media', id!)}
          >
            편집
          </Button>
          <DeleteButton
            resource='media'
            recordItemId={id}
            onSuccess={() => list('media')}
          />
        </Space>
      </div>
      <Descriptions
        bordered
        column={1}
        layout='vertical'
        items={descriptionsItems}
      />
    </div>
  );
}
