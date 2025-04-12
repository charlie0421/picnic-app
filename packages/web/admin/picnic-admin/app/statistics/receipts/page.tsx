'use server';

import { Suspense } from 'react';
import StatisticsClient from '../components/StatisticsClient';
import { generateMetabaseUrl } from '../utils/metabase';

export default async function ReceiptsPage() {
  const iframeUrl = await generateMetabaseUrl({ dashboardId: 3 });
  
  return (
    <Suspense fallback={<div>로딩 중...</div>}>
      <StatisticsClient iframeUrl={iframeUrl} />
    </Suspense>
  );
}