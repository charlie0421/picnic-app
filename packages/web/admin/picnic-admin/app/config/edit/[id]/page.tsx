'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import ConfigForm from '@/app/config/components/ConfigForm';
import { Config } from '@/lib/types/config';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';

export default function ConfigEdit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps } = useForm<Config>({
    resource: 'config',
    id,
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
  });

  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  return (
    <AuthorizePage resource='config' action='edit'>
      <Edit
        breadcrumb={false}
        
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <ConfigForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
