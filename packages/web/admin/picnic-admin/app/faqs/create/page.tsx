'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, Input, Select, InputNumber, Button, Space } from 'antd';
import { useGetIdentity, useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import TextEditor from '@/components/ui/TextEditor';

const { Option } = Select;
const { TextArea } = Input;

export default function FAQCreatePage() {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult, onFinish } = useForm({
    resource: 'faqs',
    redirect: 'list',
    meta: {
      idField: 'faq_id',
    },
  });

  const { data: identity } = useGetIdentity<{ id: string }>();

  useEffect(() => {
    // 폼 초기값 설정
    formProps.form?.setFieldsValue({
      status: 'DRAFT', // 기본값 초안
      order_number: 0, // 기본 정렬 순서
      category: '일반', // 기본 카테고리
    });
  }, [formProps.form]);

  // 폼 제출 핸들러
  const handleSubmit = async (values: any) => {
    // 현재 사용자 ID 추가
    const submitValues = {
      ...values,
      created_by: identity?.id,
    };

    return onFinish(submitValues);
  };

  // FAQ 카테고리 목록 (실제로는 데이터베이스에서 가져와야 함)
  const categoryOptions = [
    { label: '일반', value: '일반' },
    { label: '계정', value: '계정' },
    { label: '서비스', value: '서비스' },
    { label: '결제', value: '결제' },
    { label: '기타', value: '기타' },
  ];

  return (
    <AuthorizePage resource="faqs" action="create">
      <Create
        title="FAQ 작성"
        footerButtons={
          <>
            <Button onClick={goBack}>취소</Button>
            <Button type="primary" {...saveButtonProps}>
              저장
            </Button>
          </>
        }
      >
        <Form 
          {...formProps} 
          layout="vertical"
          onFinish={handleSubmit}
        >
          <Form.Item
            label="질문"
            name="question"
            rules={[{ required: true, message: '질문을 입력해주세요' }]}
          >
            <Input placeholder="질문을 입력하세요" />
          </Form.Item>

          <Form.Item
            label="답변"
            name="answer"
            rules={[{ required: true, message: '답변을 입력해주세요' }]}
          >
            <TextEditor />
          </Form.Item>

          <Space>
            <Form.Item
              label="카테고리"
              name="category"
            >
              <Select style={{ width: 150 }}>
                {categoryOptions.map(option => (
                  <Option key={option.value} value={option.value}>{option.label}</Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              label="상태"
              name="status"
              rules={[{ required: true }]}
            >
              <Select style={{ width: 150 }}>
                <Option value="DRAFT">초안</Option>
                <Option value="PUBLISHED">발행</Option>
                <Option value="ARCHIVED">보관</Option>
              </Select>
            </Form.Item>

            <Form.Item
              label="정렬 순서"
              name="order_number"
              rules={[{ required: true }]}
            >
              <InputNumber min={0} style={{ width: 100 }} />
            </Form.Item>
          </Space>
        </Form>
      </Create>
    </AuthorizePage>
  );
} 