'use client';

import { Form, Input } from 'antd';
import { useForm } from '@refinedev/antd';
import { AdminRole } from '@/types/permission';

type RoleFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<AdminRole>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<AdminRole>>['saveButtonProps'];
  onFinish?: (values: AdminRole) => Promise<any>;
  redirectPath?: string;
};

export default function RoleForm({
  mode,
  formProps,
  saveButtonProps,
}: RoleFormProps) {
  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={formProps.initialValues || {}}
    >
      <Form.Item
        label='역할 이름'
        name='name'
        rules={[
          {
            required: true,
            message: '역할 이름을 입력해 주세요',
          },
        ]}
      >
        <Input placeholder='역할 이름을 입력하세요' />
      </Form.Item>

      <Form.Item
        label='설명'
        name='description'
        rules={[
          {
            required: true,
            message: '역할에 대한 설명을 입력해 주세요',
          },
        ]}
      >
        <Input.TextArea placeholder='역할에 대한 설명을 입력하세요' rows={4} />
      </Form.Item>
    </Form>
  );
}
