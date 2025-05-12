'use client';

import { CreateButton, List } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { PopupList } from './components';

export default function PopupListPage() {
  const { resource } = useResource();

  return (
    <AuthorizePage resource='popup' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '팝업'}
      >
        <PopupList />
      </List>
    </AuthorizePage>
  );
}
