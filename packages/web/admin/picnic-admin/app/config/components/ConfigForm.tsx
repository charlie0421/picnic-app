'use client';

import { Form, Input } from 'antd';
import { useForm } from '@refinedev/antd';
import { Config } from '@/lib/types/config';

type ConfigFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<Config>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<Config>>['saveButtonProps'];
};

export default function ConfigForm({
  mode,
  formProps,
  saveButtonProps,
}: ConfigFormProps) {
  return (
    <Form {...formProps} layout='vertical'>
      <Form.Item
        label='키'
        name='key'
        rules={[{ required: true, message: '키를 입력해주세요' }]}
      >
        <Input />
      </Form.Item>

      <Form.Item
        label='값'
        name='value'
        rules={[{ required: true, message: '값을 입력해주세요' }]}
      >
        <Input.TextArea rows={4} />
      </Form.Item>
    </Form>
  );
}
