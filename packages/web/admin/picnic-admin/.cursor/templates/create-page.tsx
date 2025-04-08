'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Form, Input, Button, message } from 'antd';
import { createSupabaseClient } from '../../lib/supabase';

export default function CreatePage() {
  const router = useRouter();
  const tableName = '${dirname}';
  const supabase = createSupabaseClient(tableName);

  const onFinish = async (values: any) => {
    try {
      await supabase.create(values);
      message.success('생성되었습니다.');
      router.push(`/${tableName}`);
    } catch (error) {
      message.error('생성에 실패했습니다.');
    }
  };

  return (
    <div className='container mx-auto py-10'>
      <div className='flex justify-between items-center mb-6'>
        <h1 className='text-3xl font-bold'>새로 만들기</h1>
        <Button onClick={() => router.push(`/${tableName}`)}>목록으로</Button>
      </div>
      <Form layout='vertical' onFinish={onFinish}>
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
          <Button type='primary' htmlType='submit'>
            저장
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
