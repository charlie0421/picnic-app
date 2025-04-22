import React, { useState } from 'react';
import { Button, message, Tooltip } from 'antd';
import { TranslationOutlined, LoadingOutlined } from '@ant-design/icons';
import { SupportedLocale, translateText } from '@/lib/utils/translation';

interface TranslationButtonProps {
  text: string;
  sourceLang: SupportedLocale;
  targetLang: SupportedLocale;
  onTranslated: (translatedText: string) => void;
}

const TranslationButton: React.FC<TranslationButtonProps> = ({
  text,
  sourceLang,
  targetLang,
  onTranslated,
}) => {
  const [loading, setLoading] = useState(false);

  // 번역 처리 함수
  const handleTranslate = async () => {
    if (!text.trim()) {
      message.warning('번역할 내용이 없습니다.');
      return;
    }

    try {
      setLoading(true);
      const result = await translateText(text, targetLang, sourceLang);
      onTranslated(result.text);
      message.success('번역이 완료되었습니다.');
    } catch (error) {
      console.error('번역 실패:', error);
      message.error('번역 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  // 번역할 내용이 없거나 로딩 중이면 버튼 비활성화
  const disableTranslation =
    !text.trim() || loading || sourceLang === targetLang;

  return (
    <Tooltip title='DeepL 번역'>
      <Button
        icon={loading ? <LoadingOutlined /> : <TranslationOutlined />}
        onClick={handleTranslate}
        disabled={disableTranslation}
        loading={loading}
      >
        {getLangLabel(targetLang)}로 번역
      </Button>
    </Tooltip>
  );
};

// 언어 코드별 표시 라벨
function getLangLabel(locale: SupportedLocale): string {
  const labels: Record<SupportedLocale, string> = {
    ko: '한국어',
    en: '영어',
    ja: '일본어',
    zh: '중국어',
    id: '인도네시아어',
  };
  return labels[locale] || locale;
}

export default TranslationButton;
