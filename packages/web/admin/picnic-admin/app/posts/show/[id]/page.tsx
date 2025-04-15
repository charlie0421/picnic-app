'use client';

import { useShow, useResource, useOne } from '@refinedev/core';
import { Show, TextField, DateField } from '@refinedev/antd';
import {
  theme,
  Typography,
  Space,
  Tag,
  List,
  Button,
  Card,
  Divider,
} from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { DownloadOutlined } from '@ant-design/icons';
import { Post } from '../../components/types';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { useParams } from 'next/navigation';
import { MultiLanguageDisplay } from '@/components/ui';

const { Title, Text } = Typography;

export default function PostShow() {
  const params = useParams();
  const id = params.id as string;

  const { queryResult } = useShow<Post>({
    resource: 'posts',
    id,
    meta: {
      idField: 'post_id',
    },
  });
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();

  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  // 게시판 정보 조회 (있는 경우)
  const { data: boardData } = useOne({
    resource: 'boards',
    id: record?.board_id || '',
    queryOptions: {
      enabled: !!record?.board_id,
    },
    meta: {
      idField: 'board_id',
    },
  });

  // 작성자 정보 조회
  const { data: userData } = useOne({
    resource: 'user_profiles',
    id: record?.user_id || '',
    queryOptions: {
      enabled: !!record?.user_id,
    },
    meta: {
      idField: 'user_id',
    },
  });

  return (
    <AuthorizePage resource='posts' action='show'>
      <Show
        breadcrumb={false}
        title={resource?.meta?.show?.label || '게시글 상세'}
        isLoading={isLoading}
      >
        <div style={getCardStyle(token)}>
          <Title level={4} style={getTitleStyle(token)}>
            {record?.title}
          </Title>

          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <Space align='center'>
              <Text type='secondary'>작성자:</Text>
              <Text strong>
                {record?.is_anonymous
                  ? '익명'
                  : userData?.data?.nickname ||
                    userData?.data?.email ||
                    record?.user_id}
              </Text>

              {record?.is_anonymous && <Tag color='blue'>익명</Tag>}

              {record?.is_hidden && <Tag color='red'>숨김</Tag>}

              {record?.is_temporary && <Tag color='orange'>임시</Tag>}
            </Space>
          </div>

          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <Space>
              <Text type='secondary'>게시판:</Text>
              {boardData?.data ? (
                <MultiLanguageDisplay value={boardData.data.name} />
              ) : (
                <Text>없음</Text>
              )}
            </Space>
          </div>

          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <Space>
              <Text type='secondary'>조회수:</Text>
              <Text>{record?.view_count}</Text>

              <Text type='secondary' style={{ marginLeft: '16px' }}>
                댓글수:
              </Text>
              <Text>{record?.reply_count}</Text>
            </Space>
          </div>

          <Divider />

          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <div
              dangerouslySetInnerHTML={{
                __html:
                  typeof record?.content === 'string'
                    ? record.content
                    : JSON.stringify(record?.content),
              }}
            />
          </div>

          {record?.attachments && record.attachments.length > 0 && (
            <>
              <Divider />
              <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
                <Title level={5}>첨부 파일</Title>
                <List
                  size='small'
                  dataSource={record.attachments}
                  renderItem={(item) => (
                    <List.Item>
                      <Space>
                        <DownloadOutlined />
                        <Text>{item}</Text>
                      </Space>
                      <Button
                        size='small'
                        type='link'
                        icon={<DownloadOutlined />}
                      >
                        다운로드
                      </Button>
                    </List.Item>
                  )}
                />
              </div>
            </>
          )}

          <Divider />

          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <Space direction='vertical'>
              <Space>
                <Text type='secondary'>생성일:</Text>
                <DateField
                  value={record?.created_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
              <Space>
                <Text type='secondary'>수정일:</Text>
                <DateField
                  value={record?.updated_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
            </Space>
          </div>
        </div>
      </Show>
    </AuthorizePage>
  );
}
