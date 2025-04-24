import {
  Typography,
  Space,
  Tag,
  List,
  Button,
  Divider,
  Avatar,
  theme,
} from 'antd';
import { DateField } from '@refinedev/antd';
import { DownloadOutlined, UserOutlined } from '@ant-design/icons';
import { Post } from '../../../lib/types/post';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { MultiLanguageDisplay, UUIDDisplay } from '@/components/ui';
import { Board } from '@/lib/types/board';
import { UserProfile } from '@/lib/types/user_profiles';
const { Title, Text } = Typography;

interface PostDetailProps {
  record?: Post;
}

export const PostDetail: React.FC<PostDetailProps> = ({
  record,
}) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record) {
    console.warn('PostDetail: record is null or undefined');
    return null;
  }

  const userData = record?.user_profiles;
  const boardData = record?.boards;

  console.log('record', record);
  console.log('userData', userData);
  console.log('boardData', boardData);

  return (
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        {record.title}
      </Title>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <UUIDDisplay uuid={record.post_id} label="게시글 ID" />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Space align="center" size="middle">
          <Text type="secondary">작성자:</Text>
          {!record.is_anonymous && userData?.avatar_url ? (
            <Avatar 
              src={userData.avatar_url} 
              size="default" 
              alt={userData?.nickname || '사용자'}
            />
          ) : (
            <Avatar icon={<UserOutlined />} />
          )}
          <Text strong>
            {record.is_anonymous
              ? '익명'
              : userData?.nickname ||
                userData?.email ||
                record.user_id}
          </Text>

          {record.is_anonymous && <Tag color="blue">익명</Tag>}
          {record.is_hidden && <Tag color="red">숨김</Tag>}
          {record.is_temporary && <Tag color="orange">임시</Tag>}
        </Space>
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Space>
          <Text type="secondary">게시판:</Text>
          {boardData ? (
              <MultiLanguageDisplay languages={['ko']} value={boardData.name} />
          ) : (
            <Text>없음</Text>
          )}
        </Space>
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Space>
          <Text type="secondary">아티스트:</Text>
          <Text>{boardData?.artist?.name?.ko}</Text>
        </Space>
      </div>


      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Space>
          <Text type="secondary">조회수:</Text>
          <Text>{record.view_count}</Text>

          <Text type="secondary" style={{ marginLeft: '16px' }}>
            댓글수:
          </Text>
          <Text>{record.reply_count}</Text>
        </Space>
      </div>

      <Divider />

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <div
          dangerouslySetInnerHTML={{
            __html:
              typeof record.content === 'string'
                ? record.content
                : JSON.stringify(record.content),
          }}
        />
      </div>

      {record.attachments && record.attachments.length > 0 && (
        <>
          <Divider />
          <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
            <Title level={5}>첨부 파일</Title>
            <List
              size="small"
              dataSource={record.attachments}
              renderItem={(item) => (
                <List.Item>
                  <Space>
                    <DownloadOutlined />
                    <Text>{item}</Text>
                  </Space>
                  <Button
                    size="small"
                    type="link"
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
        <Space direction="vertical">
          <Space>
            <Text type="secondary">생성일:</Text>
            <DateField
              value={record.created_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
          </Space>
          <Space>
            <Text type="secondary">수정일:</Text>
            <DateField
              value={record.updated_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
          </Space>
        </Space>
      </div>
    </div>
  );
}; 