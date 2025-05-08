'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { Version } from '@/lib/types/version';
import VersionForm from '../components/VersionForm';

export default function VersionCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm<Version>({
    resource: 'version',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('버전이 성공적으로 생성되었습니다');
    },
  });

  return (
    <AuthorizePage resource='version' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <VersionForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
