'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, Input, Switch, Button, Space } from 'antd';
import { useGetIdentity, useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import TextEditor from '@/components/ui/TextEditor';

export default function QnACreatePage() {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult, onFinish } = useForm({
    resource: 'qnas',
    redirect: 'list',
    meta: {
      idField: 'qna_id',
    },
  });

  const { data: identity } = useGetIdentity<{ id: string }>();

  useEffect(() => {
    // 폼 초기값 설정
    formProps.form?.setFieldsValue({
      status: 'PENDING', // 기본값 대기중
      is_private: false, // 기본값 공개 질문
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

  return (
    <AuthorizePage resource="qnas" action="create">
      <Create
        title="질문 작성"
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
            label="제목"
            name="title"
            rules={[{ required: true, message: '제목을 입력해주세요' }]}
          >
            <Input placeholder="제목을 입력하세요" />
          </Form.Item>

          <Form.Item
            label="질문 내용"
            name="question"
            rules={[{ required: true, message: '질문 내용을 입력해주세요' }]}
          >
            <TextEditor />
          </Form.Item>

          <Form.Item
            label="비공개 질문"
            name="is_private"
            valuePropName="checked"
            help="비공개 질문은 본인과 관리자만 볼 수 있습니다."
          >
            <Switch />
          </Form.Item>
        </Form>
      </Create>
    </AuthorizePage>
  );
} 