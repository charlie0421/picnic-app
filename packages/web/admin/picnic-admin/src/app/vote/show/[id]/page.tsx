'use client';

import { Show } from '@refinedev/antd';
import { useShow } from '@refinedev/core';
import { type VoteRecord } from '@/utils/vote';
import VoteDetail from '@/components/vote/VoteDetail';

export default function VoteShow({ params }: { params: { id: string } }) {
  const { queryResult } = useShow<VoteRecord>({
    resource: 'vote',
    id: params.id,
    meta: {
      select:
        'id, title, main_image, vote_category, visible_at, start_at, stop_at, created_at, updated_at, deleted_at, vote_item(id, artist_id, vote_total, artist(id, name, image, birth_date, yy, mm, dd, artist_group(id, name, image, debut_yy, debut_mm, debut_dd)), created_at, updated_at, deleted_at)',
    },
  });
  const { data, isLoading } = queryResult;

  return (
    <Show isLoading={isLoading} title='투표 상세'>
      <VoteDetail record={data?.data} loading={isLoading} />
    </Show>
  );
}
