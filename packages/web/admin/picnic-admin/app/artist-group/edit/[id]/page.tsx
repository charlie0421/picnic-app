'use client';

import { Edit, useForm } from '@refinedev/antd';
import { useParams } from 'next/navigation';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import ArtistGroupForm from '@/app/artist-group/components/ArtistGroupForm';

export default function ArtistGroupEdit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'artist_group',
    id: id,
    meta: {
      select: '*',
    },
    action: 'edit',
  });

  const { resource } = useResource();
  
  return (
    <AuthorizePage resource='artist_group' action='edit'>
      <Edit
        breadcrumb={false}
        
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
        <ArtistGroupForm
          mode="edit"
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}
