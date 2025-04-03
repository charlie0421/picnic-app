'use client';

import {
  DateField,
  Show,
  TextField,
  DeleteButton,
  EditButton,
} from '@refinedev/antd';
import { useShow } from '@refinedev/core';
import {
  Card,
  Descriptions,
  Space,
  Typography,
  Image,
  Tabs,
  Divider,
} from 'antd';
import { getImageUrl } from '@/utils/image';

const { Title, Link } = Typography;
const { TabPane } = Tabs;

export default function MediaShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;
  const record = data?.data;

  // 유튜브 비디오 ID로부터 썸네일 URL 생성
  const youtubeThumbnailUrl = record?.video_id
    ? `https://img.youtube.com/vi/${record.video_id}/0.jpg`
    : null;

  return (
    <Show isLoading={isLoading}>
      <Title level={5}>미디어 정보</Title>
      <Descriptions bordered column={1} layout='vertical'>
        <Descriptions.Item label='ID'>
          <TextField value={record?.id} />
        </Descriptions.Item>
        <Descriptions.Item label='제목 (한국어)'>
          <TextField value={record?.title?.ko} />
        </Descriptions.Item>
        <Descriptions.Item label='제목 (영어)'>
          <TextField value={record?.title?.en} />
        </Descriptions.Item>
        <Descriptions.Item label='제목 (일본어)'>
          <TextField value={record?.title?.ja} />
        </Descriptions.Item>
        <Descriptions.Item label='제목 (중국어)'>
          <TextField value={record?.title?.zh} />
        </Descriptions.Item>
        <Descriptions.Item label='비디오 ID (YouTube)'>
          <TextField value={record?.video_id} />
        </Descriptions.Item>
        <Descriptions.Item label='유튜브 링크'>
          <Space direction='vertical' style={{ width: '100%' }}>
            <Typography.Link
              href={`https://www.youtube.com/watch?v=${record?.video_id}`}
              target='_blank'
            >
              {`https://www.youtube.com/watch?v=${record?.video_id}`}
            </Typography.Link>
            {record?.video_id && (
              <Card
                bordered
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
                    src={`https://www.youtube.com/embed/${record.video_id}`}
                    title='YouTube video player'
                    frameBorder='0'
                    allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
                    allowFullScreen
                  ></iframe>
                </div>
              </Card>
            )}
          </Space>
        </Descriptions.Item>
        <Descriptions.Item label='썸네일'>
          <Tabs defaultActiveKey='1' style={{ width: '100%' }}>
            {youtubeThumbnailUrl && (
              <TabPane tab='유튜브 썸네일' key='1'>
                <Card
                  bordered
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
              </TabPane>
            )}
            {record?.thumbnail_url &&
              record.thumbnail_url !== youtubeThumbnailUrl && (
                <TabPane tab='데이터베이스 썸네일' key='2'>
                  <Card
                    bordered
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
                </TabPane>
              )}
          </Tabs>
        </Descriptions.Item>
        <Descriptions.Item label='생성일'>
          <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
        </Descriptions.Item>
        <Descriptions.Item label='수정일'>
          <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </Descriptions.Item>
      </Descriptions>
    </Show>
  );
}
