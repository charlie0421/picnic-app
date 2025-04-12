'use client';

import { DateField } from '@refinedev/antd';
import { Typography, Descriptions } from 'antd';

const { Text } = Typography;

interface AdminUserRolesDetailProps {
  record?: any;
  loading?: boolean;
}

export default function AdminUserRolesDetail({ record, loading }: AdminUserRolesDetailProps) {
  if (!record && !loading) {
    return <div>사용자 역할 정보를 찾을 수 없습니다.</div>;
  }

  const descriptionsItems = [
    {
      key: 'id',
      label: '사용자 역할 ID',
      children: <Text>{record?.id}</Text>,
    },
    {
      key: 'user_id',
      label: '사용자 ID',
      children: <Text>{record?.user_id}</Text>,
    },
    {
      key: 'role_id',
      label: '역할 ID',
      children: <Text>{record?.role_id}</Text>,
    },
    {
      key: 'created-at',
      label: '생성일',
      children: (
        <DateField value={record?.created_at} format='YYYY-MM-DD' />
      ),
    },
    {
      key: 'updated-at',
      label: '수정일',
      children: (
        <DateField value={record?.updated_at} format='YYYY-MM-DD' />
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