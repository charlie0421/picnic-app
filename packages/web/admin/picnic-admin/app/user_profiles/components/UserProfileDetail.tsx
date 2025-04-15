'use client';

import { useShow, useList } from '@refinedev/core';
import { Show, DateField, EditButton, DeleteButton } from '@refinedev/antd';
import {
  theme,
  Typography,
  Space,
  Avatar,
  Tag,
  Descriptions,
  Divider,
  Card,
  Statistic,
  Switch,
  Table,
  Tabs,
} from 'antd';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { UserProfile, genderOptions } from '@/lib/types/user_profiles';
import { VotePick } from '@/lib/types/vote';
import {
  Receipt,
  RECEIPT_STATUS,
  RECEIPT_PLATFORM,
  RECEIPT_ENVIRONMENT,
} from '@/lib/types/receipt';
import { useEffect, useState } from 'react';
import MultiLanguageDisplay from '@/components/ui/MultiLanguageDisplay';

const { Title } = Typography;

interface UserProfileDetailProps {
  record?: UserProfile;
  loading?: boolean;
}

export function UserProfileDetail({ record, loading }: UserProfileDetailProps) {
  const { queryResult } = useShow<UserProfile>({});

  const { data, isLoading } = queryResult;

  // 현재 페이지와 페이지 크기 상태 관리
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // 구매내역 페이지네이션 상태 관리
  const [receiptCurrentPage, setReceiptCurrentPage] = useState(1);
  const [receiptPageSize, setReceiptPageSize] = useState(10);

  // vote_pick 데이터 조회 - 데이터베이스 관계 사용
  const { data: votePicksData, isLoading: isLoadingVotePicks } =
    useList<VotePick>({
      resource: 'vote_pick',
      filters: [
        {
          field: 'user_id',
          operator: 'eq',
          value: record?.id,
        },
      ],
      pagination: {
        current: currentPage,
        pageSize: pageSize,
      },
      sorters: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
      meta: {
        select: `
        id, 
        created_at, 
        vote_id, 
        vote_item_id, 
        amount, 
        vote (id, title), 
        vote_item (
          id,
          artist_id,
          artist (
            id, 
            name
          )
        )
      `,
      },
    });

  // receipts 데이터 조회
  const { data: receiptsData, isLoading: isLoadingReceipts } = useList<Receipt>(
    {
      resource: 'receipts',
      filters: [
        {
          field: 'user_id',
          operator: 'eq',
          value: record?.id,
        },
      ],
      pagination: {
        current: receiptCurrentPage,
        pageSize: receiptPageSize,
      },
      sorters: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
  );

  // 투표 내역 페이지 변경 핸들러
  const handlePageChange = (page: number, newPageSize?: number) => {
    setCurrentPage(page);
    if (newPageSize) setPageSize(newPageSize);
  };

  // 구매내역 페이지 변경 핸들러
  const handleReceiptPageChange = (page: number, newPageSize?: number) => {
    setReceiptCurrentPage(page);
    if (newPageSize) setReceiptPageSize(newPageSize);
  };

  // 콘솔에 데이터 기록
  useEffect(() => {
    if (votePicksData) {
      console.log('Vote Picks with Relations:', votePicksData.data);
    }
  }, [votePicksData]);

  useEffect(() => {
    if (receiptsData) {
      console.log('Receipts Data:', receiptsData.data);
    }
  }, [receiptsData]);

  // Ant Design의 테마 토큰 사용
  const { token } = theme.useToken();

  // 성별 표시 포맷팅
  const getGenderLabel = (gender?: string) => {
    if (!gender) return '미설정';
    const option = genderOptions.find((opt) => opt.value === gender);
    return option ? option.label : gender;
  };

  // Vote Pick 테이블 컬럼 설정
  const votePickColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
    },
    {
      title: '투표명',
      key: 'vote_title',
      render: (record: any) => {
        const title = record.vote?.title;
        return title ? (
          <MultiLanguageDisplay languages={['ko']} value={title} />
        ) : (
          '-'
        );
      },
    },
    {
      title: '아티스트',
      key: 'artist_name',
      render: (record: any) => {
        const artistName = record.vote_item?.artist?.name;
        return artistName ? (
          <MultiLanguageDisplay languages={['ko']} value={artistName} />
        ) : (
          '-'
        );
      },
    },
    {
      title: '수량',
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => amount?.toLocaleString() || 0,
    },
    {
      title: '투표 일시',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => (
        <DateField value={date} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  // Receipt 플랫폼 표시 포맷팅
  const getPlatformLabel = (platform?: string) => {
    if (!platform) return '미설정';
    switch (platform) {
      case RECEIPT_PLATFORM.IOS:
        return 'iOS';
      case RECEIPT_PLATFORM.ANDROID:
        return 'Android';
      default:
        return platform;
    }
  };

  // Receipt 환경 표시 포맷팅
  const getEnvironmentLabel = (environment?: string) => {
    if (!environment) return '미설정';
    switch (environment) {
      case RECEIPT_ENVIRONMENT.PRODUCTION:
        return '프로덕션';
      case RECEIPT_ENVIRONMENT.SANDBOX:
        return '샌드박스';
      default:
        return environment;
    }
  };

  // Receipt 상태 표시 포맷팅
  const getStatusColor = (status?: string) => {
    if (!status) return 'default';
    switch (status) {
      case RECEIPT_STATUS.VALID:
        return 'success';
      case RECEIPT_STATUS.INVALID:
        return 'error';
      case RECEIPT_STATUS.PENDING:
        return 'warning';
      default:
        return 'default';
    }
  };

  // Receipt 테이블 컬럼 설정
  const receiptColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
    },
    {
      title: '플랫폼',
      dataIndex: 'platform',
      key: 'platform',
      render: (platform: string) => getPlatformLabel(platform),
    },
    {
      title: '상품 ID',
      dataIndex: 'product_id',
      key: 'product_id',
      render: (product_id: string) => product_id || '-',
    },
    {
      title: '상태',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={getStatusColor(status)}>{status || '-'}</Tag>
      ),
    },
    {
      title: '환경',
      dataIndex: 'environment',
      key: 'environment',
      render: (environment: string) => getEnvironmentLabel(environment),
    },
    {
      title: '구매 일시',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => (
        <DateField value={date} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  // 사용자 기본 정보 탭 렌더링
  const renderUserInfoTab = () => (
    <Space direction='vertical' size='large' style={{ width: '100%' }}>
      <div style={{ display: 'flex', gap: '16px' }}>
        <Card style={{ flex: 1 }}>
          <Statistic
            title='스타캔디'
            value={record?.star_candy}
            precision={0}
          />
        </Card>
        <Card style={{ flex: 1 }}>
          <Statistic
            title='스타캔디 보너스'
            value={record?.star_candy_bonus}
            precision={0}
            valueStyle={{
              color:
                record?.star_candy_bonus && record.star_candy_bonus > 0
                  ? '#3f8600'
                  : '#cf1322',
            }}
          />
        </Card>
      </div>

      <div style={getCardStyle(token)}>
        <Title level={4} style={getTitleStyle(token)}>
          사용자 정보
        </Title>

        <div style={getSectionStyle(token)}>
          <Descriptions column={{ xs: 1, sm: 2 }} bordered>
            <Descriptions.Item label='성별'>
              {getGenderLabel(record?.gender)}
            </Descriptions.Item>
            <Descriptions.Item label='생년월일'>
              {record?.birth_date ? (
                <DateField value={record.birth_date} format='YYYY-MM-DD' />
              ) : (
                '-'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='출생 시간'>
              {record?.birth_time || '-'}
            </Descriptions.Item>
            <Descriptions.Item label='성별/나이 공개 설정'>
              <Space direction='vertical'>
                <span>
                  성별 공개:{' '}
                  <Switch size='small' disabled checked={record?.open_gender} />
                </span>
                <span>
                  나이 공개:{' '}
                  <Switch size='small' disabled checked={record?.open_ages} />
                </span>
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
            <Descriptions.Item label='가입일'>
              <DateField
                value={record?.created_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
            </Descriptions.Item>
            <Descriptions.Item label='최근 정보 수정일'>
              <DateField
                value={record?.updated_at}
                format='YYYY-MM-DD HH:mm:ss'
              />
            </Descriptions.Item>
            <Descriptions.Item label='탈퇴일'>
              {record?.deleted_at ? (
                <DateField
                  value={record.deleted_at}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              ) : (
                '-'
              )}
            </Descriptions.Item>
          </Descriptions>
        </div>
      </div>
    </Space>
  );

  // 투표 내역 탭 렌더링
  const renderVoteHistoryTab = () => (
    <div style={getCardStyle(token)}>
      <div style={getSectionStyle(token)}>
        <div style={{ width: '100%', overflowX: 'auto' }}>
          <Table
            dataSource={votePicksData?.data || []}
            columns={votePickColumns}
            rowKey='id'
            loading={isLoadingVotePicks}
            pagination={{
              current: currentPage,
              pageSize: pageSize,
              total: votePicksData?.total || 0,
              onChange: handlePageChange,
              showSizeChanger: true,
              pageSizeOptions: ['10', '20', '50', '100'],
              showTotal: (total) => `총 ${total}개 투표 내역`,
            }}
            onRow={() => ({
              style: {
                cursor: 'pointer',
              },
            })}
            scroll={{ x: 'max-content' }}
            size='small'
          />
        </div>
      </div>
    </div>
  );

  // 구매내역 탭 렌더링
  const renderReceiptHistoryTab = () => (
    <div style={getCardStyle(token)}>
      <div style={getSectionStyle(token)}>
        <div style={{ width: '100%', overflowX: 'auto' }}>
          <Table
            dataSource={receiptsData?.data || []}
            columns={receiptColumns}
            rowKey='id'
            loading={isLoadingReceipts}
            pagination={{
              current: receiptCurrentPage,
              pageSize: receiptPageSize,
              total: receiptsData?.total || 0,
              onChange: handleReceiptPageChange,
              showSizeChanger: true,
              pageSizeOptions: ['10', '20', '50', '100'],
              showTotal: (total) => `총 ${total}개 구매 내역`,
            }}
            onRow={() => ({
              style: {
                cursor: 'pointer',
              },
            })}
            scroll={{ x: 'max-content' }}
            size='small'
          />
        </div>
      </div>
    </div>
  );

  return (
    <>
      {record && (
        <>
          <div
            style={{
              marginBottom: '24px',
              display: 'flex',
              alignItems: 'flex-start',
              gap: '24px',
            }}
          >
            <Avatar
              src={record.avatar_url}
              size={128}
              style={{
                backgroundColor: '#f0f0f0',
                border: '1px solid #d9d9d9',
              }}
            />
            <div style={{ flex: 1 }}>
              <Title level={3} style={{ margin: '0 0 8px 0' }}>
                {record.nickname || '(닉네임 없음)'}
              </Title>
              <Descriptions column={1} size='small'>
                <Descriptions.Item label='이메일'>
                  {record.email || '-'}
                </Descriptions.Item>
                <Descriptions.Item label='ID'>{record.id}</Descriptions.Item>
                <Descriptions.Item label='가입일'>
                  <DateField
                    value={record.created_at}
                    format='YYYY-MM-DD HH:mm:ss'
                  />
                </Descriptions.Item>
                <Descriptions.Item label='상태'>
                  <Tag color={record.deleted_at ? 'error' : 'success'}>
                    {record.deleted_at ? '탈퇴' : '활성'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label='관리자 권한'>
                  <Tag color={record.is_admin ? 'red' : 'default'}>
                    {record.is_admin ? '관리자' : '일반 유저'}
                  </Tag>
                </Descriptions.Item>
              </Descriptions>
            </div>
          </div>

          <Divider />

          <Tabs defaultActiveKey='info' type='card'>
            <Tabs.TabPane tab='사용자 정보' key='info'>
              {renderUserInfoTab()}
            </Tabs.TabPane>
            <Tabs.TabPane tab='투표 내역' key='votes'>
              {renderVoteHistoryTab()}
            </Tabs.TabPane>
            <Tabs.TabPane tab='구매 내역' key='receipts'>
              {renderReceiptHistoryTab()}
            </Tabs.TabPane>
          </Tabs>
        </>
      )}
    </>
  );
}
