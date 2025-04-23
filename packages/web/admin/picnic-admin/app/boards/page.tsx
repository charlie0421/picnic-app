'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { BoardList } from './components';
import { Board } from '../../lib/types/board';

export default function BoardListPage() {
  const { resource } = useResource();
  return (
    <AuthorizePage resource='boards' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || '게시판 목록'}
      >
        <BoardList />
      </List>
    </AuthorizePage>
  );
}
