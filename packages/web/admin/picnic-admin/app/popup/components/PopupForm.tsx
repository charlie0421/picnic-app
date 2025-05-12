'use client';

import React, { useEffect } from 'react';
import dayjs from 'dayjs';
import { Form, DatePicker } from 'antd';
import ImageUpload from '@/components/features/upload';
import { getCdnImageUrl } from '@/lib/image';
import type { FormProps } from 'antd';
import MultilingualInput from '@/app/faqs/components/MultilingualInput';

interface PopupFormProps {
  formProps: FormProps<any>;
}

export const PopupForm: React.FC<PopupFormProps> = ({ formProps }) => {
  const { form, initialValues } = formProps;

  useEffect(() => {
    if (form && initialValues) {
      form.setFieldsValue(initialValues);
    }
  }, [form, initialValues]);

  return (
    <Form {...formProps} layout='vertical' initialValues={initialValues}>
      <MultilingualInput name='title' label='제목' required baseLocale='ko' />
      <MultilingualInput name='content' label='내용' required baseLocale='ko' />
      <Form.Item
        name='start_at'
        label='시작 일시'
        rules={[{ required: true, message: '시작 일시를 선택해주세요.' }]}
        getValueProps={(value) => ({ value: value ? dayjs(value) : undefined })}
      >
        <DatePicker showTime format='YYYY-MM-DD HH:mm:ss' />
      </Form.Item>
      <Form.Item
        name='stop_at'
        label='종료 일시'
        rules={[{ required: true, message: '종료 일시를 선택해주세요.' }]}
        getValueProps={(value) => ({ value: value ? dayjs(value) : undefined })}
      >
        <DatePicker showTime format='YYYY-MM-DD HH:mm:ss' />
      </Form.Item>
      <Form.Item
        label='이미지(한국어)'
        name={['image', 'ko']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
      >
        <ImageUpload folder='popup' />
      </Form.Item>
      <Form.Item
        label='이미지(영어)'
        name={['image', 'en']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
      >
        <ImageUpload folder='popup' />
      </Form.Item>
      <Form.Item
        label='이미지(일본어)'
        name={['image', 'ja']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
      >
        <ImageUpload folder='popup' />
      </Form.Item>
      <Form.Item
        label='이미지(중국어)'
        name={['image', 'zh']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
      >
        <ImageUpload folder='popup' />
      </Form.Item>
      <Form.Item
        label='이미지(인도네시아어)'
        name={['image', 'id']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
      >
        <ImageUpload folder='popup' />
      </Form.Item>
    </Form>
  );
};

export default PopupForm;
