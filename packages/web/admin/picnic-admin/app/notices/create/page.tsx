'use client';

import { Create, useForm, useSelect } from '@refinedev/antd';
import { Form, Input, Select, Switch, Alert, Button, Space } from 'antd';
import { useGetIdentity, useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import TextEditor from '@/components/ui/TextEditor';

const { Option } = Select;

export default function NoticeCreatePage() {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult, onFinish } = useForm({
    resource: 'notices',
    redirect: 'list',
    meta: {
      idField: 'notice_id',
    },
  });

  const { data: identity } = useGetIdentity<{ id: string }>();

  useEffect(() => {
    // 폼 초기값 설정
    formProps.form?.setFieldsValue({
      status: 'DRAFT', // 기본값 초안
      is_pinned: false, // 기본값 일반 공지
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
    <AuthorizePage resource="notices" action="create">
      <Create
        title="공지사항 작성"
        footerButtons={
          <>
            <Button onClick={goBack}>취소</Button>
            <Button 
              type="primary" 
              {...saveButtonProps}
            >
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
            label="내용"
            name="content"
            rules={[{ required: true, message: '내용을 입력해주세요' }]}
          >
            <TextEditor />
          </Form.Item>

          <Space>
            <Form.Item
              label="상태"
              name="status"
              rules={[{ required: true }]}
            >
              <Select style={{ width: 200 }}>
                <Option value="DRAFT">초안</Option>
                <Option value="PUBLISHED">발행</Option>
                <Option value="ARCHIVED">보관</Option>
              </Select>
            </Form.Item>

            <Form.Item
              label="상단 고정"
              name="is_pinned"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>
          </Space>
        </Form>
      </Create>
    </AuthorizePage>
  );
} 