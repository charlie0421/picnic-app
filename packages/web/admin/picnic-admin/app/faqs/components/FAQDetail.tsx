import { Typography, Space, Tag, Descriptions, theme, Tabs, Card } from 'antd';
import { DateField } from '@refinedev/antd';
import { convertToDisplayFAQ, FAQ } from '../../../lib/types/faq';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { SupportedLocale, supportedLocales } from '@/lib/utils/translation';
import { useState } from 'react';
import { MultiLanguageDisplay, UUIDDisplay } from '@/components/ui';

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
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        FAQ 상세
      </Title>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <UUIDDisplay uuid={String(record.id)} label="FAQ ID" />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>질문</Title>
        <MultiLanguageDisplay value={record.question} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>답변</Title>
        <MultiLanguageDisplay value={record.answer} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>생성일/수정일</Title>
        <Space direction="vertical">
          <DateField value={record.created_at} format="YYYY-MM-DD HH:mm:ss" />
          <DateField value={record.updated_at} format="YYYY-MM-DD HH:mm:ss" />
        </Space>
      </div>

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
