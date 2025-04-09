'use client';

import {
  Show,
  DeleteButton,
  EditButton,
} from '@refinedev/antd';
import { useShow, useNavigation, useResource } from '@refinedev/core';
import {
  Skeleton,
  Button,
} from 'antd';
import React from 'react';
import {
  EditOutlined,
  DeleteOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import MediaDetail from '@/app/media/components/MediaDetail';

export default function MediaShow() {
  const { queryResult } = useShow();
  const { data, isLoading } = queryResult;

  const { edit, list } = useNavigation();
  const id = data?.data?.id;

  const { resource } = useResource();

  if (isLoading) {
    return (
      <AuthorizePage resource='media' action='show'>
        <Skeleton active paragraph={{ rows: 10 }} />
      </AuthorizePage>
    );
  }

  return (
    <AuthorizePage resource='media' action='show'>
      <Show
        isLoading={isLoading}
        breadcrumb={false}
        
        title={resource?.meta?.label}
      >
        <MediaDetail record={data?.data} loading={isLoading} />
      </Show>
    </AuthorizePage>
  );
}
