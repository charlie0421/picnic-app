import React from 'react';
import { Space, Typography, Button, message } from 'antd';
import { CopyOutlined } from '@ant-design/icons';

const { Text } = Typography;

interface UUIDDisplayProps {
  uuid: string;
  label?: string;
}

export const UUIDDisplay: React.FC<UUIDDisplayProps> = ({ 
  uuid,
  label = 'ID'
}) => {
  const handleCopy = () => {
    navigator.clipboard.writeText(uuid)
      .then(() => {
        message.success('ID가 클립보드에 복사되었습니다.');
      })
      .catch(() => {
        message.error('ID 복사에 실패했습니다.');
      });
  };

  return (
    <Space>
      <Text type="secondary">{label}:</Text>
      <Text code copyable={false}>{uuid}</Text>
      <Button 
        icon={<CopyOutlined />} 
        size="small"
        onClick={handleCopy}
        title="ID 복사"
      />
    </Space>
  );
}; 