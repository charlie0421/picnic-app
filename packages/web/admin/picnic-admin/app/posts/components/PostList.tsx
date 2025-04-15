import { Table, Space, Tag, Tooltip, Avatar } from 'antd';
import { DateField } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { UserOutlined } from '@ant-design/icons';

interface PostListProps {
  tableProps: any;
}

export const PostList: React.FC<PostListProps> = ({ tableProps }) => {
  const { show } = useNavigation();

  return (
    <Table
      {...tableProps}
      rowKey="post_id"
      scroll={{ x: 'max-content' }}
      onRow={(record) => ({
        style: { cursor: 'pointer' },
        onClick: () => show('posts', record.post_id),
      })}
      pagination={{
        ...tableProps.pagination,
        showSizeChanger: true,
        pageSizeOptions: ['10', '20', '50'],
        showTotal: (total) => `총 ${total}개 항목`,
      }}
    >
      <Table.Column
        dataIndex="post_id"
        title="ID"
        width={100}
        ellipsis={true}
        render={(value: string) => (
          <Tooltip title={value}>
            <span>{value.substring(0, 10)}...</span>
          </Tooltip>
        )}
      />
      <Table.Column dataIndex="title" title="제목" sorter render={(value: string) => (
          <Tooltip title={value}>
            <span>{value.substring(0, 20)}...</span>
          </Tooltip>
        )}
      />
      <Table.Column dataIndex="title" title="제목" sorter />
      <Table.Column
        dataIndex="user_id"
        title="작성자"
        width={150}
        render={(user_id: string, record: any) => {
          // 익명 게시글인 경우
          if (record.is_anonymous) {
            return (
              <Space>
                <Avatar icon={<UserOutlined />} size="small" />
                <Tag color="blue">익명</Tag>
              </Space>
            );
          }

          // 조인된 사용자 프로필 정보 사용
          const userProfile = record.user_profiles;
          if (userProfile) {
            return (
              <Tooltip title={`ID: ${user_id}`}>
                <Space>
                  {userProfile.avatar_url ? (
                    <Avatar 
                      src={userProfile.avatar_url} 
                      size="small" 
                      alt={userProfile.nickname || userProfile.name || '사용자'} 
                    />
                  ) : (
                    <Avatar icon={<UserOutlined />} size="small" />
                  )}
                  {userProfile.nickname || userProfile.name || user_id}
                </Space>
              </Tooltip>
            );
          }

          return (
            <Space>
              <Avatar icon={<UserOutlined />} size="small" />
              {user_id}
            </Space>
          );
        }}
      />
      <Table.Column
        dataIndex="view_count"
        title="조회수"
        width={100}
        sorter
      />
      <Table.Column
        dataIndex="reply_count"
        title="댓글수"
        width={100}
        sorter
      />
      <Table.Column
        dataIndex="is_anonymous"
        title="익명 여부"
        width={120}
        render={(value: boolean) => (
          <Tag color={value ? "blue" : "default"}>
            {value ? "익명" : "실명"}
          </Tag>
        )}
      />
      <Table.Column
        dataIndex="is_hidden"
        title="숨김 여부"
        width={120}
        render={(value: boolean) => (
          <Tag color={value ? "red" : "green"}>
            {value ? "숨김" : "표시"}
          </Tag>
        )}
      />
      <Table.Column
        dataIndex="created_at"
        title="생성일"
        width={200}
        sorter
        render={(value) => (
          <DateField value={value} format="YYYY-MM-DD HH:mm:ss" />
        )}
      />
    </Table>
  );
}; 