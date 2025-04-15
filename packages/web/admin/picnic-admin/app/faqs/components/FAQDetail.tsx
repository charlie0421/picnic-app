import {
  Typography,
  Space,
  Tag,
  Descriptions,
  theme,
} from 'antd';
import { DateField } from '@refinedev/antd';
import { FAQ } from '../../../lib/types/faq';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';

const { Title, Text } = Typography;

interface FAQDetailProps {
  record?: FAQ;
}

export const FAQDetail: React.FC<FAQDetailProps> = ({
  record,
}) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record) {
    return null;
  }

  return (
    <div style={getCardStyle(token)}>
      <Descriptions bordered column={1}>
        <Descriptions.Item label="ID">{record.id}</Descriptions.Item>

        <Descriptions.Item label="질문">{record.question}</Descriptions.Item>

        <Descriptions.Item label="답변">
          <div dangerouslySetInnerHTML={{ __html: record.answer }} />
        </Descriptions.Item>

        <Descriptions.Item label="카테고리">{record.category || '-'}</Descriptions.Item>

        <Descriptions.Item label="상태">
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

        <Descriptions.Item label="정렬 순서">{record.order_number}</Descriptions.Item>

        <Descriptions.Item label="작성자">
          {record.created_by_user?.user_metadata?.name || record.created_by_user?.email || '-'}
        </Descriptions.Item>

        <Descriptions.Item label="생성일/수정일">
          <Space direction="vertical">
            <DateField
              value={record.created_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
            <DateField
              value={record.updated_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
          </Space>
        </Descriptions.Item>
      </Descriptions>
    </div>
  );
}; 