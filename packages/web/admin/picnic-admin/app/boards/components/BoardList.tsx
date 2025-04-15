import { Table, Space, Tag, Tooltip, Typography, Empty } from 'antd';
import { DateField } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { MultiLanguageDisplay } from '@/components/ui';
import { Board } from '../../../lib/types/board';

interface BoardListProps {
  tableProps: any;
}

export const BoardList: React.FC<BoardListProps> = ({ tableProps }) => {
  const { show } = useNavigation();

  if (!tableProps?.dataSource || tableProps.dataSource.length === 0) {
    return <Empty description="데이터가 없습니다" />;
  }

  return (
    <Table
      {...tableProps}
      rowKey="board_id"
      scroll={{ x: 'max-content' }}
      onRow={(record: Board) => ({
        style: { cursor: 'pointer' },
        onClick: () => show('boards', record.board_id),
      })}
      pagination={{
        ...tableProps.pagination,
        showSizeChanger: true,
        pageSizeOptions: ['10', '20', '50'],
        showTotal: (total) => `총 ${total}개 항목`,
      }}
    >
      <Table.Column
        dataIndex="board_id"
        title="ID"
        width={100}
        ellipsis={true}
        sorter
        render={(value) => <Tag>{value.toString().slice(0, 8)}...</Tag>}
      />
      <Table.Column
        dataIndex="name"
        title="이름"
        sorter
        render={(value) => <MultiLanguageDisplay languages={["ko"]} value={value} />}
      />
      <Table.Column
        dataIndex="status"
        title="상태"
        width={120}
        sorter
        render={(value: string) => (
          <Tag
            color={
              value === 'ACTIVE'
                ? 'green'
                : value === 'PENDING'
                ? 'orange'
                : value === 'REJECTED'
                ? 'red'
                : 'default'
            }
          >
            {value}
          </Tag>
        )}
      />
      <Table.Column
        dataIndex="is_official"
        title="공식 게시판"
        width={120}
        sorter
        render={(value: boolean) => (
          <Tag color={value ? 'blue' : 'default'}>
            {value ? '공식' : '비공식'}
          </Tag>
        )}
      />
      <Table.Column 
        title="아티스트" 
        width={120} 
        dataIndex={['artist', 'name', 'ko']}
        render={(_, record: Board) => (
          record.artist ? (
            <MultiLanguageDisplay languages={["ko"]} value={record.artist.name} />
          ) : (
            '-'
          )
        )}
      />
      <Table.Column
        dataIndex="created_at"
        title="생성일"
        width={180}
        sorter
        defaultSortOrder="descend"
        render={(value) => (
          <DateField value={value} format="YYYY-MM-DD HH:mm:ss" />
        )}
      />
    </Table>
  );
}; 