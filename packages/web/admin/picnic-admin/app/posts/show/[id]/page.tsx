'use client';

import { useShow, useResource } from '@refinedev/core';
import { Show } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Post } from '../../../../lib/types/post';
import { useParams } from 'next/navigation';
import { PostDetail } from '../../components';

export default function PostShowPage() {
  const params = useParams();
  const id = params.id as string;

  const { queryResult } = useShow<Post>({
    resource: 'posts',
    id,
    meta: {
      idField: 'post_id',
      select: '*,user_profiles!posts_user_id_fkey(*),boards!posts_board_id_fkey(*, artist(*))',
    },
  });
  
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();

  return (
    <AuthorizePage resource='posts' action='show'>
      <Show
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        isLoading={isLoading}
      >
        <PostDetail 
          record={record} 
        />
      </Show>
    </AuthorizePage>
  );
}
