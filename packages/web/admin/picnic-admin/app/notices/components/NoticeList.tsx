import React from 'react';
import { Table, Space, Button, Tag } from 'antd';
import { useNavigation, useDelete } from '@refinedev/core';
import { EditButton, ShowButton, DeleteButton, DateField } from '@refinedev/antd';
import { TableProps } from 'antd/es/table';
import { Notice } from '@/lib/types/notice';

interface NoticeListProps {
  tableProps: TableProps<Notice>;
}

export const NoticeList: React.FC<NoticeListProps> = ({ tableProps }) => {
  const { show, edit } = useNavigation();
  const { mutate: deleteMutate } = useDelete();

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: '제목',
      dataIndex: 'title',
      key: 'title',
      render: (value: string, record: Notice) => (
        <Space>
          {record.is_pinned && <Tag color="red">공지</Tag>}
          <span style={{ cursor: 'pointer' }} onClick={() => show('notices', record.id)}>
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
        if (value === 'PUBLISHED') color = 'green';
        if (value === 'DRAFT') color = 'gold';
        if (value === 'ARCHIVED') color = 'gray';
        
        return <Tag color={color}>{value}</Tag>;
      },
    },
    {
      title: '작성자',
      key: 'created_by',
      width: 120,
      render: (_: any, record: Notice) => {
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
      title: '액션',
      key: 'actions',
      width: 120,
      render: (_: any, record: Notice) => (
        <Space>
          <ShowButton size="small" recordItemId={record.id} />
          <EditButton size="small" recordItemId={record.id} />
          <DeleteButton
            size="small"
            recordItemId={record.id}
            resource="notices"
          />
        </Space>
      ),
    },
  ];

  return (
    <Table
      {...tableProps}
      rowKey="id"
      columns={columns}
    />
  );
}; 