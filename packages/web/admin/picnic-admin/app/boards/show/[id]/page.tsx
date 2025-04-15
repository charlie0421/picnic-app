'use client';

import { useShow, useResource, useOne } from '@refinedev/core';
import { Show } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useParams } from 'next/navigation';
import { Board } from '../../../../lib/types/board';
import { BoardDetail } from '../../components';

export default function BoardShowPage() {
  const params = useParams();
  const id = params.id as string;

  const { queryResult } = useShow<Board>({
    resource: 'boards',
    id,
    meta: {
      idField: 'board_id',
      select: '*,artist(*)',
    },
  });

  const { data, isLoading } = queryResult;
  const record = data?.data as Board | undefined;
  const { resource } = useResource();

  // 상위 게시판 정보 조회
  const { data: parentBoardData } = useOne<Board>({
    resource: 'boards',
    id: record?.parent_board_id || '',
    queryOptions: {
      enabled: !!record?.parent_board_id,
    },
    meta: {
      idField: 'board_id',
      select: '*,artist(*)',
    },
  });

  // 부모 게시판 데이터를 Board 타입으로 변환
  const parentBoard = parentBoardData?.data as Board | undefined;

  return (
    <AuthorizePage resource='boards' action='show'>
      <Show
        breadcrumb={false}
        title={resource?.meta?.show?.label || '게시판 상세'}
        isLoading={isLoading}
      >
        <BoardDetail record={record} parentBoard={parentBoard} />
      </Show>
    </AuthorizePage>
  );
}
