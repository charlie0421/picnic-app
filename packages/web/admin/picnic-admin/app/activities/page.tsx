'use client';

import { useState, useEffect } from 'react';
import {
  Typography,
  Table,
  Card,
  Space,
  Tag,
  DatePicker,
  Select,
  Form,
  Button,
  Breadcrumb,
  Tooltip,
  Input,
} from 'antd';
import {
  SearchOutlined,
  ReloadOutlined,
  FileExcelOutlined,
} from '@ant-design/icons';
import {
  getActivityLogs,
  ActivityType,
  ResourceType,
} from '@/lib/services/activityLogger';
import dayjs from 'dayjs';
import { supabaseBrowserClient } from '@/lib/supabase/client';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;
const { Option } = Select;

// Ant Design 색상 세트
const antColors = [
  'blue',
  'green',
  'red',
  'orange',
  'purple',
  'cyan',
  'magenta',
  'lime',
  'gold',
  'volcano',
  'geekblue',
  'pink',
  'processing',
];

// 리소스 타입에 따라 자동으로 색상을 할당하는 함수
const getResourceTypeColor = (resourceType: string): string => {
  // 리소스 타입 문자열의 각 문자 코드 합산으로 간단한 해싱
  const charSum = resourceType
    .split('')
    .reduce((sum, char) => sum + char.charCodeAt(0), 0);

  // 해시값을 색상 배열 길이로 나눈 나머지를 인덱스로 사용
  return antColors[charSum % antColors.length];
};

// 리소스 타입 색상 정의 - 동적 생성
const resourceTypeColors: Record<string, string> = Object.values(
  ResourceType,
).reduce(
  (colors, type) => ({ ...colors, [type]: getResourceTypeColor(type) }),
  {},
);

// 액티비티 타입 색상 정의
const activityTypeColors = {
  [ActivityType.CREATE]: 'green',
  [ActivityType.READ]: 'blue',
  [ActivityType.UPDATE]: 'orange',
  [ActivityType.DELETE]: 'red',
  [ActivityType.LOGIN]: 'cyan',
  [ActivityType.LOGOUT]: 'purple',
  [ActivityType.EXPORT]: 'magenta',
  [ActivityType.IMPORT]: 'gold',
  [ActivityType.APPROVE]: 'lime',
  [ActivityType.REJECT]: 'volcano',
  [ActivityType.OTHER]: 'default',
};

