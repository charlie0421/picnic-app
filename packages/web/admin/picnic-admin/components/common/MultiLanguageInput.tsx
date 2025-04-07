'use client';

import { Form, Input } from 'antd';
import React from 'react';

export type LanguageType = 'ko' | 'en' | 'ja' | 'zh';

interface MultiLanguageInputProps {
  name: string;
  required?: boolean;
  label?: string;
  placeholder?: {
    ko?: string;
    en?: string;
    ja?: string;
    zh?: string;
  };
}

export const MultiLanguageInput: React.FC<MultiLanguageInputProps> = ({
  name,
  required = true,
  label = '이름',
  placeholder = {
    ko: '한국어를 입력하세요',
    en: '영어를 입력하세요',
    ja: '일본어를 입력하세요',
    zh: '중국어를 입력하세요',
  },
}) => {
  return (
    <>
      <Form.Item
        label={`${label} (한국어) 🇰🇷`}
        name={[name, 'ko']}
        rules={[
          {
            required,
            message: `한국어 ${label}을(를) 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={placeholder.ko} />
      </Form.Item>

      <Form.Item
        label={`${label} (영어) 🇺🇸`}
        name={[name, 'en']}
        rules={[
          {
            required,
            message: `영어 ${label}을(를) 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={placeholder.en} />
      </Form.Item>

      <Form.Item
        label={`${label} (일본어) 🇯🇵`}
        name={[name, 'ja']}
        rules={[
          {
            required,
            message: `일본어 ${label}을(를) 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={placeholder.ja} />
      </Form.Item>

      <Form.Item
        label={`${label} (중국어) 🇨🇳`}
        name={[name, 'zh']}
        rules={[
          {
            required,
            message: `중국어 ${label}을(를) 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={placeholder.zh} />
      </Form.Item>
    </>
  );
};

export default MultiLanguageInput;
