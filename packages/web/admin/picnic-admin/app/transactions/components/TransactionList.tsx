import { Table, Tag } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { Transaction } from '@/lib/types/transactions';
import dayjs from 'dayjs';

interface TransactionListProps {
  data?: Transaction[];
  loading?: boolean;
}

const sourceColorMap = {
  admob: 'blue',
  pangle: 'green',
  pincrux: 'purple',
  tapjoy: 'orange',
  unity: 'cyan',
};

export const TransactionList: React.FC<TransactionListProps> = ({ data, loading }) => {
  const columns: ColumnsType<Transaction> = [
    {
      title: '광고 플랫폼',
      dataIndex: 'source',
      key: 'source',
      render: (source: keyof typeof sourceColorMap) => (
        <Tag color={sourceColorMap[source]}>{source.toUpperCase()}</Tag>
      ),
    },
    {
      title: '리워드 타입',
      dataIndex: 'reward_type',
      key: 'reward_type',
    },
    {
      title: '리워드 금액',
      dataIndex: 'reward_amount',
      key: 'reward_amount',
      render: (amount: number) => amount.toLocaleString(),
    },
    {
      title: '광고 네트워크',
      dataIndex: 'ad_network',
      key: 'ad_network',
    },
    {
      title: '플랫폼',
      dataIndex: 'platform',
      key: 'platform',
    },
    {
      title: '리워드 이름',
      dataIndex: 'reward_name',
      key: 'reward_name',
    },
    {
      title: '수수료',
      dataIndex: 'commission',
      key: 'commission',
      render: (commission: number | null) => commission?.toLocaleString() ?? '-',
    },
    {
      title: '생성일',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => dayjs(date).format('YYYY-MM-DD HH:mm:ss'),
    },
  ];

  return (
    <Table
      columns={columns}
      dataSource={data}
      loading={loading}
      rowKey="transaction_id"
      scroll={{ x: true }}
    />
  );
}; 