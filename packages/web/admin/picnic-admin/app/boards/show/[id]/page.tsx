'use client';

import { useShow, useResource, useOne } from '@refinedev/core';
import { Show, TextField, DateField } from '@refinedev/antd';
import {
  theme,
  Typography,
  Space,
  Tag,
  Divider,
  Card,
  Row,
  Col,
  Descriptions,
} from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useParams } from 'next/navigation';
import { Board } from '../../components/types';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { MultiLanguageDisplay } from '@/components/ui';

const { Title, Text } = Typography;

export default function BoardShow() {
  const params = useParams();
  const id = params.id as string;

  const { queryResult } = useShow<Board>({
    resource: 'boards',
    id,
    meta: {
      idField: 'board_id',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();

  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  // 아티스트 정보 조회
  const { data: artistData } = useOne({
    resource: 'artist',
    id: record?.artist_id?.toString() || '',
    queryOptions: {
      enabled: !!record?.artist_id,
    },
  });

  // 상위 게시판 정보 조회
  const { data: parentBoardData } = useOne({
    resource: 'boards',
    id: record?.parent_board_id || '',
    queryOptions: {
      enabled: !!record?.parent_board_id,
    },
    meta: {
      idField: 'board_id',
    },
  });

  return (
    <AuthorizePage resource='boards' action='show'>
      <Show
        breadcrumb={false}
        title={resource?.meta?.show?.label || '게시판 상세'}
        isLoading={isLoading}
      >
        <div style={getCardStyle(token)}>
          <Title level={4} style={getTitleStyle(token)}>
            게시판 정보
          </Title>

          <Descriptions bordered column={1}>
            <Descriptions.Item label='ID'>{record?.board_id}</Descriptions.Item>

            <Descriptions.Item label='이름'>
              <MultiLanguageDisplay value={record?.name} />
            </Descriptions.Item>

            <Descriptions.Item label='설명'>
              {record?.description || '-'}
            </Descriptions.Item>

            <Descriptions.Item label='상태'>
              <Tag
                color={
                  record?.status === 'ACTIVE'
                    ? 'green'
                    : record?.status === 'PENDING'
                    ? 'orange'
                    : record?.status === 'REJECTED'
                    ? 'red'
                    : 'default'
                }
              >
                {record?.status}
              </Tag>
            </Descriptions.Item>

            <Descriptions.Item label='공식 게시판'>
              <Tag color={record?.is_official ? 'blue' : 'default'}>
                {record?.is_official ? '공식' : '비공식'}
              </Tag>
            </Descriptions.Item>

            <Descriptions.Item label='상위 게시판'>
              {parentBoardData?.data ? (
                <Space>
                  {parentBoardData.data.board_id}
                  <Divider type='vertical' />
                  <MultiLanguageDisplay value={parentBoardData.data.name} />
                </Space>
              ) : (
                '-'
              )}
            </Descriptions.Item>

            <Descriptions.Item label='아티스트'>
              {artistData?.data ? (
                <Space>
                  {artistData.data.id}
                  <Divider type='vertical' />
                  <MultiLanguageDisplay value={artistData.data.name} />
                </Space>
              ) : (
                record?.artist_id?.toString() || '-'
              )}
            </Descriptions.Item>

            <Descriptions.Item label='생성자'>
              {record?.creator_id || '-'}
            </Descriptions.Item>

            <Descriptions.Item label='순서'>{record?.order}</Descriptions.Item>

            <Descriptions.Item label='요청 메시지'>
              {record?.request_message || '-'}
            </Descriptions.Item>

            <Descriptions.Item label='기능 목록'>
              {record?.features && record.features.length > 0 ? (
                <Space wrap>
                  {record.features.map((feature) => (
                    <Tag key={feature}>{feature}</Tag>
                  ))}
                </Space>
              ) : (
                '-'
              )}
            </Descriptions.Item>

            <Descriptions.Item label='생성일'>
              <DateField
                value={record?.created_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
            </Descriptions.Item>

            <Descriptions.Item label='수정일'>
              <DateField
                value={record?.updated_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
            </Descriptions.Item>
          </Descriptions>
        </div>
      </Show>
    </AuthorizePage>
  );
}
