'use client';

import { Card, Typography, Row, Col, Statistic, Spin } from 'antd';
import { useEffect, useState } from 'react';
import {
  UserOutlined,
  CheckCircleOutlined,
  PictureOutlined,
  VideoCameraOutlined,
} from '@ant-design/icons';
import { supabaseBrowserClient } from '@/lib/supabase/client';

const { Title } = Typography;

interface ActivityRecord {
  id: number;
  description: string;
  timestamp: string;
  user_id?: string;
  resource_type?: string;
  resource_id?: string;
}

export default function Dashboard() {
  const [usersCount, setUsersCount] = useState<number | null>(null);
  const [votesCount, setVotesCount] = useState<number | null>(null);
  const [bannersCount, setBannersCount] = useState<number | null>(null);
  const [mediaCount, setMediaCount] = useState<number | null>(null);
  const [recentActivities, setRecentActivities] = useState<ActivityRecord[]>(
    [],
  );
  const [loading, setLoading] = useState({
    users: true,
    votes: true,
    banners: true,
    media: true,
    activities: true,
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        // 사용자 수 가져오기
        const { count: usersCount, error: usersError } =
          await supabaseBrowserClient
            .from('user_profiles')
            .select('*', { count: 'exact', head: true });

        if (!usersError) {
          setUsersCount(usersCount);
        }
        setLoading((prev) => ({ ...prev, users: false }));

        // 투표 수 가져오기
        const { count: votesCount, error: votesError } =
          await supabaseBrowserClient
            .from('vote')
            .select('*', { count: 'exact', head: true });

        if (!votesError) {
          setVotesCount(votesCount);
        }
        setLoading((prev) => ({ ...prev, votes: false }));

        // 배너 수 가져오기
        const { count: bannersCount, error: bannersError } =
          await supabaseBrowserClient
            .from('banner')
            .select('*', { count: 'exact', head: true });

        if (!bannersError) {
          setBannersCount(bannersCount);
        }
        setLoading((prev) => ({ ...prev, banners: false }));

        // 미디어 수 가져오기
        const { count: mediaCount, error: mediaError } =
          await supabaseBrowserClient
            .from('media')
            .select('*', { count: 'exact', head: true });

        if (!mediaError) {
          setMediaCount(mediaCount);
        }
        setLoading((prev) => ({ ...prev, media: false }));

        // 최근 활동 가져오기
        const { data: activitiesData, error: activitiesError } =
          await supabaseBrowserClient
            .from('activities')
            .select('*')
            .order('timestamp', { ascending: false })
            .limit(10);

        if (!activitiesError && activitiesData) {
          setRecentActivities(activitiesData);
        }
        setLoading((prev) => ({ ...prev, activities: false }));
      } catch (error) {
        console.error('데이터 로드 중 오류 발생:', error);
        setLoading({
          users: false,
          votes: false,
          banners: false,
          media: false,
          activities: false,
        });
      }
    };

    fetchData();
  }, []);

  return (
    <div style={{ padding: '24px' }}>
      <Title level={2}>피크닠 관리자 대시보드</Title>

      <Row gutter={[16, 16]} style={{ marginTop: '24px' }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title='총 사용자'
              value={usersCount || 0}
              prefix={<UserOutlined />}
              loading={loading.users}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title='총 투표'
              value={votesCount || 0}
              prefix={<CheckCircleOutlined />}
              loading={loading.votes}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title='배너'
              value={bannersCount || 0}
              prefix={<PictureOutlined />}
              loading={loading.banners}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title='미디어'
              value={mediaCount || 0}
              prefix={<VideoCameraOutlined />}
              loading={loading.media}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: '24px' }}>
        <Col span={24}>
          <Card title='최근 활동'>
            {loading.activities ? (
              <div style={{ textAlign: 'center', padding: '20px' }}>
                <Spin />
              </div>
            ) : recentActivities.length > 0 ? (
              <ul>
                {recentActivities.map((activity, index) => (
                  <li key={index}>
                    {activity.description} -{' '}
                    {new Date(activity.timestamp).toLocaleString()}
                  </li>
                ))}
              </ul>
            ) : (
              <p>최근 활동 내역이 없습니다.</p>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
