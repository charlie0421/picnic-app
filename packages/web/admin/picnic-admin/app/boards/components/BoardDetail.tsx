import {
  Typography,
  Space,
  Tag,
  Divider,
  Descriptions,
  theme,
} from 'antd';
import { DateField } from '@refinedev/antd';
import { Board } from '../../../lib/types/board';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { MultiLanguageDisplay } from '@/components/ui';

const { Title, Text } = Typography;

interface BoardDetailProps {
  record?: Board;
  parentBoard?: Board | null;
}

export const BoardDetail: React.FC<BoardDetailProps> = ({
  record,
  parentBoard,
}) => {
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  if (!record) {
    return null;
  }

  return (
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        게시판 정보
      </Title>

      <Descriptions bordered column={1}>
        <Descriptions.Item label="ID">{record.board_id}</Descriptions.Item>

        <Descriptions.Item label="이름">
          <MultiLanguageDisplay value={record.name} />
        </Descriptions.Item>

        <Descriptions.Item label="설명">
          {record.description || '-'}
        </Descriptions.Item>

        <Descriptions.Item label="상태">
          <Tag
            color={
              record.status === 'ACTIVE'
                ? 'green'
                : record.status === 'PENDING'
                ? 'orange'
                : record.status === 'REJECTED'
                ? 'red'
                : 'default'
            }
          >
            {record.status}
          </Tag>
        </Descriptions.Item>

        <Descriptions.Item label="공식 게시판">
          <Tag color={record.is_official ? 'blue' : 'default'}>
            {record.is_official ? '공식' : '비공식'}
          </Tag>
        </Descriptions.Item>

        <Descriptions.Item label="상위 게시판">
          {parentBoard ? (
            <Space>
              {parentBoard.board_id}
              <Divider type="vertical" />
              <MultiLanguageDisplay value={parentBoard.name} />
            </Space>
          ) : (
            '-'
          )}
        </Descriptions.Item>

        <Descriptions.Item label="아티스트">
          {record.artist ? <MultiLanguageDisplay value={record.artist.name} /> : '-'}
        </Descriptions.Item>

        <Descriptions.Item label="신청 메시지">
          {record.request_message || '-'}
        </Descriptions.Item>

        <Descriptions.Item label="정렬 순서">{record.order}</Descriptions.Item>

        <Descriptions.Item label="기능">
          {record.features && record.features.length > 0 ? (
            <Space wrap>
              {record.features.map((feature, index) => (
                <Tag key={index}>{feature}</Tag>
              ))}
            </Space>
          ) : (
            '-'
          )}
        </Descriptions.Item>

        <Descriptions.Item label="생성일/수정일">
          <Space direction="vertical">
            <DateField
              value={record.created_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
            <DateField
              value={record.updated_at}
              format="YYYY-MM-DD HH:mm:ss"
            />
          </Space>
        </Descriptions.Item>
      </Descriptions>
    </div>
  );
}; 