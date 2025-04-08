import React from 'react';
import { Typography, Image, Card, Space, Tag, Row, Col } from 'antd';
import { ArtistGroup } from '@/lib/types/artist';
import { getImageUrl } from '@/lib/image';
import {
  CalendarOutlined,
  TeamOutlined,
  GlobalOutlined,
} from '@ant-design/icons';

const { Text, Title } = Typography;

interface ArtistGroupDisplayProps {
  group: ArtistGroup;
  showImage?: boolean;
}

/**
 * 아티스트 그룹 정보를 보여주는 컴포넌트
 * 그룹 이름을 4개 언어(한국어, 영어, 일본어, 중국어)로 표시하고
 * 옵션에 따라 그룹 이미지도 표시
 */
const ArtistGroupDisplay: React.FC<ArtistGroupDisplayProps> = ({
  group,
  showImage = true,
}) => {
  if (!group) {
    return <Text type='secondary'>그룹 정보 없음</Text>;
  }

  // name 객체가 없는 경우 처리
  if (!group.name) {
    console.warn('Group name object is missing:', group);
    return <Text type='secondary'>그룹 이름 정보 없음</Text>;
  }

  // 데뷔일 포맷팅
  const getDebutDateDisplay = () => {
    if (!group.debut_yy) return null;

    let debutDate = `${group.debut_yy}년`;
    if (group.debut_mm) {
      debutDate += ` ${group.debut_mm}월`;
      if (group.debut_dd) {
        debutDate += ` ${group.debut_dd}일`;
      }
    }
    return debutDate;
  };

  const debutDate = getDebutDateDisplay();

  // 이름 필드가 객체가 아닌 경우를 처리
  const nameKo =
    typeof group.name === 'object' ? group.name.ko : String(group.name);
  const nameEn = typeof group.name === 'object' ? group.name.en : '';
  const nameJa = typeof group.name === 'object' ? group.name.ja : '';
  const nameZh = typeof group.name === 'object' ? group.name.zh : '';

  return (
    <Card
      size='small'
      variant='outlined'
      style={{ width: '100%', marginBottom: 16 }}
    >
      <Row gutter={16} align='middle'>
        {showImage && group.image && (
          <Col xs={24} sm={6} md={5} lg={4}>
            <Image
              src={getImageUrl(group.image)}
              alt={nameKo || '그룹 이미지'}
              style={{
                width: '100%',
                maxWidth: 120,
                objectFit: 'cover',
                borderRadius: 4,
              }}
            />
          </Col>
        )}

        <Col
          xs={24}
          sm={showImage && group.image ? 18 : 24}
          md={showImage && group.image ? 19 : 24}
          lg={showImage && group.image ? 20 : 24}
        >
          <div style={{ marginBottom: 8 }}>
            <Title level={5} style={{ margin: 0 }}>
              <TeamOutlined style={{ marginRight: 8 }} />
              {nameKo || '이름 없음'}
              {nameEn && (
                <Text
                  type='secondary'
                  style={{ marginLeft: 8, fontWeight: 'normal', fontSize: 14 }}
                >
                  ({nameEn})
                </Text>
              )}
            </Title>
            {debutDate && (
              <Tag color='blue' style={{ marginTop: 8 }}>
                <CalendarOutlined style={{ marginRight: 4 }} />
                데뷔: {debutDate}
              </Tag>
            )}
          </div>

          <Row gutter={[16, 8]}>
            <Col xs={24} md={12}>
              <Space>
                <Text strong>🇰🇷</Text>
                <Text>{nameKo || '-'}</Text>
              </Space>
            </Col>
            <Col xs={24} md={12}>
              <Space>
                <Text strong>🇺🇸</Text>
                <Text>{nameEn || '-'}</Text>
              </Space>
            </Col>
            <Col xs={24} md={12}>
              <Space>
                <Text strong>🇯🇵</Text>
                <Text>{nameJa || '-'}</Text>
              </Space>
            </Col>
            <Col xs={24} md={12}>
              <Space>
                <Text strong>🇨🇳</Text>
                <Text>{nameZh || '-'}</Text>
              </Space>
            </Col>
          </Row>
        </Col>
      </Row>
    </Card>
  );
};

export default ArtistGroupDisplay;
