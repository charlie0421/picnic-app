'use client';

import { Typography, Descriptions, Card } from 'antd';
import { Config } from '@/lib/types/config';

const { Text } = Typography;

interface ConfigDetailProps {
  record?: Config;
  loading?: boolean;
}

export default function ConfigDetail({ record, loading }: ConfigDetailProps) {
  if (!record && !loading) {
    return <div>환경설정 정보를 찾을 수 없습니다.</div>;
  }

  const descriptionsItems = [
    {
      key: 'key',
      label: '키',
      children: <Text>{record?.key}</Text>,
    },
    {
      key: 'value',
      label: '값',
      children: <Text>{record?.value}</Text>,
    },
    {
      key: 'created-at',
      label: '생성일',
      children: (
        <Text>
          {record?.created_at && new Date(record.created_at).toLocaleString()}
        </Text>
      ),
    },
    {
      key: 'updated-at',
      label: '수정일',
      children: (
        <Text>
          {record?.updated_at && new Date(record.updated_at).toLocaleString()}
        </Text>
      ),
    },
  ];

  return (
    <Card>
      <Descriptions
        bordered
        column={1}
        layout='vertical'
        items={descriptionsItems}
      />
    </Card>
  );
} 