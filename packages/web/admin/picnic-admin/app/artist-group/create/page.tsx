'use client';

import { Create, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupForm from '@/app/artist-group/components/ArtistGroupForm';

export default function ArtistGroupCreate() {
  const { formProps, saveButtonProps } = useForm({
    resource: 'artist_group',
  });

  const { resource } = useResource();

  return (
    <AuthorizePage resource='artist_group' action='create'>
      <Create
        breadcrumb={false}
        
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        <ArtistGroupForm
          mode="create"
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}
