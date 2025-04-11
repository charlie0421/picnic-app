'use client';

import { useShow, useResource } from '@refinedev/core';
import { Show, DateField } from '@refinedev/antd';
import { theme, Typography, Space, Avatar, Tag, Descriptions, Divider, Card, Statistic, Switch } from 'antd';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { UserProfile, genderOptions } from './types';

const { Title } = Typography;

interface UserProfileShowProps {
  id: string;
  resource?: string;
}

export function UserProfileShow({ id, resource = 'user_profiles' }: UserProfileShowProps) {
  const { queryResult } = useShow<UserProfile>({
    resource,
    id,
  });
  
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource: resourceInfo } = useResource();
  
  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  // 성별 표시 포맷팅
  const getGenderLabel = (gender?: string) => {
    if (!gender) return '미설정';
    const option = genderOptions.find(opt => opt.value === gender);
    return option ? option.label : gender;
  };

  return (
    <Show
      breadcrumb={false}
      title="사용자 상세 정보"
      isLoading={isLoading}
    >
      {record && (
        <>
          <div style={{ marginBottom: '24px', display: 'flex', alignItems: 'flex-start', gap: '24px' }}>
            <Avatar 
              src={record.avatar_url} 
              size={128}
              style={{ backgroundColor: '#f0f0f0', border: '1px solid #d9d9d9' }}
            />
            <div style={{ flex: 1 }}>
              <Title level={3} style={{ margin: '0 0 8px 0' }}>
                {record.nickname || '(닉네임 없음)'}
              </Title>
              <Descriptions column={1} size="small">
                <Descriptions.Item label="이메일">{record.email || '-'}</Descriptions.Item>
                <Descriptions.Item label="ID">{record.id}</Descriptions.Item>
                <Descriptions.Item label="가입일">
                  <DateField value={record.created_at} format="YYYY-MM-DD HH:mm:ss" />
                </Descriptions.Item>
                <Descriptions.Item label="상태">
                  <Tag color={record.deleted_at ? 'error' : 'success'}>
                    {record.deleted_at ? '탈퇴' : '활성'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="관리자 권한">
                  <Tag color={record.is_admin ? 'red' : 'default'}>
                    {record.is_admin ? '관리자' : '일반 유저'}
                  </Tag>
                </Descriptions.Item>
              </Descriptions>
            </div>
          </div>

          <Divider />

          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <div style={{ display: 'flex', gap: '16px' }}>
              <Card style={{ flex: 1 }}>
                <Statistic 
                  title="스타캔디" 
                  value={record.star_candy} 
                  precision={0} 
                />
              </Card>
              <Card style={{ flex: 1 }}>
                <Statistic 
                  title="스타캔디 보너스" 
                  value={record.star_candy_bonus} 
                  precision={0} 
                  valueStyle={{ color: record.star_candy_bonus > 0 ? '#3f8600' : '#cf1322' }}
                />
              </Card>
            </div>

            <div style={getCardStyle(token)}>
              <Title level={4} style={getTitleStyle(token)}>
                사용자 정보
              </Title>
              
              <div style={getSectionStyle(token)}>
                <Descriptions column={{ xs: 1, sm: 2 }} bordered>
                  <Descriptions.Item label="성별">
                    {getGenderLabel(record.gender)}
                  </Descriptions.Item>
                  <Descriptions.Item label="생년월일">
                    {record.birth_date ? (
                      <DateField value={record.birth_date} format="YYYY-MM-DD" />
                    ) : (
                      '-'
                    )}
                  </Descriptions.Item>
                  <Descriptions.Item label="출생 시간">
                    {record.birth_time || '-'}
                  </Descriptions.Item>
                  <Descriptions.Item label="성별/나이 공개 설정">
                    <Space direction="vertical">
                      <span>성별 공개: <Switch size="small" disabled checked={record.open_gender} /></span>
                      <span>나이 공개: <Switch size="small" disabled checked={record.open_ages} /></span>
                    </Space>
                  </Descriptions.Item>
                </Descriptions>
              </div>
            </div>

            <div style={getCardStyle(token)}>
              <Title level={4} style={getTitleStyle(token)}>
                계정 이력
              </Title>
              
              <div style={getSectionStyle(token)}>
                <Descriptions column={1} bordered>
                  <Descriptions.Item label="가입일">
                    <DateField value={record.created_at} format="YYYY-MM-DD HH:mm:ss" />
                  </Descriptions.Item>
                  <Descriptions.Item label="최근 정보 수정일">
                    <DateField value={record.updated_at} format="YYYY-MM-DD HH:mm:ss" />
                  </Descriptions.Item>
                  <Descriptions.Item label="탈퇴일">
                    {record.deleted_at ? (
                      <DateField value={record.deleted_at} format="YYYY-MM-DD HH:mm:ss" />
                    ) : (
                      '-'
                    )}
                  </Descriptions.Item>
                </Descriptions>
              </div>
            </div>
          </Space>
        </>
      )}
    </Show>
  );
} 