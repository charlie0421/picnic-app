'use client';

import { Create, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupForm from '@/app/artist-group/components/ArtistGroupForm';

export default function ArtistGroupCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm({
    resource: 'artist_group',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('아티스트 그룹이 성공적으로 생성되었습니다');
    },
  });

  return (
    <AuthorizePage resource='artist_group' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <ArtistGroupForm
          mode='create'
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
