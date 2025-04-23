'use client';

import { CreateButton, List, useTable } from '@refinedev/antd';
import { Space, Input, Alert, Form, Select } from 'antd';
import { useState, useEffect } from 'react';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useResource } from '@refinedev/core';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { FAQList } from './components';
import { FAQ } from '../../lib/types/faq';

export default function FAQListPage() {
  const { resource } = useResource();

  return (
    <AuthorizePage resource='faqs' action='list'>
      <List
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label || 'FAQ'}
      >
        <FAQList />
      </List>
    </AuthorizePage>
  );
}
