'use client';

import { DeleteButton, EditButton, Show } from '@refinedev/antd';
import { useOne, useResource } from '@refinedev/core';
import { Typography, Card, Image, Space, Row, Col, Divider } from 'antd';
import { Reward, defaultLocalizations } from './types';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageDisplay } from '@/components/ui';

const { Title, Text, Paragraph } = Typography;

interface RewardShowProps {
  id: string;
  resource?: string;
}

// 언어 라벨 헬퍼 함수
const getLanguageLabel = (locale: string): string => {
  switch (locale) {
    case 'ko':
      return '한국어';
    case 'en':
      return '영어';
    case 'ja':
      return '일본어';
    case 'zh':
      return '중국어';
    default:
      return locale;
  }
};

export default function RewardShow({ id, resource }: RewardShowProps) {
  const { data, isLoading } = useOne<Reward>({
    resource: resource || 'reward',
    id,
  });
  const record = data?.data;
  const { resource: resourceInfo } = useResource();

  // Helper function to safely convert potentially complex values to string
  const safeToString = (value: any): string => {
    if (value === null || value === undefined) return '-';
    if (typeof value === 'string') return value;
    if (typeof value === 'number') return value.toString();
    if (typeof value === 'boolean') return value ? 'true' : 'false';
    try {
      // For objects/arrays, attempt to stringify but catch any errors
      return JSON.stringify(value);
    } catch (e) {
      return '-';
    }
  };

  // 일반 텍스트 형식으로 표시
  const formatText = (text: string): string => {
    if (!text || text === '-') return '-';
    try {
      // JSON 문자열인 경우 파싱하여 포맷팅
      const jsonObject = JSON.parse(text);
      return JSON.stringify(jsonObject, null, 2);
    } catch (e) {
      // JSON이 아닌 일반 문자열이면 그대로 반환
      return text;
    }
  };

  return (
    <Show
      isLoading={isLoading}
      breadcrumb={false}
      title={resourceInfo?.meta?.show?.label}
      headerButtons={[<EditButton key='edit' />, <DeleteButton key='delete' />]}
    >
      <Card title='기본 정보' style={{ marginBottom: 20 }}>
        <div style={{ marginBottom: 20 }}>
          <Title level={5}>ID</Title>
          <Text>{safeToString(record?.id)}</Text>
        </div>

        <div style={{ marginBottom: 20 }}>
          <Title level={5}>제목</Title>
          <MultiLanguageDisplay
            value={record?.title as Record<'ko' | 'en' | 'ja' | 'zh', string>}
          />
        </div>

        <div style={{ marginBottom: 20 }}>
          <Title level={5}>순서</Title>
          <Text>{safeToString(record?.order)}</Text>
        </div>

        <div style={{ marginBottom: 20 }}>
          <Title level={5}>생성일</Title>
          <Text>
            {record?.created_at
              ? new Date(record.created_at).toLocaleString()
              : '-'}
          </Text>
        </div>

        <div style={{ marginBottom: 20 }}>
          <Title level={5}>수정일</Title>
          <Text>
            {record?.updated_at
              ? new Date(record.updated_at).toLocaleString()
              : '-'}
          </Text>
        </div>
      </Card>

      <Card title='이미지 정보' style={{ marginBottom: 20 }}>
        <div style={{ marginBottom: 20 }}>
          <Title level={5}>썸네일</Title>
          {record?.thumbnail ? (
            <Image
              src={getCdnImageUrl(record.thumbnail, 100)}
              alt='썸네일'
              style={{ maxWidth: '100%', maxHeight: 200 }}
            />
          ) : (
            <Text>이미지 없음</Text>
          )}
        </div>

        <div style={{ marginBottom: 20 }}>
          <Title level={5}>개요 이미지</Title>
          {record?.overview_images && record.overview_images.length > 0 ? (
            <Space wrap>
              {record.overview_images.map((img: string, index: number) => (
                <Image
                  key={`overview-${index}`}
                  src={getCdnImageUrl(img, 100)}
                  alt={`개요 이미지 ${index + 1}`}
                  style={{ maxWidth: 200, maxHeight: 200 }}
                />
              ))}
            </Space>
          ) : (
            <Text>이미지 없음</Text>
          )}
        </div>
      </Card>

      <Card title='위치 정보' style={{ marginBottom: 20 }}>
        <Row gutter={[24, 24]}>
          <Col span={12}>
            <Title level={5}>위치 설명</Title>
            {defaultLocalizations.map((locale) => {
              let locationValue = '-';
              try {
                if (record?.location && typeof record.location === 'object') {
                  const locationObj = JSON.parse(
                    safeToString(record.location[locale]),
                  );
                  if (locationObj) {
                    return (
                      <div
                        key={`location-${locale}`}
                        style={{ marginBottom: 16 }}
                      >
                        <Text strong>{getLanguageLabel(locale)}: </Text>
                        <div>
                          <Text strong>주소: </Text>
                          {locationObj.address || '-'}
                        </div>
                        <div style={{ marginTop: 8 }}>
                          <Text strong>설명: </Text>
                          <Paragraph
                            style={{ whiteSpace: 'pre-wrap', marginTop: 4 }}
                          >
                            {locationObj.desc || '-'}
                          </Paragraph>
                        </div>
                        <Divider />
                      </div>
                    );
                  }
                }

                // 객체가 아닌 경우 그냥 텍스트로 표시
                return (
                  <div key={`location-${locale}`} style={{ marginBottom: 16 }}>
                    <Text strong>{getLanguageLabel(locale)}: </Text>
                    <Paragraph style={{ whiteSpace: 'pre-wrap' }}>
                      {locationValue}
                    </Paragraph>
                    <Divider />
                  </div>
                );
              } catch (e) {
                return (
                  <div key={`location-${locale}`} style={{ marginBottom: 16 }}>
                    <Text strong>{getLanguageLabel(locale)}: </Text>
                    <Paragraph>{locationValue}</Paragraph>
                    <Divider />
                  </div>
                );
              }
            })}
          </Col>
          <Col span={12}>
            {record?.location_images && record.location_images.length > 0 ? (
              <>
                <Title level={5}>위치 이미지</Title>
                <Space direction='vertical'>
                  {record.location_images.map((img: string, index: number) => (
                    <Image
                      key={`location-${index}`}
                      src={getCdnImageUrl(img, 100)}
                      alt={`위치 이미지 ${index + 1}`}
                      style={{ maxWidth: '100%' }}
                    />
                  ))}
                </Space>
              </>
            ) : (
              <div style={{ marginTop: 30 }}>
                <Text>위치 이미지 없음</Text>
              </div>
            )}
          </Col>
        </Row>
      </Card>

      <Card title='사이즈 가이드' style={{ marginBottom: 20 }}>
        <Row gutter={[24, 24]}>
          <Col span={12}>
            <Title level={5}>사이즈 정보</Title>
            {defaultLocalizations.map((locale) => {
              if (
                !record?.size_guide ||
                !record.size_guide[locale] ||
                !Array.isArray(record.size_guide[locale])
              ) {
                return (
                  <div
                    key={`size-guide-${locale}`}
                    style={{ marginBottom: 16 }}
                  >
                    <Text strong>{getLanguageLabel(locale)}: </Text>
                    <Paragraph>-</Paragraph>
                    <Divider />
                  </div>
                );
              }

              return (
                <div key={`size-guide-${locale}`} style={{ marginBottom: 16 }}>
                  <Text strong>{getLanguageLabel(locale)}: </Text>
                  {record.size_guide[locale].map(
                    (guide: any, index: number) => (
                      <div
                        key={`guide-${locale}-${index}`}
                        style={{ marginBottom: 8 }}
                      >
                        <Text strong>항목 {index + 1}</Text>
                        {Array.isArray(guide.desc) ? (
                          <Paragraph
                            style={{ whiteSpace: 'pre-wrap', marginTop: 4 }}
                          >
                            {guide.desc.join('\n')}
                          </Paragraph>
                        ) : (
                          <Paragraph
                            style={{ whiteSpace: 'pre-wrap', marginTop: 4 }}
                          >
                            {guide.desc || '-'}
                          </Paragraph>
                        )}
                      </div>
                    ),
                  )}
                  <Divider />
                </div>
              );
            })}
          </Col>
          <Col span={12}>
            {record?.size_guide_images &&
            record.size_guide_images.length > 0 ? (
              <>
                <Title level={5}>사이즈 가이드 이미지</Title>
                <Space direction='vertical'>
                  {record.size_guide_images.map(
                    (img: string, index: number) => (
                      <Image
                        key={`size-guide-${index}`}
                        src={getCdnImageUrl(img, 100)}
                        alt={`사이즈 가이드 이미지 ${index + 1}`}
                        style={{ maxWidth: '100%' }}
                      />
                    ),
                  )}
                </Space>
              </>
            ) : (
              <div style={{ marginTop: 30 }}>
                <Text>사이즈 가이드 이미지 없음</Text>
              </div>
            )}
          </Col>
        </Row>
      </Card>
    </Show>
  );
}
