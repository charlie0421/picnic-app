'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { MediaForm } from '@/components/media';

export default function MediaCreate() {
  const { formProps, saveButtonProps } = useForm({});
  const [messageApi, contextHolder] = message.useMessage();

  return (
    <Create saveButtonProps={saveButtonProps}>
      {contextHolder}
      <MediaForm
        mode='create'
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Create>
  );
}
