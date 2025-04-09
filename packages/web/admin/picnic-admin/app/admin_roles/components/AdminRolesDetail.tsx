'use client';

import { DateField } from '@refinedev/antd';
import { Typography, Descriptions } from 'antd';
import { AdminRole } from '@/lib/types/permission';

const { Text } = Typography;

interface AdminRolesDetailProps {
  record?: AdminRole;
  loading?: boolean;
}

export default function AdminRolesDetail({ record, loading }: AdminRolesDetailProps) {
  if (!record && !loading) {
    return <div>역할 정보를 찾을 수 없습니다.</div>;
  }

  const descriptionsItems = [
    {
      key: 'id',
      label: 'ID',
      children: <Text>{record?.id}</Text>,
    },
    {
      key: 'name',
      label: '역할 이름',
      children: <Text>{record?.name}</Text>,
    },
    {
      key: 'description',
      label: '설명',
      children: <Text>{record?.description}</Text>,
    },
    {
      key: 'created-at',
      label: '생성일',
      children: (
        <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      key: 'updated-at',
      label: '수정일',
      children: (
        <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  return (
    <Descriptions
      bordered
      column={1}
      layout='vertical'
      items={descriptionsItems}
    />
  );
} 