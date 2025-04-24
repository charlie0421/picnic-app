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
import { useEffect, useState, useCallback, useMemo } from 'react';
import { useNavigation, useCreate, useUpdate, useList } from '@refinedev/core';
import { getCdnImageUrl } from '@/lib/image';
import { RewardItem, VOTE_CATEGORIES, type VoteRecord } from '@/lib/vote';
import { VoteItem } from '@/lib/types/vote';
import dayjs from '@/lib/dayjs';
import ArtistSelector from '@/components/features/artist-selector/index';
import ImageUpload from '@/components/features/upload/index';
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
  const [submitting, setSubmitting] = useState(false);

  // onFinish 핸들러 설정 여부를 추적하는 ref
  const onFinishHandlerSet = React.useRef(false);

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);
  
  // voteItems 변경 사항을 추적할 임시 ID 카운터
  const tempIdCounter = React.useRef(1);
  
  // 다음 임시 ID 생성 함수
  const getNextTempId = () => {
    const id = `temp_${tempIdCounter.current}`;
    tempIdCounter.current += 1;
    return id;
  };

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
    const initialVoteItems = formProps.initialValues?.vote_item ?? [];
    if (initialVoteItems.length > 0) {
      // 모든 항목에 temp_id 추가하여 일관된 추적 가능하게 함
      const normalizedItems = initialVoteItems.map((item: any) => ({
        ...item,
        temp_id: item.temp_id || getNextTempId(),
        // artist_id가 문자열인 경우 숫자로 변환
        artist_id: typeof item.artist_id === 'string' 
          ? parseInt(item.artist_id, 10) 
          : item.artist_id,
      }));
      
      setVoteItems(normalizedItems);
    }
  }, [formProps.initialValues?.vote_item]);

  // 디버깅 로그 제거
  useEffect(() => {
    if (id && mode === 'edit') {
      // 편집 모드 초기화 로직
      // 필요한 경우에만 로직 추가
    }
  }, [id, mode]);

  // 디버깅 로그 제거
  useEffect(() => {
    if (selectedRewardIds.length > 0) {
      // 선택된 리워드 상태 변경시 필요한 로직
      // 필요한 경우에만 로직 추가
    }
  }, [selectedRewardIds]);

  // 투표 항목 추가 핸들러 - useCallback으로 최적화
  const handleAddArtist = useCallback((newVoteItem: VoteItem) => {
    // artist_id가 문자열인 경우 숫자로 변환
    const normalizedVoteItem = {
      ...newVoteItem,
      temp_id: newVoteItem.temp_id || getNextTempId(),
      artist_id: typeof newVoteItem.artist_id === 'string' 
        ? parseInt(newVoteItem.artist_id, 10) 
        : newVoteItem.artist_id,
      deleted_at: null,  // 명시적으로 삭제되지 않았음을 표시
    };
    
    // 이미 존재하는 아티스트인지 확인 (삭제된 항목 제외)
    setVoteItems(prevItems => {
      const isDuplicate = prevItems.some(
        item => !item.deleted_at && 
        item.artist_id.toString() === normalizedVoteItem.artist_id.toString()
      );
      
      if (isDuplicate) {
        message.error('이미 추가된 아티스트입니다');
        return prevItems;
      }
      
      return [...prevItems, normalizedVoteItem];
    });
  }, []);

  // 투표 항목 삭제 핸들러 - useCallback으로 최적화
  const handleRemoveArtist = useCallback((
    voteItemId: string | number,
    isNewItem = false,
  ) => {
    // 삭제할 아이템 찾기
    setVoteItems(prevItems => {
      const itemToRemove = prevItems.find(
        item => item.id === voteItemId || item.temp_id === voteItemId
      );
      
      if (!itemToRemove) {
        return prevItems;
      }
      
      // 새 아이템 여부 확인 - id가 없고 temp_id만 있거나, is_existing이 false인 경우
      const isNewVoteItem = !itemToRemove.id || (itemToRemove.is_existing === false);

      Modal.confirm({
        title: '투표 항목 삭제',
        content: '이 투표 항목을 삭제하시겠습니까?',
        onOk: () => {
          if (mode === 'create' || isNewVoteItem) {
            // 생성 모드이거나 새 항목인 경우 목록에서 완전히 제거
            setVoteItems(prevItems => 
              prevItems.filter(
                item => item.temp_id !== voteItemId && item.id !== voteItemId
              )
            );
            
            // 폼 값 즉시 업데이트
            formProps.form?.setFieldValue(
              'vote_item',
              voteItems.filter(
                item => item.temp_id !== voteItemId && item.id !== voteItemId
              )
            );
          } else {
            // 편집 모드에서 기존 항목은 deleted_at 설정
            setVoteItems(prevItems => 
              prevItems.map(item =>
                (item.id === voteItemId || item.temp_id === voteItemId)
                  ? { ...item, deleted_at: new Date().toISOString() }
                  : item
              )
            );
            
            // 폼 값 즉시 업데이트
            formProps.form?.setFieldValue(
              'vote_item',
              voteItems.map(item =>
                (item.id === voteItemId || item.temp_id === voteItemId)
                  ? { ...item, deleted_at: new Date().toISOString() }
                  : item
              )
            );
          }
        },
      });
      
      return prevItems;
    });
  }, [formProps.form, mode, voteItems]);

  // API 훅
  const { mutate: createVoteReward } = useCreate();
  const { mutate: deleteVoteReward } = useUpdate();

  // vote_item과 vote_reward를 폼에 업데이트하는 함수
  const updateFormFields = React.useCallback(() => {
    // 삭제되지 않은 항목만 필터링 - 명확하게 필터링 조건 강화
    const processedVoteItems = voteItems
      .filter((item) => {
        const notDeleted = !item.deleted_at;
        return notDeleted;
      })
      .map((item) => {
        // artist_id가 문자열인 경우 숫자로 변환
        const artistId = typeof item.artist_id === 'string' 
          ? parseInt(item.artist_id, 10) 
          : item.artist_id;
          
        return {
          ...item,
          artist_id: artistId,
          is_existing: !!item.id, // id가 있으면 기존 항목, 없으면 새 항목
          temp_id: item.temp_id || getNextTempId(), // 임시 ID 없으면 생성
          deleted_at: null, // 명시적으로 null로 설정하여 삭제되지 않았음을 표시
        };
      });
    
    const processedVoteRewards = selectedRewardIds.map((id) => ({
      reward_id: id,
      deleted_at: null,
    }));

    // 데이터를 폼에 직접 설정하고 상태 변경 사항 강제로 적용
    formProps.form?.setFields([
      {
        name: 'vote_item',
        value: processedVoteItems,
      },
      {
        name: 'vote_reward',
        value: processedVoteRewards,
      }
    ]);
    
  }, [voteItems, selectedRewardIds, formProps.form]);

  // voteItems 또는 selectedRewardIds가 변경될 때마다 폼 값 업데이트
  useEffect(() => {
    updateFormFields();
  }, [updateFormFields]);

  // 기존 formProps 저장 및 커스텀 onFinish 핸들러 설정
  useEffect(() => {
    if (onFinishHandlerSet.current) return;
    onFinishHandlerSet.current = true;

    const originalFinish = formProps.onFinish;

    formProps.onFinish = async (values: VoteRecord) => {
      try {
        if (submitting) return; // 중복 제출 방지
        setSubmitting(true);
        
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
        updateFormFields();
        
        // 최신 폼 값 가져오기
        const updatedFormValues = formProps.form?.getFieldsValue() as Record<string, any>;
        const updatedValues = {
          ...values,
          vote_item: updatedFormValues?.vote_item || [],
          vote_reward: updatedFormValues?.vote_reward || [],
        };

        // props로 전달된 onFinish 함수가 있으면 그것을 사용하고, 없으면 원래 함수 사용
        let result;
        if (onFinish) {
          result = await onFinish(updatedValues);
        } else {
          result = await originalFinish?.(voteData);
        }

        // 리다이렉트 처리
        if (redirectPath && mode === 'create') {
          push(redirectPath);
        }
        
        return result;
      } catch (error) {
        console.error('VoteForm onFinish 에러:', error);
        message.error('투표 저장 중 오류가 발생했습니다.');
        throw error;
      } finally {
        setSubmitting(false);
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
    updateFormFields,
  ]);

  // Transfer 컴포넌트를 리워드 선택에 효과적으로 사용하기 위한 처리
  const [transferTargetKeys, setTransferTargetKeys] = useState<string[]>([]);

  // 초기 리워드 ID 설정 개선
  useEffect(() => {
    if (selectedRewardIds.length > 0) {
      // 문자열 배열로 변환
      const stringIds = selectedRewardIds.map((id) => id.toString());
      setTransferTargetKeys(stringIds);
    }
  }, [selectedRewardIds]);

  // 초기 리워드 ID 설정
  useEffect(() => {
    const rewardData = formProps.initialValues?.vote_reward ?? [];

    if (rewardData.length > 0) {
      const uniqueIds = Array.from(
        new Set(
          rewardData
            .filter((item: any) => item.reward_id && !item.deleted_at)
            .map((item: any) => Number(item.reward_id))
            .filter((id: number) => !isNaN(id) && id > 0),
        ),
      ) as number[];

      setInitialRewardIds(uniqueIds);
      setSelectedRewardIds(uniqueIds);

      // 폼 필드에도 설정
      formProps.form?.setFieldValue(
        'vote_reward',
        uniqueIds.map((id) => ({
          reward_id: id,
          deleted_at: null,
        })),
      );
    } else {
      // 초기 데이터가 없는 경우 상태 초기화
      setInitialRewardIds([]);
      setSelectedRewardIds([]);
      formProps.form?.setFieldValue('vote_reward', []);
    }
  }, [formProps.initialValues?.vote_reward, formProps.form]);

  // 리워드 변경 핸들러 - useCallback으로 최적화
  const handleRewardChange = useCallback((rewardIds: number[]) => {
    setSelectedRewardIds(rewardIds);
    
    // vote_reward 데이터 생성
    const voteRewards = rewardIds.map(rewardId => ({
      reward_id: rewardId
    }));
    
    // 폼 필드에 설정
    formProps.form?.setFieldValue('vote_reward', voteRewards);
  }, [formProps.form]);

  // 폼 데이터 준비 - useMemo로 최적화
  const formData = useMemo(() => {
    return {
      vote_item: voteItems.filter(item => !item.deleted_at),
      vote_reward: selectedRewardIds.map(id => ({ reward_id: id })),
    };
  }, [voteItems, selectedRewardIds]);

  return (
    <Form
      {...formProps}
      layout='vertical'
      style={{ maxWidth: '800px', margin: '0 auto' }}
    >
      {/* 폼 데이터에 vote_item과 vote_reward를 보관하기 위한 숨겨진 필드 */}
      <Form.Item name="vote_item" hidden={true}>
        <Input type="hidden" />
      </Form.Item>
      
      <Form.Item name="vote_reward" hidden={true}>
        <Input type="hidden" />
      </Form.Item>
      
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

      <Form.Item name={['title', 'id']} label='제목 (Bahasa Indonesia)'>
        <Input placeholder='인도네시아어 제목을 입력하세요' />
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
              .filter((item) => !item.deleted_at)
              .map((item) => item.artist_id)}
          />
        </div>

        {voteItems.filter((item) => !item.deleted_at).length === 0 ? (
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
              .filter((item) => !item.deleted_at)
              .map((item, index) => (
                <div key={item.id || item.temp_id} style={{ position: 'relative' }}>
                  <ArtistCard
                    artist={item.artist!}
                    showDeleteButton
                    onDelete={() =>
                      handleRemoveArtist(
                        item.id || item.temp_id!, 
                        !item.id // id가 없으면 새 항목으로 간주
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
