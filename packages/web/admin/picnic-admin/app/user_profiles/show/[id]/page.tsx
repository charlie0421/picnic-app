'use client';

import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { UserProfileDetail } from '@/app/user_profiles/components/';
import { useParams } from 'next/navigation';
import { EditButton } from '@refinedev/antd';
import { DeleteButton } from '@refinedev/antd';
import { Show } from '@refinedev/antd';
import { useResource, useShow } from '@refinedev/core';
import { UserProfile } from '@/lib/types/user_profiles';

export default function UserProfileShowPage() {
  const params = useParams();
  const { queryResult } = useShow<UserProfile>({
    id: params.id as string,
    resource: 'user_profiles',
    meta: {
      select: '*',
    },
  });
  const { data, isLoading } = queryResult;
  const { resource } = useResource();

  return (
    <AuthorizePage action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        headerButtons={[
          <EditButton key='edit' />,
          <DeleteButton key='delete' />,
        ]}
      >
        <UserProfileDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
