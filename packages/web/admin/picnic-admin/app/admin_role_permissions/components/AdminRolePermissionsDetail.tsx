'use client';

import { DateField } from '@refinedev/antd';
import { Typography, Descriptions } from 'antd';

const { Text } = Typography;

interface AdminRolePermissionsDetailProps {
  record?: any;
  loading?: boolean;
}

export default function AdminRolePermissionsDetail({ record, loading }: AdminRolePermissionsDetailProps) {
  if (!record && !loading) {
    return <div>역할 권한 정보를 찾을 수 없습니다.</div>;
  }

  const descriptionsItems = [
    {
      key: 'id',
      label: '역할 권한 ID',
      children: <Text>{record?.id}</Text>,
    },
    {
      key: 'role_id',
      label: '역할 ID',
      children: <Text>{record?.role_id}</Text>,
    },
    {
      key: 'permission_id',
      label: '권한 ID',
      children: <Text>{record?.permission_id}</Text>,
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