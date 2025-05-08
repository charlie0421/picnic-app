'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Select, InputNumber, Button, Space } from 'antd';
import { useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import MultilingualInput from '../../components/MultilingualInput';
import {
  convertFAQToFormData,
  FAQ,
  FAQFormData,
  convertFormDataToFAQ,
} from '@/lib/types/faq';

const { Option } = Select;

export default function FAQEditPage({ params }: { params: { id: string } }) {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult, onFinish } = useForm({
    resource: 'faqs',
    action: 'edit',
    id: params.id,
    redirect: 'show',
  });

  // 데이터 로드 후 폼 필드 설정
  useEffect(() => {
    if (queryResult?.data?.data) {
      const faq = queryResult.data.data as FAQ;
      const formData = convertFAQToFormData(faq);

      // 폼 필드 값 설정
      formProps.form?.setFieldsValue(formData);
    }
  }, [queryResult?.data?.data, formProps.form]);

  // 폼 제출 핸들러
  const handleSubmit = async (values: any) => {
    // 다국어 객체로 변환
    const faqData = values as FAQFormData;
    const submitData = convertFormDataToFAQ(faqData);

    return onFinish(submitData);
  };

  // FAQ 카테고리 목록 (실제로는 데이터베이스에서 가져와야 함)
  const categoryOptions = [
    { label: '일반', value: 'GENERAL' },
    { label: '계정', value: 'ACCOUNT' },
    { label: '서비스', value: 'SERVICE' },
    { label: '결제', value: 'PAYMENT' },
    { label: '기타', value: 'ETC' },
  ];

  return (
    <AuthorizePage resource='faqs' action='edit'>
      <Edit
        title='FAQ 수정'
        footerButtons={
          <>
            <Button onClick={goBack}>취소</Button>
            <Button type='primary' {...saveButtonProps}>
              저장
            </Button>
          </>
        }
      >
        <Form {...formProps} layout='vertical' onFinish={handleSubmit}>
          {/* 다국어 질문 입력 */}
          <MultilingualInput
            name='question'
            label='질문'
            required
            baseLocale='ko'
          />

          {/* 다국어 답변 입력 */}
          <MultilingualInput
            name='answer'
            label='답변'
            required
            baseLocale='ko'
            useRichText
          />

          <Space>
            <Form.Item label='카테고리' name='category'>
              <Select style={{ width: 150 }}>
                {categoryOptions.map((option) => (
                  <Option key={option.value} value={option.value}>
                    {option.label}
                  </Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item label='상태' name='status' rules={[{ required: true }]}>
              <Select style={{ width: 150 }}>
                <Option value='DRAFT'>초안</Option>
                <Option value='PUBLISHED'>발행</Option>
                <Option value='ARCHIVED'>보관</Option>
              </Select>
            </Form.Item>

            <Form.Item
              label='정렬 순서'
              name='order_number'
              rules={[{ required: true }]}
            >
              <InputNumber min={0} style={{ width: 100 }} />
            </Form.Item>
          </Space>
        </Form>
      </Edit>
    </AuthorizePage>
  );
}
