'use client';

import { Edit, useForm } from '@refinedev/antd';
import { useParams } from 'next/navigation';
import { useResource } from '@refinedev/core';
import { message } from 'antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupForm from '@/app/artist-group/components/ArtistGroupForm';

export default function ArtistGroupEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'artist_group',
    id: id,
    meta: {
      select: '*',
    },
    action: 'edit',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('아티스트 그룹이 성공적으로 수정되었습니다');
    },
  });

  return (
    <AuthorizePage resource='artist_group' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <ArtistGroupForm
          mode='edit'
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
