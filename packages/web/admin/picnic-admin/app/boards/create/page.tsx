'use client';

import { Create, useForm } from '@refinedev/antd';
import { message, Spin } from 'antd';
import { useResource, useMany } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Board, BoardCreateInput } from '../../../lib/types/board';
import { BoardForm } from '../components';

export default function BoardCreatePage() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm({
    resource: 'boards',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('게시판이 성공적으로 생성되었습니다');
    },
    meta: {
      idField: 'board_id',
    },
  });

  // 상위 게시판 목록 가져오기
  const { data: boardsData, isLoading: isBoardsLoading } = useMany<Board>({
    resource: 'boards',
    ids: [], // 모든 게시판을 가져오기 위해 빈 배열 사용
    meta: {
      idField: 'board_id',
      pagination: {
        mode: 'off',
      },
    },
  });

  // 아티스트 목록 가져오기
  const { data: artistsData, isLoading: isArtistsLoading } = useMany({
    resource: 'artists',
    ids: [], // 모든 아티스트를 가져오기 위해 빈 배열 사용
    meta: {
      pagination: {
        mode: 'off',
      },
    },
  });

  // 저장 전 데이터 변환
  const handleSave = async (values: any) => {
    const transformedValues: BoardCreateInput = {
      ...values,
    };
    return transformedValues;
  };

  // 게시판 선택 옵션 생성
  const boardOptions = boardsData?.data?.map((board) => ({
    label: board.name.ko || board.name.en || board.board_id,
    value: board.board_id || '',
  })) || [];

  // 아티스트 선택 옵션 생성
  const artistOptions = artistsData?.data?.map((artist) => ({
    label: artist.name?.ko || artist.name?.en || String(artist.id || ''),
    value: String(artist.id || ''),
  })) || [];

  // 전체 로딩 상태 결정
  const isPageLoading = isBoardsLoading || isArtistsLoading;

  return (
    <AuthorizePage resource='boards' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label || '게시판 생성'}
        isLoading={isPageLoading}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: async () => {
            const values = await formProps.form?.validateFields();
            if (values) {
              const transformedValues = await handleSave(values);
              formProps.onFinish?.(transformedValues);
            }
          },
        }}
      >
        {contextHolder}
        <Spin spinning={isPageLoading}>
          <BoardForm 
            formProps={formProps} 
            boardOptions={boardOptions}
            artistOptions={artistOptions}
          />
        </Spin>
      </Create>
    </AuthorizePage>
  );
}
