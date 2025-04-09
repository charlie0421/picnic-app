'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import MediaForm from '../components/MediaForm';
import { useResource } from '@refinedev/core';
export default function MediaCreate() {
  const { formProps, saveButtonProps } = useForm({});
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  return (
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
  );
}
