import { Typography, Space, Tag, Descriptions, theme } from 'antd';
import { DateField } from '@refinedev/antd';
import { Notice } from '../../../lib/types/notice';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { MultiLanguageDisplay, UUIDDisplay } from '@/components/ui';

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
        공지사항 상세
      </Title>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <UUIDDisplay uuid={String(record.id)} label='공지사항 ID' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>제목</Title>
        <MultiLanguageDisplay value={record.title} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>내용</Title>
        <MultiLanguageDisplay value={record.content} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>작성자</Title>
        <Text>
          {record.created_by_user?.user_metadata?.name ||
            record.created_by_user?.email ||
            record.created_by}
        </Text>
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>생성일/수정일</Title>
        <Space direction='vertical'>
          <DateField value={record.created_at} format='YYYY-MM-DD HH:mm:ss' />
          <DateField value={record.updated_at} format='YYYY-MM-DD HH:mm:ss' />
        </Space>
      </div>
    </div>
  );
};
