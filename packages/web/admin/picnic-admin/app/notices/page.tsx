'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form, Button } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { NoticeList } from './components/index';
import { Notice } from '../../lib/types/notice';

export default function NoticeListPage() {

  const { resource } = useResource();

  return (
    <AuthorizePage resource='notices' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label}
      >
        <NoticeList />
      </List>
    </AuthorizePage>
  );
} 