export default function ActivitiesPage() {
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [userOptions, setUserOptions] = useState<
    { label: string; value: string }[]
  >([]);
  const [form] = Form.useForm();
  const [filters, setFilters] = useState({
    dateRange: null as [dayjs.Dayjs, dayjs.Dayjs] | null,
    user_id: undefined,
    activity_type: undefined,
    resource_type: undefined,
    keyword: '',
  });

  // 관리자 사용자 정보 가져오기
  const fetchAdminUsers = async () => {
    try {
      const { data, error } = await supabaseBrowserClient
        .from('user_profiles')
        .select('id, email');

      if (!error && data) {
        const options = data.map((user) => ({
          label: user.email,
          value: user.id,
        }));
        setUserOptions(options);
      }
    } catch (error) {
      console.error('관리자 정보 로드 실패:', error);
    }
  };

  // 액티비티 로그 조회
  const fetchActivities = async () => {
    setLoading(true);
    try {
      // 필터 처리
      const options: any = {};

      if (filters.dateRange && filters.dateRange[0] && filters.dateRange[1]) {
        options.from_date = filters.dateRange[0].toDate();
        options.to_date = filters.dateRange[1].toDate();
      }

      if (filters.user_id) {
        options.user_id = filters.user_id;
      }

      if (filters.activity_type) {
        options.activity_type = filters.activity_type;
      }

      if (filters.resource_type) {
        options.resource_type = filters.resource_type;
      }

      console.log('로그 조회 필터:', options);

      const data = await getActivityLogs(options);
      console.log('조회된 활동 로그:', data.length);

      // 키워드 필터링 (클라이언트 측에서 수행)
      const filteredData = filters.keyword
        ? data.filter(
            (item) =>
              item.description
                ?.toLowerCase()
                .includes(filters.keyword.toLowerCase()) ||
              (item.details &&
                JSON.stringify(item.details)
                  .toLowerCase()
                  .includes(filters.keyword.toLowerCase())),
          )
        : data;

      setActivities(filteredData);
    } catch (error) {
      console.error('활동 로그 로드 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  // 초기 데이터 로드
  useEffect(() => {
    fetchAdminUsers();
    fetchActivities();
  }, []);

  // 필터 변경 시 데이터 다시 로드
  useEffect(() => {
    fetchActivities();
  }, [filters]);

  // 필터 적용
  const applyFilters = (values: any) => {
    setFilters({
      ...filters,
      ...values,
    });
  };

  // 필터 초기화
  const resetFilters = () => {
    form.resetFields();
    setFilters({
      dateRange: null,
      user_id: undefined,
      activity_type: undefined,
      resource_type: undefined,
      keyword: '',
    });
  };

  // 테이블 컬럼 정의
  const columns = [
    {
      title: '시간',
      dataIndex: 'timestamp',
      key: 'timestamp',
      render: (text: string) => dayjs(text).format('YYYY-MM-DD HH:mm:ss'),
      width: 180,
    },
    {
      title: '활동 유형',
      dataIndex: 'activity_type',
      key: 'activity_type',
      render: (text: ActivityType) => (
        <Tag color={activityTypeColors[text] || 'default'}>{text}</Tag>
      ),
      width: 120,
    },
    {
      title: '리소스 유형',
      dataIndex: 'resource_type',
      key: 'resource_type',
      render: (text: ResourceType) => (
        <Tag color={resourceTypeColors[text] || 'default'}>{text}</Tag>
      ),
      width: 120,
    },
    {
      title: '설명',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: '사용자',
      dataIndex: 'user_id',
      key: 'user_id',
      render: (text: string) => {
        const user = userOptions.find((u) => u.value === text);
        return user ? user.label : text || '-';
      },
      width: 200,
    },
    {
      title: '상세 정보',
      dataIndex: 'details',
      key: 'details',
      render: (details: any) =>
        details ? (
          <Tooltip title={<pre>{JSON.stringify(details, null, 2)}</pre>}>
            <Button type='link' size='small'>
              상세보기
            </Button>
          </Tooltip>
        ) : (
          '-'
        ),
      width: 100,
    },
  ];

  return (
    <div style={{ padding: '24px' }}>
      <Breadcrumb
        items={[
          { title: '대시보드', href: '/dashboard' },
          { title: '활동 로그' },
        ]}
        style={{ marginBottom: '16px' }}
      />

      <Title level={2}>활동 로그</Title>
      <Text type='secondary' style={{ marginBottom: '24px', display: 'block' }}>
        관리자 활동 기록을 조회하고 모니터링합니다.
      </Text>

      <Card style={{ marginBottom: '24px' }}>
        <Form
          form={form}
          layout='vertical'
          onFinish={applyFilters}
          initialValues={filters}
        >
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px' }}>
            <Form.Item
              name='dateRange'
              label='날짜 범위'
              style={{ minWidth: '300px' }}
            >
              <RangePicker
                showTime
                format='YYYY-MM-DD HH:mm:ss'
                allowClear
                placeholder={['시작 날짜', '종료 날짜']}
              />
            </Form.Item>

            <Form.Item
              name='user_id'
              label='사용자'
              style={{ minWidth: '200px' }}
            >
              <Select
                allowClear
                placeholder='모든 사용자'
                options={userOptions}
              />
            </Form.Item>

            <Form.Item
              name='activity_type'
              label='활동 유형'
              style={{ minWidth: '150px' }}
            >
              <Select allowClear placeholder='모든 활동'>
                {Object.values(ActivityType).map((type) => (
                  <Option key={type} value={type}>
                    {type}
                  </Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              name='resource_type'
              label='리소스 유형'
              style={{ minWidth: '150px' }}
            >
              <Select allowClear placeholder='모든 리소스'>
                {Object.values(ResourceType).map((type) => (
                  <Option key={type} value={type}>
                    {type}
                  </Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              name='keyword'
              label='키워드 검색'
              style={{ flex: 1, minWidth: '200px' }}
            >
              <Input
                prefix={<SearchOutlined />}
                placeholder='설명 또는 상세 정보에서 검색'
              />
            </Form.Item>
          </div>

          <div
            style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}
          >
            <Button onClick={resetFilters} icon={<ReloadOutlined />}>
              필터 초기화
            </Button>
            <Button type='primary' htmlType='submit' icon={<SearchOutlined />}>
              검색
            </Button>
          </div>
        </Form>
      </Card>

      <Card>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            marginBottom: '16px',
          }}
        >
          <Text>총 {activities.length}개의 활동 기록</Text>
          <Button
            icon={<FileExcelOutlined />}
            onClick={() => {
              // 엑셀 내보내기 기능 (향후 구현)
              alert('엑셀 내보내기 기능은 개발 중입니다.');
            }}
          >
            엑셀로 내보내기
          </Button>
        </div>
        <Table
          columns={columns}
          dataSource={activities.map((item) => ({ ...item, key: item.id }))}
          loading={loading}
          pagination={{ pageSize: 10 }}
          scroll={{ x: 'max-content' }}
        />
      </Card>
    </div>
  );
}
