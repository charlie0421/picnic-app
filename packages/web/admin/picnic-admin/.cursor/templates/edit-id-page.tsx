'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Form, Input, Button, message } from 'antd';
import { createSupabaseClient } from '../../lib/supabase';

export default function EditPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const tableName = '${dirname}';
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const supabase = createSupabaseClient(tableName);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const result = await supabase.getById(params.id);
        form.setFieldsValue(result);
      } catch (error) {
        message.error('데이터를 불러오는데 실패했습니다.');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [params.id, form]);

  const onFinish = async (values: any) => {
    setLoading(true);
    try {
      await supabase.update(params.id, values);
      message.success('수정되었습니다.');
      router.push(`/${tableName}`);
    } catch (error) {
      message.error('수정에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className='container mx-auto py-10'>
      <div className='flex justify-between items-center mb-6'>
        <h1 className='text-3xl font-bold'>수정</h1>
        <Button onClick={() => router.push(`/${tableName}`)}>목록으로</Button>
      </div>
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
        <Form.Item>
          <Button type='primary' htmlType='submit' loading={loading}>
            저장
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
