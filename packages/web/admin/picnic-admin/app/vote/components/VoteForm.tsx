'use client';

import { useForm } from '@refinedev/antd';
import {
  Form,
  Input,
  Select,
  Button,
  Table,
  Space,
  Modal,
  message,
  DatePicker,
  theme,
  Empty,
  ButtonProps,
} from 'antd';
import { DeleteOutlined, UserOutlined, TeamOutlined } from '@ant-design/icons';
import { useEffect, useState } from 'react';
import { useNavigation, useCreate, useUpdate, useList } from '@refinedev/core';
import { getCdnImageUrl } from '@/lib/image';
import { RewardItem, VOTE_CATEGORIES, type VoteRecord } from '@/lib/vote';
import { VoteItem } from '@/lib/types/vote';
import dayjs from '@/lib/dayjs';
import ArtistSelector from '@/components/features/artist-selector';
import ImageUpload from '@/components/features/upload';
import ArtistCard from '@/app/artist/components/ArtistCard';
import React from 'react';
import Image from 'next/image';
import VoteRewardSelector from './VoteRewardSelector';
import { handleRewardConnections } from '../api/voteReward';

export type VoteFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<VoteRecord>>['formProps'];
  onFinish?: (values: any) => Promise<any>;
  redirectPath?: string;
  saveButtonProps?: ButtonProps;
};

