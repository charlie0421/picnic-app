import React, { useState } from 'react';
import { Form, Input, Tabs, Typography, Space } from 'antd';
import { SupportedLocale, supportedLocales } from '@/lib/utils/translation';
import TranslationButton from '@/components/ui/TranslationButton';
import TextEditor from '@/components/ui/TextEditor';

const { Text } = Typography;

interface MultilingualInputProps {
  name: string;
  label: string;
  required?: boolean;
  baseLocale?: SupportedLocale;
  useRichText?: boolean;
}

const MultilingualInput: React.FC<MultilingualInputProps> = ({
  name,
  label,
  required = false,
  baseLocale = 'ko',
  useRichText = false,
}) => {
  const [activeTab, setActiveTab] = useState<string>(baseLocale);
  const form = Form.useFormInstance();

  const handleTranslated = (
    translatedText: string,
    targetLang: SupportedLocale,
  ) => {
    form.setFieldValue(`${name}_${targetLang}`, translatedText);
  };

  return (
    <Form.Item label={label} required={required} style={{ marginBottom: 32 }}>
      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        type='card'
        items={supportedLocales.map((locale) => ({
          key: locale,
          label: getLocaleLabel(locale),
          children: (
            <Space direction='vertical' style={{ width: '100%' }}>
              <Form.Item
                name={`${name}_${locale}`}
                rules={
                  locale === baseLocale && required
                    ? [
                        {
                          required: true,
                          message: `${label}을(를) 입력해주세요`,
                        },
                      ]
                    : []
                }
                noStyle
                preserve={true}
              >
                {useRichText ? (
                  <TextEditor />
                ) : (
                  <Input.TextArea
                    rows={4}
                    placeholder={`${label} (${getLocaleLabel(locale)})`}
                  />
                )}
              </Form.Item>

              {locale !== baseLocale && (
                <Space style={{ marginTop: 8 }}>
                  <TranslationButton
                    text={form.getFieldValue(`${name}_${baseLocale}`)}
                    sourceLang={baseLocale}
                    targetLang={locale as SupportedLocale}
                    onTranslated={(text) =>
                      handleTranslated(text, locale as SupportedLocale)
                    }
                  />
                  <Text type='secondary'>
                    {getLocaleLabel(baseLocale)}에서 번역
                  </Text>
                </Space>
              )}
            </Space>
          ),
        }))}
      />

      {required && (
        <Text type='secondary' style={{ marginTop: 8, display: 'block' }}>
          {getLocaleLabel(baseLocale)}는 필수 입력 항목입니다.
        </Text>
      )}
    </Form.Item>
  );
};

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

export default MultilingualInput;
