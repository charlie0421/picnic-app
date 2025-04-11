'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Form, Input, Button, message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Create } from '@refinedev/antd';
import { createSupabaseClient } from '../../supabase';

interface Props {
  resource: string;
}

export function ResourceCreate({ resource }: Props) {
  const router = useRouter();
  const supabase = createSupabaseClient(resource);
  const [form] = Form.useForm();

  const onFinish = async (values: any) => {
    try {
      await supabase.create(values);
      message.success('생성되었습니다.');
      router.push(`/${resource}`);
    } catch (error) {
      message.error('생성에 실패했습니다.');
    }
  };

  return (
    <AuthorizePage resource={resource} action='create'>
      <Create
        title="새로 만들기"
        saveButtonProps={{
          onClick: form.submit,
        }}
        headerButtons={({ defaultButtons }) => (
          <Button onClick={() => router.push(`/${resource}`)}>목록으로</Button>
        )}
      >
        <Form form={form} layout='vertical' onFinish={onFinish}>
          <Form.Item
            label='이름'
            name='name'
            rules={[{ required: true, message: '이름을 입력해주세요.' }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            label='설명'
            name='description'
            rules={[{ required: true, message: '설명을 입력해주세요.' }]}
          >
            <Input.TextArea rows={4} />
          </Form.Item>
        </Form>
      </Create>
    </AuthorizePage>
  );
} 