export default function VoteForm({
  mode,
  id,
  formProps,
  onFinish,
  redirectPath,
}: VoteFormProps) {
  const { push } = useNavigation();
  const { token } = theme.useToken();

  // onFinish 핸들러 설정 여부를 추적하는 ref
  const onFinishHandlerSet = React.useRef(false);

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);

  // 리워드 관련 상태
  const [initialRewardIds, setInitialRewardIds] = useState<number[]>([]);
  const [selectedRewardIds, setSelectedRewardIds] = useState<number[]>([]);

  // 리워드 목록 및 선택된 리워드 관리
  const [rewardItems, setRewardItems] = useState<RewardItem[]>([]);

  // 모든 리워드 목록 조회 - select 절 수정
  const { data: rewardsData, isLoading: isRewardsLoading } = useList({
    resource: 'reward',
    pagination: {
      pageSize: 100,
    },
    meta: {
      select: 'id,title,order,thumbnail',
    },
  });

  // 리워드 목록 설정 - title 필드 처리 수정
  useEffect(() => {
    console.log('rewardsData 변경됨:', rewardsData);
    if (rewardsData?.data) {
      setRewardItems(
        rewardsData.data.map((item: any) => ({
          id: item.id,
          title: item.title || {}, // title.ko 접근 대신 전체 title 객체 사용
          order: item.order,
          thumbnail: item.thumbnail,
        })),
      );
    }
  }, [rewardsData]);

  // vote_item 초기 데이터 설정
  useEffect(() => {
    const voteItems = formProps.initialValues?.vote_item ?? [];
    if (voteItems.length > 0) {
      setVoteItems(voteItems);
    }
  }, [formProps.initialValues?.vote_item]);

  // 디버깅 로그 추가
  useEffect(() => {
    if (id && mode === 'edit') {
      console.log('VoteForm - 편집 중인 투표 ID:', id);
      console.log('VoteForm - 투표 ID 타입:', typeof id);
    }
  }, [id, mode]);

  // 디버깅 로그 추가
  useEffect(() => {
    if (selectedRewardIds.length > 0) {
      console.log('selectedRewardIds 상태 변경됨:', selectedRewardIds);
    }
  }, [selectedRewardIds]);

  // 투표 항목 추가 핸들러
  const handleAddArtist = (newVoteItem: VoteItem) => {
    setVoteItems([...voteItems, newVoteItem]);
  };

  // 투표 항목 삭제 핸들러
  const handleRemoveArtist = (
    voteItemId: string | number,
    isNewItem = false,
  ) => {
    Modal.confirm({
      title: '투표 항목 삭제',
      content: '이 투표 항목을 삭제하시겠습니까?',
      onOk: () => {
        if (mode === 'create' || isNewItem) {
          setVoteItems(voteItems.filter((item) => item.temp_id !== voteItemId));
        } else {
          const updatedItems = voteItems.map((item) =>
            item.id === voteItemId || item.temp_id === voteItemId
              ? { ...item, deleted: true }
              : item,
          );
          setVoteItems(updatedItems);
        }
      },
    });
  };

  // API 훅
  const { mutate: createVoteReward } = useCreate();
  const { mutate: deleteVoteReward } = useUpdate();

  // 기존 formProps 저장 및 커스텀 onFinish 핸들러 설정
  useEffect(() => {
    if (onFinishHandlerSet.current) return;
    onFinishHandlerSet.current = true;

    const originalFinish = formProps.onFinish;

    formProps.onFinish = async (values: VoteRecord) => {
      try {
        console.log('VoteForm onFinish 시작');
        // vote_item과 vote_reward는 별도 테이블에 저장되므로 제외
        const { vote_item, vote_reward, ...voteData } = values as any;

        // dayjs 객체를 ISO 문자열로 변환
        if (voteData.visibility_range) {
          const [visibleAt, invisibleAt] = voteData.visibility_range;
          if (visibleAt) voteData.visible_at = visibleAt.toISOString();
          if (invisibleAt) voteData.invisible_at = invisibleAt.toISOString();
          delete voteData.visibility_range;
        }

        if (voteData.vote_range) {
          const [startAt, stopAt] = voteData.vote_range;
          if (startAt) voteData.start_at = startAt.toISOString();
          if (stopAt) voteData.stop_at = stopAt.toISOString();
          delete voteData.vote_range;
        }

        // 폼 데이터에 vote_item과 vote_reward 정보 설정 (handleVoteData에서 사용)
        formProps.form?.setFieldValue(
          'vote_item',
          voteItems
            .filter((item) => !item.deleted)
            .map((item) => ({
              ...item,
              is_existing: false,
            })),
        );

        formProps.form?.setFieldValue(
          'vote_reward',
          selectedRewardIds.map((id) => ({
            reward_id: id,
            deleted: false,
          })),
        );

        console.log('VoteForm - 최종 제출 데이터:', {
          voteData,
          vote_items: formProps.form?.getFieldValue('vote_item'),
          vote_rewards: formProps.form?.getFieldValue('vote_reward'),
        });

        console.log('VoteForm - onFinish 호출 전');
        const result = await formProps.onFinish?.(voteData);
        console.log('VoteForm - onFinish 호출 후, 결과:', result);
        return result;
      } catch (error) {
        console.error('VoteForm onFinish 에러:', error);
        message.error('투표 저장 중 오류가 발생했습니다.');
        throw error;
      }
    };
  }, [
    id,
    mode,
    selectedRewardIds,
    initialRewardIds,
    push,
    redirectPath,
    onFinish,
    formProps,
    createVoteReward,
    deleteVoteReward,
  ]);

  // Transfer 컴포넌트를 리워드 선택에 효과적으로 사용하기 위한 처리
  const [transferTargetKeys, setTransferTargetKeys] = useState<string[]>([]);

  // 초기 리워드 ID 설정 개선
  useEffect(() => {
    if (selectedRewardIds.length > 0) {
      // 문자열 배열로 변환
      const stringIds = selectedRewardIds.map((id) => id.toString());
      setTransferTargetKeys(stringIds);

      // 콘솔에 현재 상태 기록
      console.log(
        '선택된 리워드 IDs가 변경되어 Transfer targetKeys 업데이트:',
        stringIds,
      );
    }
  }, [selectedRewardIds]);

  // 초기 리워드 ID 설정
  useEffect(() => {
    console.log('폼 초기값:', formProps.initialValues);
    const rewardData = formProps.initialValues?.vote_reward ?? [];
    console.log('초기 리워드 데이터:', rewardData);

    if (rewardData.length > 0) {
      const uniqueIds = Array.from(
        new Set(
          rewardData
            .filter((item: any) => item.reward_id && !item.deleted)
            .map((item: any) => Number(item.reward_id))
            .filter((id: number) => !isNaN(id) && id > 0),
        ),
      ) as number[];

      console.log('필터링된 리워드 IDs:', uniqueIds);

      setInitialRewardIds(uniqueIds);
      setSelectedRewardIds(uniqueIds);

      // 폼 필드에도 설정
      formProps.form?.setFieldValue(
        'vote_reward',
        uniqueIds.map((id) => ({
          reward_id: id,
          deleted: false,
        })),
      );
    } else {
      // 초기 데이터가 없는 경우 상태 초기화
      setInitialRewardIds([]);
      setSelectedRewardIds([]);
      formProps.form?.setFieldValue('vote_reward', []);
    }
  }, [formProps.initialValues?.vote_reward, formProps.form]);

  // 리워드 선택 변경 핸들러
  const handleRewardChange = (rewardIds: number[]) => {
    console.log('리워드 선택 변경:', rewardIds);
    setSelectedRewardIds(rewardIds);

    // 폼 필드 업데이트
    const updatedVoteReward = rewardIds.map((id) => ({
      reward_id: id,
      deleted: false,
    }));

    console.log('업데이트할 vote_reward 데이터:', updatedVoteReward);
    formProps.form?.setFieldValue('vote_reward', updatedVoteReward);

    // 디버깅을 위한 현재 폼 값 출력
    console.log('현재 폼 데이터:', formProps.form?.getFieldsValue());
  };

  return (
    <Form
      {...formProps}
      layout='vertical'
      style={{ maxWidth: '800px', margin: '0 auto' }}
      onFinish={(values: VoteRecord) => {
        // vote_item과 vote_reward는 별도 테이블에 저장되므로 제외
        const { vote_item, vote_reward, ...voteData } = values as any;

        // dayjs 객체를 ISO 문자열로 변환
        if (voteData.visibility_range) {
          const [visibleAt, invisibleAt] = voteData.visibility_range;
          if (visibleAt) voteData.visible_at = visibleAt.toISOString();
          if (invisibleAt) voteData.invisible_at = invisibleAt.toISOString();
          delete voteData.visibility_range;
        }

        if (voteData.vote_range) {
          const [startAt, stopAt] = voteData.vote_range;
          if (startAt) voteData.start_at = startAt.toISOString();
          if (stopAt) voteData.stop_at = stopAt.toISOString();
          delete voteData.vote_range;
        }

        // 폼 데이터에 vote_item과 vote_reward 정보 설정 (handleVoteData에서 사용)
        formProps.form?.setFieldValue(
          'vote_item',
          voteItems
            .filter((item) => !item.deleted)
            .map((item) => ({
              ...item,
              is_existing: false,
            })),
        );

        formProps.form?.setFieldValue(
          'vote_reward',
          selectedRewardIds.map((id) => ({
            reward_id: id,
            deleted: false,
          })),
        );

        console.log('VoteForm - 최종 제출 데이터:', {
          voteData,
          vote_items: formProps.form?.getFieldValue('vote_item'),
          vote_rewards: formProps.form?.getFieldValue('vote_reward'),
        });

        return formProps.onFinish?.(voteData);
      }}
    >
      <Form.Item
        name={['title', 'ko']}
        label='제목 (한국어)'
        rules={[{ required: true, message: '한국어 제목을 입력해주세요' }]}
      >
        <Input placeholder='한국어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item name={['title', 'en']} label='제목 (English)'>
        <Input placeholder='영어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item name={['title', 'ja']} label='제목 (日本語)'>
        <Input placeholder='일본어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item name={['title', 'zh']} label='제목 (中文)'>
        <Input placeholder='중국어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item
        name='vote_category'
        label='카테고리'
        rules={[{ required: true, message: '카테고리를 선택해주세요' }]}
      >
        <Select
          options={VOTE_CATEGORIES}
          placeholder='투표 카테고리를 선택하세요'
        />
      </Form.Item>

      <Form.Item
        name='main_image'
        label='메인 이미지'
        valuePropName='value'
        getValueFromEvent={(e) => {
          if (typeof e === 'string') return e;
          if (e?.file?.response) return e.file.response;
          return e;
        }}
      >
        <ImageUpload />
      </Form.Item>

      <Form.Item
        name='visible_at'
        label='공개일'
        rules={[{ required: true, message: '공개일을 선택해주세요' }]}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker
          showTime
          format='YYYY-MM-DD HH:mm:ss'
          style={{ width: '100%' }}
        />
      </Form.Item>

      <Form.Item
        name='start_at'
        label='시작일'
        rules={[{ required: true, message: '시작일을 선택해주세요' }]}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker
          showTime
          format='YYYY-MM-DD HH:mm:ss'
          style={{ width: '100%' }}
        />
      </Form.Item>

      <Form.Item
        name='stop_at'
        label='종료일'
        rules={[{ required: true, message: '종료일을 선택해주세요' }]}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker
          showTime
          format='YYYY-MM-DD HH:mm:ss'
          style={{ width: '100%' }}
        />
      </Form.Item>

      <VoteRewardSelector
        initialRewardIds={initialRewardIds}
        selectedRewardIds={selectedRewardIds}
        onRewardChange={handleRewardChange}
      />

      <div
        style={{
          backgroundColor: token.colorBgContainer,
          border: `1px solid ${token.colorBorderSecondary}`,
          borderRadius: token.borderRadiusLG,
          padding: token.padding,
          marginBottom: token.marginLG,
          boxShadow: token.boxShadowTertiary,
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '16px',
          }}
        >
          <h3 style={{ margin: 0 }}>투표 항목</h3>
          <ArtistSelector
            onArtistAdd={handleAddArtist}
            existingArtistIds={voteItems
              .filter((item) => !item.deleted)
              .map((item) => item.artist_id)}
          />
        </div>

        {voteItems.filter((item) => !item.deleted).length === 0 ? (
          <Empty description='투표 항목이 없습니다. 아티스트를 추가해주세요.' />
        ) : (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))',
              gap: '16px',
              marginBottom: '16px',
            }}
          >
            {voteItems
              .filter((item) => !item.deleted)
              .map((item, index) => (
                <div key={item.id} style={{ position: 'relative' }}>
                  <ArtistCard
                    artist={item.artist!}
                    showDeleteButton
                    onDelete={() =>
                      handleRemoveArtist(
                        item.id!,
                        item.is_existing ? false : true,
                      )
                    }
                  />
                </div>
              ))}
          </div>
        )}
      </div>
    </Form>
  );
}
