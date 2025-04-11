'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Form, Input, Button, message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Edit } from '@refinedev/antd';
import { createSupabaseClient } from '../../supabase';

interface Props {
  resource: string;
  id: string;
}

export function ResourceEdit({ resource, id }: Props) {
  const router = useRouter();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(resource);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const result = await supabase.getById(id);
        form.setFieldsValue(result);
      } catch (error) {
        message.error('데이터를 불러오는데 실패했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id, form]);

  const onFinish = async (values: any) => {
    setLoading(true);
    try {
      await supabase.update(id, values);
      message.success('수정되었습니다.');
      router.push(`/${resource}`);
    } catch (error) {
      message.error('수정에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthorizePage resource={resource} action='edit'>
      <Edit
        isLoading={loading}
        title="수정"
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
      </Edit>
    </AuthorizePage>
  );
} 