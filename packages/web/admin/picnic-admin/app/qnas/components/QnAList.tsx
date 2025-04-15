import React from 'react';
import { Table, Space, Button, Tag } from 'antd';
import { useNavigation, useDelete } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField } from '@refinedev/antd';
import { TableProps } from 'antd/es/table';
import { QnA } from '@/lib/types/qna';

interface QnAListProps {
  tableProps: TableProps<QnA>;
}

export const QnAList: React.FC<QnAListProps> = ({ tableProps }) => {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const columns = [
    {
      title: 'ID',
      dataIndex: 'qna_id',
      key: 'qna_id',
      width: 80,
    },
    {
      title: '제목',
      dataIndex: 'title',
      key: 'title',
      render: (value: string, record: QnA) => (
        <Space>
          {record.is_private && <Tag color="blue">비공개</Tag>}
          <span style={{ cursor: 'pointer' }} onClick={() => show('qnas', record.qna_id)}>
            {value}
          </span>
        </Space>
      ),
    },
    {
      title: '상태',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (value: string) => {
        let color = 'default';
        if (value === 'PENDING') color = 'gold';
        if (value === 'ANSWERED') color = 'green';
        if (value === 'ARCHIVED') color = 'gray';
        
        return <Tag color={color}>{value}</Tag>;
      },
    },
    {
      title: '질문자',
      key: 'created_by',
      width: 120,
      render: (_: any, record: QnA) => {
        const userName = record.created_by_user?.user_metadata?.name || record.created_by_user?.email || '시스템';
        return userName;
      },
    },
    {
      title: '작성일',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (value: string) => <DateField value={value} format="YYYY-MM-DD HH:mm" />,
    },
    {
      title: '답변일',
      dataIndex: 'answered_at',
      key: 'answered_at',
      width: 160,
      render: (value: string) => value ? <DateField value={value} format="YYYY-MM-DD HH:mm" /> : '-',
    },
    {
      title: '액션',
      key: 'actions',
      width: 120,
      render: (_: any, record: QnA) => (
        <Space>
          <ShowButton size="small" recordItemId={record.qna_id} />
          <EditButton size="small" recordItemId={record.qna_id} />
          <DeleteButton
            size="small"
            recordItemId={record.qna_id}
            resource="qnas"
          />
        </Space>
      ),
    },
  ];

  return (
    <Table
      {...tableProps}
      rowKey="qna_id"
      columns={columns}
    />
  );
}; 