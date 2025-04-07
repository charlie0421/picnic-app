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
import { getImageUrl } from '@/lib/image';
import { VOTE_CATEGORIES, type VoteRecord } from '@/lib/vote';
import { VoteItem } from '@/types/vote';
import dayjs from 'dayjs';
import { COLORS } from '@/lib/theme';
import ArtistSelector from '@/components/artist-selector';
import ImageUpload from '@/components/upload';
import ArtistCard from '@/components/artist/ArtistCard';
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
