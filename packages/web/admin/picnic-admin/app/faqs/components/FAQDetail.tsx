import { Typography, Space, Tag, Descriptions, theme, Tabs, Card } from 'antd';
import { DateField } from '@refinedev/antd';
import { convertToDisplayFAQ, FAQ } from '../../../lib/types/faq';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { SupportedLocale, supportedLocales } from '@/lib/utils/translation';
import { useState } from 'react';

const { Title, Text } = Typography;

interface FAQDetailProps {
  record?: FAQ;
}

export const FAQDetail: React.FC<FAQDetailProps> = ({ record }) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();
  const [activeLocale, setActiveLocale] = useState<SupportedLocale>('ko');

  if (!record) {
    return null;
  }

  // 현재 선택된 언어로 데이터 변환
  const displayFAQ = convertToDisplayFAQ(record, activeLocale);

  // 각 언어별 탭 아이템 생성
  const localeTabItems = supportedLocales.map((locale) => ({
    key: locale,
    label: getLocaleLabel(locale),
    children: (
      <Card style={getCardStyle(token)}>
        <Descriptions bordered column={1}>
          <Descriptions.Item label='질문'>
            {typeof record.question === 'string'
              ? record.question
              : record.question?.[locale] || ''}
          </Descriptions.Item>

          <Descriptions.Item label='답변'>
            <div
              dangerouslySetInnerHTML={{
                __html:
                  typeof record.answer === 'string'
                    ? record.answer
                    : record.answer?.[locale] || '',
              }}
            />
          </Descriptions.Item>
        </Descriptions>
      </Card>
    ),
  }));

  return (
    <div>
      <Descriptions bordered column={1} style={{ marginBottom: 24 }}>
        <Descriptions.Item label='ID'>{record.id}</Descriptions.Item>

        <Descriptions.Item label='카테고리'>
          {record.category || '-'}
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

        <Descriptions.Item label='정렬 순서'>
          {record.order_number}
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

      <Title level={5}>언어별 내용</Title>
      <Tabs
        activeKey={activeLocale}
        onChange={(key) => setActiveLocale(key as SupportedLocale)}
        items={localeTabItems}
      />
    </div>
  );
};

// 언어 코드별 표시 라벨
function getLocaleLabel(locale: SupportedLocale): string {
  const labels: Record<SupportedLocale, string> = {
    ko: '한국어',
    en: '영어',
    ja: '일본어',
    zh: '중국어',
    id: '인도네시아어',
  };
  return labels[locale] || locale;
}
