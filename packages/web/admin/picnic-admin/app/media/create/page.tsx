'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import MediaForm from '../components/MediaForm';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function MediaCreate() {
  const { formProps, saveButtonProps } = useForm({
    resource: 'media'
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  
  return (
    <AuthorizePage action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <MediaForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
