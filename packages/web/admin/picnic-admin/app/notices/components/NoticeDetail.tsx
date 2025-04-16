import { Typography, Space, Tag, Descriptions, theme } from 'antd';
import { DateField } from '@refinedev/antd';
import { Notice } from '../../../lib/types/notice';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';

const { Title, Text } = Typography;

interface NoticeDetailProps {
  record?: Notice;
}

export const NoticeDetail: React.FC<NoticeDetailProps> = ({ record }) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record) {
    return null;
  }

  return (
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        공지사항 정보
      </Title>

      <Descriptions bordered column={1}>
        <Descriptions.Item label='ID'>{record.id}</Descriptions.Item>

        <Descriptions.Item label='제목'>
          <Space>
            {record.is_pinned && <Tag color='red'>공지</Tag>}
            {record.title}
          </Space>
        </Descriptions.Item>

        <Descriptions.Item label='내용'>
          <div dangerouslySetInnerHTML={{ __html: record.content }} />
        </Descriptions.Item>

        <Descriptions.Item label='상태'>
          <Tag
            color={
              record.status === 'PUBLISHED'
                ? 'green'
                : record.status === 'DRAFT'
                ? 'gold'
                : 'default'
            }
          >
            {record.status}
          </Tag>
        </Descriptions.Item>

        <Descriptions.Item label='작성자'>
          {record.created_by_user?.user_metadata?.name ||
            record.created_by_user?.email ||
            '-'}
        </Descriptions.Item>

        <Descriptions.Item label='생성일/수정일'>
          <Space direction='vertical'>
            <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
            <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
          </Space>
        </Descriptions.Item>
      </Descriptions>
    </div>
  );
};
