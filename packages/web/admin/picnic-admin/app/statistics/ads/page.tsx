'use client';

import { Typography } from 'antd';

const { Title } = Typography;

export default function StatisticsDashboard() {
  return (
    <div style={{ padding: '24px' }}>
      <Title level={2}>통계 대시보드</Title>
      <div style={{ width: '100%', height: 'calc(100vh - 150px)' }}>
        <iframe
          src='http://bi.picnic.fan/public/dashboard/fef8f30c-34c9-4942-a196-fd3118fd4a4d'
          width='100%'
          height='100%'
          style={{ border: 'none' }}
          title='피크닉 통계 대시보드'
        />
      </div>
    </div>
  );
}
