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
  Transfer,
  Divider,
} from 'antd';
import { DeleteOutlined, UserOutlined, TeamOutlined } from '@ant-design/icons';
import { useEffect, useState } from 'react';
import { useNavigation, useCreate, useUpdate, useList } from '@refinedev/core';
import { getCdnImageUrl } from '@/lib/image';
import { RewardItem, VOTE_CATEGORIES, type VoteRecord } from '@/lib/vote';
import { VoteItem } from '@/lib/types/vote';
import dayjs from '@/lib/dayjs';
import { COLORS } from '@/lib/theme';
import ArtistSelector from '@/components/features/artist-selector';
import ImageUpload from '@/components/features/upload';
import ArtistCard from '@/app/artist/components/ArtistCard';
import React from 'react';
import Image from 'next/image';

type VoteFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  initialVoteItems?: VoteItem[];
  formProps: ReturnType<typeof useForm<VoteRecord>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<VoteRecord>>['saveButtonProps'];
  onFinish?: (values: any) => Promise<any>;
  redirectPath?: string;
};

export default function VoteForm({
  mode,
  id,
  initialVoteItems = [],
  formProps,
  saveButtonProps,
  onFinish,
  redirectPath,
}: VoteFormProps) {
  const { push } = useNavigation();
  const { token } = theme.useToken();
  
  console.log('VoteForm 컴포넌트 마운트', formProps);

  // onFinish 핸들러 설정 여부를 추적하는 ref
  const onFinishHandlerSet = React.useRef(false);

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>(initialVoteItems);
  
  // formProps에서 initialRewardIds 추출
  const initialRewardIds = formProps.initialValues?.reward_ids || [];
  
  // 리워드 목록 및 선택된 리워드 관리
  const [rewardItems, setRewardItems] = useState<RewardItem[]>([]);
  const [selectedRewardIds, setSelectedRewardIds] = useState<number[]>(initialRewardIds);
  
  // vote_item 생성/수정/삭제 훅
  const { mutate: createVoteItem } = useCreate();
  const { mutate: updateVoteItem } = useUpdate();
  
  // vote_reward 생성/삭제 훅
  const { mutate: createVoteReward } = useCreate();
  const { mutate: deleteVoteReward } = useUpdate();
  const { mutate: hardDeleteVoteReward } = useCreate({
    resource: 'rpc/delete_vote_reward',
    meta: {
      dataProviderName: 'default'
    }
  });

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
  
  // Transfer 컴포넌트를 리워드 선택에 효과적으로 사용하기 위한 처리
  const [transferTargetKeys, setTransferTargetKeys] = useState<string[]>([]);
  
  // 초기 리워드 ID 설정 개선
  useEffect(() => {
    if (selectedRewardIds.length > 0) {
      // 문자열 배열로 변환
      const stringIds = selectedRewardIds.map(id => id.toString());
      setTransferTargetKeys(stringIds);
      
      // 콘솔에 현재 상태 기록
      console.log('선택된 리워드 IDs가 변경되어 Transfer targetKeys 업데이트:', stringIds);
    }
  }, [selectedRewardIds]);

  // 컴포넌트 마운트 시 formProps의 reward_ids를 selectedRewardIds로 설정
  useEffect(() => {
    const rewardIds = formProps.initialValues?.vote_reward || [];
    console.log('rewardIds:', rewardIds);
    if (rewardIds.length > 0) {
      console.log('formProps에서 추출한 리워드 IDs를 선택된 리워드로 설정합니다:', rewardIds);
      setSelectedRewardIds(rewardIds.map((item: any) => item.reward_id));
      
      // 폼 필드에도 설정
      if (formProps.form) {
        formProps.form.setFieldValue('_rewardIds', rewardIds);
        formProps.form.setFieldValue('_targetKeys', rewardIds.map((id: number) => id.toString()));
      }
    }
  }, [formProps.initialValues?.vote_reward, formProps.form]);
  
  // 폼 필드 디버깅 함수 추가
  const logFormValues = (form: any) => {
    if (!form) return;
    
    try {
      const allValues = form.getFieldsValue(true);
      console.log('===== 폼 필드 현재 값 =====');
      console.log('모든 폼 필드:', allValues);
      console.log('_rewardIds 필드:', form.getFieldValue('_rewardIds'));
      console.log('_targetKeys 필드:', form.getFieldValue('_targetKeys'));
      console.log('===========================');
    } catch (error) {
      console.error('폼 필드 로깅 오류:', error);
    }
  };

  // 리워드 ID 처리 함수 추가 (타입 안전성 강화)
  const processRewardIds = (ids: number[] | string[] | any[] | undefined): number[] => {
    if (!ids || !Array.isArray(ids) || ids.length === 0) return [];
    
    // 모든 요소를 숫자로 변환하고 유효한 ID만 필터링
    return ids
      .map(id => typeof id === 'string' ? Number(id) : id)
      .filter(id => typeof id === 'number' && !isNaN(id) && id > 0);
  };

  // 리워드 선택 변경 핸들러 개선 - 타입 오류 수정
  const handleRewardSelectChange = (
    nextTargetKeys: string[] | React.Key[], 
    direction: 'left' | 'right', 
    moveKeys: React.Key[]
  ) => {
    console.log('리워드 선택 변경됨:', nextTargetKeys);
    
    // Transfer의 targetKeys 상태 업데이트 (문자열 배열로 변환)
    const stringKeys = nextTargetKeys.map(key => key.toString());
    setTransferTargetKeys(stringKeys);
    
    // 숫자 배열로 변환
    const numericIds = nextTargetKeys.map(key => Number(key.toString())).filter(id => !isNaN(id) && id > 0);
    console.log('숫자로 변환된 리워드 IDs:', numericIds);
    
    // 메인 상태 업데이트
    setSelectedRewardIds(numericIds);
    
    // 디버깅: 현재 상태 출력
    console.log('리워드 선택 상태 업데이트됨:', {
      selectedRewardIds: numericIds,
      transferTargetKeys: stringKeys
    });
  };

  // 기존 formProps 저장 및 커스텀 onFinish 핸들러 설정
  useEffect(() => {
    if (onFinishHandlerSet.current) return;
    onFinishHandlerSet.current = true;
    
    // 기존 onFinish 함수 저장
    const originalFinish = formProps.onFinish;
    
    // 커스텀 onFinish 핸들러로 교체
    formProps.onFinish = async (values: any) => {
      try {
        console.log(`[${mode} mode] Form submission started with values:`, values);
        
        // 날짜 형식 변환 처리
        const finalValues: any = {
          ...values,
        };
        
        if (finalValues.visibility_range) {
          const [visibleAt, invisibleAt] = finalValues.visibility_range || [];
          if (visibleAt) finalValues.visible_at = visibleAt.toISOString();
          if (invisibleAt) finalValues.invisible_at = invisibleAt.toISOString();
          delete finalValues.visibility_range;
        }
        
        if (finalValues.vote_range) {
          const [startAt, stopAt] = finalValues.vote_range || [];
          if (startAt) finalValues.start_at = startAt.toISOString();
          if (stopAt) finalValues.stop_at = stopAt.toISOString();
          delete finalValues.vote_range;
        }
        
        // 전역 저장소에서 리워드 ID 목록 가져오기
        const rewardIds: number[] = selectedRewardIds.length > 0 
          ? selectedRewardIds
          // @ts-ignore
          : window.__rewardIds || [];
          
        console.log('최종 폼 데이터:', finalValues);
        console.log('최종 리워드 ID 목록:', rewardIds);
        
        // Refine의 기본 onFinish 함수 호출 또는 커스텀 onFinish 함수 호출
        const result = await (onFinish 
          ? onFinish(finalValues)
          : originalFinish?.(finalValues));
        
        if (!result || !result.data) {
          console.error('투표 저장 결과가 없습니다.');
          return result;
        }
        
        console.log('투표 저장 결과:', result);
  
        const voteId = result?.data?.id || id;
        const numericVoteId = Number(voteId);
  
        console.log('저장된 투표 ID:', voteId, '(타입:', typeof voteId, ')');
        console.log('숫자 변환 ID:', numericVoteId);
        
        // 투표 ID가 유효한지 확인
        if (!voteId || isNaN(numericVoteId) || numericVoteId <= 0) {
          console.error('유효하지 않은 vote_id:', voteId);
          message.error('투표 ID가 유효하지 않아 리워드를 연결할 수 없습니다.');
          return result;
        }
  
        // 투표 항목 저장 로직 (생략)...
        
        // ===== 리워드 연결 저장 로직 =====
        
        // 수정 모드일 경우 기존 연결 정보와 비교하여 변경 사항 처리
        if (mode === 'edit' && id) {
          console.log('수정 모드에서 리워드 연결 처리 시작');
          console.log('현재 선택된 리워드 IDs:', rewardIds);
          console.log('초기 리워드 IDs:', initialRewardIds);
          
          // 기존 리워드에서 삭제된 항목 찾기
          const toRemove: number[] = [];
          initialRewardIds.forEach((oldId: number) => {
            if (!rewardIds.includes(oldId)) {
              toRemove.push(oldId);
            }
          });
          
          // 새로 추가된 항목 찾기
          const toAdd: number[] = [];
          rewardIds.forEach((newId: number) => {
            if (!initialRewardIds.includes(newId)) {
              toAdd.push(newId);
            }
          });
          
          console.log('삭제할 리워드 연결:', toRemove);
          console.log('추가할 리워드 연결:', toAdd);
          
          // 삭제 처리
          if (toRemove.length > 0) {
            console.log(`${toRemove.length}개 리워드 연결 삭제 시작`);
            
            for (const rewardId of toRemove) {
              try {
                console.log(`리워드 연결 삭제: vote_id=${numericVoteId}, reward_id=${rewardId}`);
                
                // RPC 방식으로 vote_reward 레코드 삭제
                await hardDeleteVoteReward({
                  resource: 'rpc/delete_vote_reward',
                  values: {
                    p_vote_id: numericVoteId,
                    p_reward_id: rewardId
                  },
                  meta: {
                    dataProviderName: 'default',
                    successNotification: false
                  }
                });
                
                console.log(`리워드 연결 삭제 성공: reward_id=${rewardId}`);
              } catch (error) {
                console.error(`리워드 연결 삭제 실패: reward_id=${rewardId}`, error);
                message.error(`리워드 ID ${rewardId} 연결 삭제 실패`);
              }
            }
          }
          
          // 추가 처리
          if (toAdd.length > 0) {
            console.log(`${toAdd.length}개 리워드 연결 추가 시작`);
            
            for (const rewardId of toAdd) {
              await createRewardConnection(numericVoteId, rewardId);
            }
          }
        } 
        // 생성 모드일 경우 모든 리워드 연결 새로 생성
        else if (mode === 'create' && rewardIds.length > 0) {
          console.log(`${rewardIds.length}개 리워드 연결 생성 시작`);
          
          for (const rewardId of rewardIds) {
            await createRewardConnection(numericVoteId, rewardId);
          }
        }
        
        console.log(`===== ${mode} 모드에서 리워드 연결 처리 완료 =====`);
        
        return result;
      } catch (error) {
        console.error('Form submission error:', error);
        message.error(
          mode === 'create'
            ? '투표 생성 중 오류가 발생했습니다'
            : '투표 업데이트 중 오류가 발생했습니다',
        );
        throw error;
      }
    };
  }, [
    id, 
    mode, 
    voteItems,
    selectedRewardIds,
    updateVoteItem, 
    createVoteItem, 
    hardDeleteVoteReward, 
    createVoteReward
  ]);
  
  // 리워드 연결 생성 함수 (코드 중복 방지)
  const createRewardConnection = async (voteId: number, rewardId: number) => {
    try {
      console.log(`리워드 연결 생성: vote_id=${voteId}, reward_id=${rewardId}`);
      
      // 숫자 타입 검증
      if (isNaN(voteId) || voteId <= 0) {
        throw new Error(`유효하지 않은 vote_id: ${voteId}`);
      }
      
      if (isNaN(rewardId) || rewardId <= 0) {
        throw new Error(`유효하지 않은 reward_id: ${rewardId}`);
      }
      
      // 연결 생성
      // API 호출 직접 확인
      console.log('createVoteReward 함수 직접 호출 시작');
      console.log('호출 파라미터:', {
        resource: 'vote_reward',
        values: {
          vote_id: voteId,
          reward_id: rewardId
        }
      });
      
      const insertResult = await createVoteReward({
        resource: 'vote_reward',
        values: {
          vote_id: voteId,
          reward_id: rewardId
        },
        meta: {
          successNotification: false
        }
      });
      
      console.log(`리워드 연결 생성 성공: reward_id=${rewardId}`, insertResult);
      return true;
    } catch (error) {
      console.error(`리워드 연결 생성 실패: vote_id=${voteId}, reward_id=${rewardId}`, error);
      message.error(`리워드 ID ${rewardId} 연결 실패: ${(error as Error).message || '알 수 없는 오류'}`);
      return false;
    }
  };

  // initialVoteItems가 변경될 때마다 voteItems 업데이트
  useEffect(() => {
    if (initialVoteItems.length > 0) {
      setVoteItems(initialVoteItems);
    }
  }, [initialVoteItems]);
  
  // 리워드 목록 설정 - title 필드 처리 수정
  useEffect(() => {
    console.log('rewardsData 변경됨:', rewardsData);
    if (rewardsData?.data) {
      setRewardItems(rewardsData.data.map((item: any) => ({
        id: item.id,
        title: item.title || {}, // title.ko 접근 대신 전체 title 객체 사용
        order: item.order,
        thumbnail: item.thumbnail
      })));
    }
  }, [rewardsData]);
  
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
          // 생성 모드 또는 새로 추가된 항목은 로컬 상태에서만 제거
          setVoteItems(voteItems.filter((item) => item.temp_id !== voteItemId));
        } else {
          // 편집 모드에서 기존 항목은 삭제 플래그 설정 (soft delete)
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
  
  // 투표 항목 테이블 컬럼 설정
  const columns = [
    {
      title: '아이디',
      dataIndex: ['artist', 'id'],
      key: 'artist_id',
      align: 'center' as const,
    },
    {
      title: '이미지',
      dataIndex: ['artist', 'image'],
      key: 'image',
      align: 'center' as const,
      render: (image: string | undefined) =>
        image ? (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <Image
              src={getCdnImageUrl(image, 40)}
              alt='아티스트 이미지'
              width={40}
              height={40}
              style={{
                objectFit: 'cover',
                borderRadius: '50%',
              }}
              onError={(e) => {
                e.currentTarget.style.display = 'none';
                if (e.currentTarget.nextElementSibling instanceof HTMLElement) {
                  e.currentTarget.nextElementSibling.style.display = 'block';
                }
              }}
            />
          </div>
        ) : (
          <div
            style={{
              width: '40px',
              height: '40px',
              backgroundColor: '#f5f5f5',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto',
            }}
          >
            <UserOutlined
              style={{ fontSize: '18px', color: token.colorTextSecondary }}
            />
          </div>
        ),
    },
    {
      title: '아티스트',
      dataIndex: ['artist', 'name', 'ko'],
      key: 'name',
      render: (text: string, record: VoteItem) => (
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontWeight: 'bold' }}>
            {record.artist?.name?.ko || '-'}
          </div>
          {record.artist?.name?.en && (
            <div style={{ fontSize: '12px', color: token.colorTextSecondary }}>
              {record.artist.name.en}
            </div>
          )}
        </div>
      ),
    },
    {
      title: '그룹',
      dataIndex: ['artist', 'artist_group', 'name', 'ko'],
      key: 'group',
      render: (text: string, record: VoteItem) => (
        <div style={{ textAlign: 'center' }}>
          {record.artist?.artist_group ? (
            <div>
              <div style={{ fontWeight: 'bold' }}>
                {record.artist.artist_group.name?.ko || ''}
              </div>
              {record.artist.artist_group.name?.en && (
                <div
                  style={{ fontSize: '12px', color: token.colorTextSecondary }}
                >
                  {record.artist.artist_group.name.en}
                </div>
              )}
            </div>
          ) : (
            '-'
          )}
        </div>
      ),
    },
    {
      title: '액션',
      key: 'action',
      align: 'center' as const,
      render: (_: any, record: VoteItem) => (
        <Space size='middle'>
          <Button
            danger
            icon={<DeleteOutlined />}
            onClick={() =>
              handleRemoveArtist(
                record.temp_id!,
                record.is_existing ? false : true,
              )
            }
          />
        </Space>
      ),
    },
  ];

  return (
    <Form
      {...formProps}
      layout='vertical'
      style={{ maxWidth: '800px', margin: '0 auto' }}
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
          // ImageUpload 컴포넌트에서 직접 string을 반환하는 경우
          if (typeof e === 'string') {
            return e;
          }
          // Antd Upload 컴포넌트의 기본 이벤트 처리
          if (e && e.file && e.file.response) {
            return e.file.response;
          }
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
      
      {/* 리워드 선택 섹션 개선 */}
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
        <h3 style={{ marginTop: 0, color: token.colorTextHeading }}>리워드 연결</h3>
        <p style={{ color: token.colorTextSecondary }}>
          이 투표와 연결할 리워드를 선택하세요. 투표 결과에 따라 제공될 리워드입니다.
        </p>
        
        {isRewardsLoading ? (
          <div style={{ textAlign: 'center', padding: '20px' }}>리워드 목록을 불러오는 중...</div>
        ) : rewardItems.length === 0 ? (
          <Empty description="연결할 수 있는 리워드가 없습니다." />
        ) : (
          <>
            <div style={{ marginBottom: '10px', color: token.colorTextSecondary }}>
              현재 선택된 리워드: {selectedRewardIds.length > 0 ? selectedRewardIds.map(id => `#${id}`).join(', ') : '없음'}
            </div>
            
            {/* 리워드 상태는 컴포넌트 자체 상태로만 관리하고 폼에는 포함하지 않음 */}
            
            {/* Transfer 컴포넌트에 직접 상태 제어 로직 적용 */}
            <Transfer
              targetKeys={transferTargetKeys}
              onChange={handleRewardSelectChange}
              dataSource={rewardItems.map(item => ({
                key: item.id.toString(),
                title: item.title?.ko || item.title?.en || '제목 없음',
                description: `ID: ${item.id}`,
                disabled: false,
                order: item.order,
                thumbnail: item.thumbnail,
              }))}
              titles={['사용 가능한 리워드', '선택된 리워드']}
              render={item => (
                <Space>
                  {item.thumbnail && (
                    <Image
                      src={getCdnImageUrl(item.thumbnail, 40)}
                      alt="리워드 썸네일"
                      width={30}
                      height={30}
                      style={{ objectFit: 'cover', borderRadius: '4px' }}
                    />
                  )}
                  <span>{item.title}</span>
                </Space>
              )}
              listStyle={{ width: 350, height: 300 }}
              style={{ marginBottom: '20px' }}
            />
          </>
        )}
      </div>

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
                <div key={item.temp_id} style={{ position: 'relative' }}>
                  <ArtistCard
                    artist={item.artist!}
                    showDeleteButton
                    onDelete={() =>
                      handleRemoveArtist(
                        item.temp_id!,
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

