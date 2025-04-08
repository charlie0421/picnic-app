'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import ConfigForm from '@/app/config/components/ConfigForm';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ConfigCreate() {
  const { formProps, saveButtonProps } = useForm<Config>({
    resource: 'config',
  });
  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource='config' action='create'>
      <Create saveButtonProps={saveButtonProps}>
        {contextHolder}
        <ConfigForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
