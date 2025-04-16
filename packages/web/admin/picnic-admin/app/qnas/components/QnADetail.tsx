import { Typography, Space, Tag, Descriptions, theme, Divider } from 'antd';
import { DateField } from '@refinedev/antd';
import { QnA } from '../../../lib/types/qna';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';

const { Title, Text } = Typography;

interface QnADetailProps {
  record?: QnA;
}

export const QnADetail: React.FC<QnADetailProps> = ({ record }) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record) {
    return null;
  }

  return (
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        질문 정보
      </Title>

      <Descriptions bordered column={1}>
        <Descriptions.Item label='ID'>{record.id}</Descriptions.Item>

        <Descriptions.Item label='제목'>
          <Space>
            {record.is_private && <Tag color='blue'>비공개</Tag>}
            {record.title}
          </Space>
        </Descriptions.Item>

        <Descriptions.Item label='질문'>
          <div dangerouslySetInnerHTML={{ __html: record.question }} />
        </Descriptions.Item>

        <Descriptions.Item label='상태'>
          <Tag
            color={
              record.status === 'ANSWERED'
                ? 'green'
                : record.status === 'PENDING'
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

        <Descriptions.Item label='작성일'>
          <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
        </Descriptions.Item>
      </Descriptions>

      {record.answer && (
        <>
          <Divider />
          <Title level={4} style={getTitleStyle(token)}>
            답변 정보
          </Title>

          <Descriptions bordered column={1}>
            <Descriptions.Item label='답변'>
              <div dangerouslySetInnerHTML={{ __html: record.answer }} />
            </Descriptions.Item>

            <Descriptions.Item label='답변자'>
              {record.answered_by_user?.user_metadata?.name ||
                record.answered_by_user?.email ||
                '-'}
            </Descriptions.Item>

            <Descriptions.Item label='답변일'>
              {record.answered_at ? (
                <DateField
                  value={record.answered_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              ) : (
                '-'
              )}
            </Descriptions.Item>
          </Descriptions>
        </>
      )}
    </div>
  );
};
