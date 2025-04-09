'use client';

import { DateField } from '@refinedev/antd';
import { Typography, Space, Descriptions } from 'antd';

const { Title, Text } = Typography;

interface AdminPermissionsDetailProps {
  record?: any;
  loading?: boolean;
}

export default function AdminPermissionsDetail({ record, loading }: AdminPermissionsDetailProps) {
  if (!record && !loading) {
    return <div>권한 정보를 찾을 수 없습니다.</div>;
  }
  
  const descriptionsItems = [
    {
      key: 'id',
      label: '권한 ID',
      children: <Text>{record?.id}</Text>,
    },
    {
      key: 'name',
      label: '권한 이름',
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