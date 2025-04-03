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
} from 'antd';
import { DeleteOutlined, UserOutlined, TeamOutlined } from '@ant-design/icons';
import { useEffect, useState } from 'react';
import { useNavigation, useCreate, useUpdate } from '@refinedev/core';
import { getImageUrl } from '@/utils/image';
import { VOTE_CATEGORIES, type VoteRecord } from '@/utils/vote';
import { Artist, VoteItem } from '@/types/vote';
import dayjs from 'dayjs';
import { COLORS } from '@/utils/theme';
import ArtistSelector from '@/components/artist-selector';
import ImageUpload from '@/components/upload';
import React from 'react';

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

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>(initialVoteItems);

  // vote_item 생성/수정/삭제 훅
  const { mutate: createVoteItem } = useCreate();
  const { mutate: updateVoteItem } = useUpdate();

  // initialVoteItems가 변경될 때마다 voteItems 업데이트
  useEffect(() => {
    if (initialVoteItems.length > 0) {
      setVoteItems(initialVoteItems);
    }
  }, [initialVoteItems]);

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

  // 폼 제출 핸들러
  const handleFormSubmit = async (values: any) => {
    try {
      // 원본 값에서 vote_item 제거 (중첩 데이터 방지)
      const { vote_item, ...restValues } = values;

      // 기본 정보 저장
      const result = await (onFinish
        ? onFinish(restValues)
        : formProps.onFinish?.(restValues));

      const voteId = result?.data?.id || id;

      if (voteId) {
        if (mode === 'edit') {
          // 삭제된 항목 처리 - soft delete
          const itemsToSoftDelete = voteItems.filter(
            (item) => item.is_existing && item.deleted,
          );

          for (const item of itemsToSoftDelete) {
            await updateVoteItem({
              resource: 'vote_item',
              id: item.id as string,
              values: {
                deleted_at: new Date().toISOString(),
              },
            });
          }
        }

        // 새 항목 추가 및 기존 항목 업데이트 (삭제되지 않은 것만)
        const activeItems = voteItems.filter((item) => !item.deleted);

        for (const item of activeItems) {
          if (mode === 'edit' && item.is_existing) {
            // 기존 항목 업데이트 (필요한 경우)
            await updateVoteItem({
              resource: 'vote_item',
              id: item.id as string,
              values: {
                artist_id: item.artist_id,
                vote_id: voteId,
              },
            });
          } else {
            // 신규 항목 생성
            await createVoteItem({
              resource: 'vote_item',
              values: {
                artist_id: item.artist_id,
                vote_id: voteId,
              },
            });
          }
        }

        message.success(
          mode === 'create'
            ? '투표가 성공적으로 생성되었습니다'
            : '투표가 성공적으로 업데이트되었습니다',
        );

        // 저장 후 리디렉션
        if (redirectPath) {
          push(redirectPath);
        } else {
          push(`/vote/show/${voteId}`);
        }
      }
    } catch (error) {
      console.error('Form submission error:', error);
      message.error(
        mode === 'create'
          ? '투표 생성 중 오류가 발생했습니다'
          : '투표 업데이트 중 오류가 발생했습니다',
      );
    }
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
            <img
              src={getImageUrl(image)}
              alt='아티스트 이미지'
              style={{
                width: '40px',
                height: '40px',
                objectFit: 'cover',
                borderRadius: '50%',
              }}
              onError={(e) => {
                const target = e.currentTarget;
                target.onerror = null;
                target.style.display = 'none';
                const parent = target.parentElement;
                if (parent) {
                  const placeholder = document.createElement('div');
                  placeholder.style.width = '40px';
                  placeholder.style.height = '40px';
                  placeholder.style.backgroundColor = '#f5f5f5';
                  placeholder.style.borderRadius = '50%';
                  placeholder.style.display = 'flex';
                  placeholder.style.alignItems = 'center';
                  placeholder.style.justifyContent = 'center';
                  placeholder.innerHTML =
                    '<span class="anticon"><svg viewBox="64 64 896 896" focusable="false" data-icon="user" width="24px" height="24px" fill="#bfbfbf" aria-hidden="true"><path d="M858.5 763.6a374 374 0 00-80.6-119.5 375.63 375.63 0 00-119.5-80.6c-.4-.2-.8-.3-1.2-.5C719.5 518 760 444.7 760 362c0-137-111-248-248-248S264 225 264 362c0 82.7 40.5 156 102.8 201.1-.4.2-.8.3-1.2.5-44.8 18.9-85 46-119.5 80.6a375.63 375.63 0 00-80.6 119.5A371.7 371.7 0 00136 901.8a8 8 0 008 8.2h60c4.4 0 7.9-3.5 8-7.8 2-77.2 33-149.5 87.8-204.3 56.7-56.7 132-87.9 212.2-87.9s155.5 31.2 212.2 87.9C779 752.7 810 825 812 902.2c.1 4.4 3.6 7.8 8 7.8h60a8 8 0 008-8.2c-1-47.8-10.9-94.3-29.5-138.2zM512 534c-45.9 0-89.1-17.9-121.6-50.4S340 407.9 340 362c0-45.9 17.9-89.1 50.4-121.6S466.1 190 512 190s89.1 17.9 121.6 50.4S684 316.1 684 362c0 45.9-17.9 89.1-50.4 121.6S557.9 534 512 534z"></path></svg></span>';
                  parent.appendChild(placeholder);
                }
              }}
            />
          </div>
        ) : (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <div
              style={{
                width: '40px',
                height: '40px',
                backgroundColor: '#f5f5f5',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <UserOutlined style={{ fontSize: '24px', color: '#bfbfbf' }} />
            </div>
          </div>
        ),
    },
    {
      title: '이름',
      dataIndex: ['artist', 'name'],
      key: 'name',
      align: 'center' as const,
      render: (name: Artist['name']) => {
        const koName = name?.ko || '';
        const enName = name?.en || '';

        return (
          <div
            style={{
              textAlign: 'center',
              fontWeight: 'bold',
              color: COLORS.primary,
            }}
          >
            {koName && <div>{koName}</div>}
            {enName && (
              <div
                style={{ fontSize: '0.9em', color: token.colorTextSecondary }}
              >
                {enName}
              </div>
            )}
            {!koName && !enName && '-'}
          </div>
        );
      },
    },
    {
      title: '그룹',
      dataIndex: ['artist', 'artist_group'],
      key: 'artist_group',
      align: 'center' as const,
      render: (artistGroup: Artist['artist_group']) =>
        artistGroup ? (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              justifyContent: 'flex-start',
            }}
          >
            {artistGroup.image ? (
              <div
                style={{ position: 'relative', width: '30px', height: '30px' }}
              >
                <img
                  src={getImageUrl(artistGroup.image)}
                  alt='그룹 이미지'
                  style={{
                    width: '30px',
                    height: '30px',
                    objectFit: 'cover',
                    borderRadius: '4px',
                  }}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    const parent = e.currentTarget.parentElement;
                    if (parent && parent.querySelector('.placeholder-backup')) {
                      const backup = parent.querySelector(
                        '.placeholder-backup',
                      ) as HTMLElement;
                      if (backup) {
                        backup.style.display = 'flex';
                      }
                    }
                  }}
                />
                <div
                  className='placeholder-backup'
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    display: 'none',
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: '#f5f5f5',
                    borderRadius: '4px',
                  }}
                >
                  <TeamOutlined
                    style={{ fontSize: '18px', color: '#bfbfbf' }}
                  />
                </div>
              </div>
            ) : (
              <div
                style={{
                  width: '30px',
                  height: '30px',
                  backgroundColor: '#f5f5f5',
                  borderRadius: '4px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <TeamOutlined style={{ fontSize: '18px', color: '#bfbfbf' }} />
              </div>
            )}

            <div>
              <div style={{ fontWeight: 'normal' }}>
                {artistGroup.name?.ko || artistGroup.name?.en || '-'}
              </div>
            </div>
          </div>
        ) : (
          '-'
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
      onFinish={handleFormSubmit}
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

      <div
        style={{
          backgroundColor: '#f5f5f5',
          borderRadius: '8px',
          padding: '16px',
          marginBottom: '24px',
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

        <Table
          rowKey='temp_id'
          dataSource={voteItems.filter((item) => !item.deleted)}
          columns={columns}
          pagination={false}
          size='small'
          style={{ marginBottom: '16px' }}
          locale={{
            emptyText: (
              <Empty description='투표 항목이 없습니다. 아티스트를 추가해주세요.' />
            ),
          }}
        />
      </div>

      <div
        style={{
          display: 'flex',
          justifyContent: 'flex-end',
          marginTop: '16px',
        }}
      >
        <Button
          type='primary'
          htmlType='submit'
          disabled={
            voteItems.filter((item) => !item.deleted).length === 0 ||
            saveButtonProps.disabled
          }
          loading={saveButtonProps.loading}
        >
          {mode === 'create' ? '투표 생성' : '투표 수정'}
        </Button>
      </div>
    </Form>
  );
}
