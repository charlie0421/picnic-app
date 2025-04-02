'use client';

import { Edit, useForm, useSelect, useTable } from '@refinedev/antd';
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
} from 'antd';
import { DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import { useEffect, useState } from 'react';
import { useList, useNavigation, BaseRecord } from '@refinedev/core';
import { getImageUrl } from '@/utils/image';
import { VOTE_CATEGORIES, type VoteRecord } from '@/utils/vote';
import dayjs from 'dayjs';

// 아티스트와 투표 항목 인터페이스 정의
interface Artist {
  id: string;
  name?: {
    ko?: string;
    en?: string;
    ja?: string;
    zh?: string;
  };
  image?: string;
}

interface VoteItem {
  id?: string;
  artist_id: string;
  vote_total?: number;
  artist?: Artist;
  temp_id?: number;
  deleted?: boolean;
}

export default function VoteEdit() {
  const { push } = useNavigation();
  const [artists, setArtists] = useState<Artist[]>([]);
  const [selectedArtist, setSelectedArtist] = useState<string | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();

  // 투표 폼 데이터 가져오기
  const { formProps, saveButtonProps, queryResult, id } = useForm<VoteRecord>({
    meta: {
      select:
        'id, title, main_image, vote_category, start_at, stop_at, vote_item(id, artist_id, vote_total, artist(id, name, image))',
    },
    redirect: 'show',
    warnWhenUnsavedChanges: true,
  });

  const voteData = queryResult?.data?.data;

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);

  // 초기 vote_item 데이터 설정
  useEffect(() => {
    if (voteData?.vote_item) {
      setVoteItems(voteData.vote_item as VoteItem[]);
    }
  }, [voteData]);

  // 아티스트 목록 가져오기
  const { data: artistsData, isLoading: artistsLoading } = useList({
    resource: 'artist',
    meta: {
      select: 'id,name,image',
    },
  });

  // 아티스트 데이터 설정
  useEffect(() => {
    if (artistsData?.data) {
      setArtists(artistsData.data as Artist[]);
    }
  }, [artistsData]);

  // 아티스트 선택 변경 핸들러
  const handleArtistSelect = (value: string) => {
    setSelectedArtist(value);
  };

  // 아티스트 추가 모달 표시
  const showAddArtistModal = () => {
    setIsModalVisible(true);
  };

  // 모달 취소 핸들러
  const handleCancel = () => {
    setIsModalVisible(false);
    setSelectedArtist(null);
  };

  // 아티스트 추가 핸들러
  const handleAddArtist = () => {
    if (!selectedArtist) {
      messageApi.error('아티스트를 선택해주세요');
      return;
    }

    // 이미 추가된 아티스트인지 확인
    const isAlreadyAdded = voteItems.some(
      (item) => item.artist_id === selectedArtist,
    );

    if (isAlreadyAdded) {
      messageApi.error('이미 추가된 아티스트입니다');
      return;
    }

    // 선택된 아티스트 정보 가져오기
    const selectedArtistData = artists.find(
      (artist) => artist.id === selectedArtist,
    );

    // 새 투표 항목 추가
    const newVoteItem: VoteItem = {
      artist_id: selectedArtist,
      vote_total: 0,
      artist: selectedArtistData,
      temp_id: Date.now(), // 임시 ID (추가 전용)
    };

    setVoteItems([...voteItems, newVoteItem]);
    setIsModalVisible(false);
    setSelectedArtist(null);
    messageApi.success('아티스트가 추가되었습니다');
  };

  // 아티스트 삭제 핸들러
  const handleRemoveArtist = (
    voteItemId: string | number,
    isNewItem = false,
  ) => {
    Modal.confirm({
      title: '투표 항목 삭제',
      content: '이 투표 항목을 삭제하시겠습니까?',
      onOk: () => {
        if (isNewItem) {
          // 새로 추가된 항목은 단순히 로컬 상태에서만 제거
          setVoteItems(voteItems.filter((item) => item.temp_id !== voteItemId));
        } else {
          // 기존 항목은 삭제 플래그 설정 (soft delete)
          setVoteItems(
            voteItems.map((item) =>
              item.id === voteItemId ? { ...item, deleted: true } : item,
            ),
          );
        }
        messageApi.success('투표 항목이 삭제되었습니다');
      },
    });
  };

  // 폼 제출 핸들러 오버라이드
  const handleFormSubmit = async (values: any) => {
    // 원본 formProps.onFinish 호출 전에 vote_item 데이터 추가
    const updatedValues = {
      ...values,
      vote_item: voteItems.map((item) => {
        // 새로 추가된 항목인 경우
        if (item.temp_id) {
          return {
            artist_id: item.artist_id,
          };
        }
        // 기존 항목 중 삭제된 경우
        if (item.deleted) {
          return {
            id: item.id,
            deleted_at: new Date().toISOString(),
          };
        }
        // 변경 없는 기존 항목
        return {
          id: item.id,
        };
      }),
    };

    await formProps.onFinish?.(updatedValues);
  };

  // 투표 항목 테이블 컬럼 설정
  const columns = [
    {
      title: '아티스트 ID',
      dataIndex: ['artist', 'id'],
      key: 'artist_id',
    },
    {
      title: '이미지',
      dataIndex: ['artist', 'image'],
      key: 'image',
      render: (image: string | undefined) =>
        image ? (
          <img
            src={getImageUrl(image)}
            alt='아티스트 이미지'
            style={{
              width: '40px',
              height: '40px',
              objectFit: 'cover',
              borderRadius: '50%',
            }}
          />
        ) : (
          '-'
        ),
    },
    {
      title: '이름 (한국어)',
      dataIndex: ['artist', 'name', 'ko'],
      key: 'name_ko',
      render: (text: string | undefined) => text || '-',
    },
    {
      title: '이름 (영어)',
      dataIndex: ['artist', 'name', 'en'],
      key: 'name_en',
      render: (text: string | undefined) => text || '-',
    },
    {
      title: '총 투표수',
      dataIndex: 'vote_total',
      key: 'vote_total',
      render: (text: number | undefined) => text?.toString() || '0',
    },
    {
      title: '액션',
      key: 'action',
      render: (_: any, record: VoteItem) => (
        <Button
          danger
          icon={<DeleteOutlined />}
          onClick={() =>
            handleRemoveArtist(
              record.id || (record.temp_id as number),
              !!record.temp_id,
            )
          }
          disabled={record.deleted}
        >
          삭제
        </Button>
      ),
    },
  ];

  return (
    <Edit
      saveButtonProps={{
        ...saveButtonProps,
        onClick: () => {
          formProps.form?.submit();
        },
      }}
    >
      {contextHolder}
      <Form {...formProps} layout='vertical' onFinish={handleFormSubmit}>
        <Form.Item
          label='제목 (한국어)'
          name={['title', 'ko']}
          rules={[
            {
              required: true,
              message: '한국어 제목을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>
        <Form.Item
          label='제목 (영어)'
          name={['title', 'en']}
          rules={[
            {
              required: true,
              message: '영어 제목을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>
        <Form.Item label='제목 (일본어)' name={['title', 'ja']}>
          <Input />
        </Form.Item>
        <Form.Item label='제목 (중국어)' name={['title', 'zh']}>
          <Input />
        </Form.Item>
        <Form.Item
          label='카테고리'
          name='vote_category'
          rules={[
            {
              required: true,
              message: '카테고리를 선택해주세요',
            },
          ]}
        >
          <Select options={VOTE_CATEGORIES} />
        </Form.Item>
        <Form.Item
          label='시작일'
          name='start_at'
          rules={[
            {
              required: true,
              message: '시작일을 입력해주세요',
            },
          ]}
          getValueProps={(value) => ({
            value: value ? dayjs(value) : undefined,
          })}
        >
          <DatePicker
            showTime
            format='YYYY-MM-DD HH:mm:ss'
            placeholder='시작일을 선택해주세요'
            style={{ width: '100%' }}
          />
        </Form.Item>
        <Form.Item
          label='종료일'
          name='stop_at'
          rules={[
            {
              required: true,
              message: '종료일을 입력해주세요',
            },
          ]}
          getValueProps={(value) => ({
            value: value ? dayjs(value) : undefined,
          })}
        >
          <DatePicker
            showTime
            format='YYYY-MM-DD HH:mm:ss'
            placeholder='종료일을 선택해주세요'
            style={{ width: '100%' }}
          />
        </Form.Item>
        <Form.Item label='메인 이미지' name='main_image'>
          <Input placeholder='이미지 경로' />
        </Form.Item>

        <div style={{ marginBottom: 16 }}>
          <Space direction='vertical' style={{ width: '100%' }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <h3>투표 항목</h3>
              <Button
                type='primary'
                icon={<PlusOutlined />}
                onClick={showAddArtistModal}
              >
                아티스트 추가
              </Button>
            </div>
            <Table
              dataSource={voteItems.filter((item) => !item.deleted)}
              columns={columns}
              rowKey={(record) => record.id || record.temp_id?.toString() || ''}
              pagination={false}
            />
          </Space>
        </div>
      </Form>

      <Modal
        title='아티스트 추가'
        open={isModalVisible}
        onOk={handleAddArtist}
        onCancel={handleCancel}
      >
        <Form layout='vertical'>
          <Form.Item label='아티스트 선택' required>
            <Select
              showSearch
              placeholder='아티스트 선택'
              optionFilterProp='children'
              onChange={handleArtistSelect}
              value={selectedArtist}
              filterOption={(input, option) =>
                (option?.label?.ko?.toLowerCase() || '').includes(
                  input.toLowerCase(),
                ) ||
                (option?.label?.en?.toLowerCase() || '').includes(
                  input.toLowerCase(),
                )
              }
              options={artists.map((artist) => ({
                value: artist.id,
                label: {
                  ko: artist.name?.ko || '',
                  en: artist.name?.en || '',
                },
                data: artist,
              }))}
              optionRender={(option: any) => (
                <Space>
                  {option.data.image && (
                    <img
                      src={getImageUrl(option.data.image)}
                      alt='아티스트 이미지'
                      style={{
                        width: '30px',
                        height: '30px',
                        objectFit: 'cover',
                        borderRadius: '50%',
                      }}
                    />
                  )}
                  <span>{option.data.name?.ko || ''}</span>
                  <span>
                    {option.data.name?.en ? `(${option.data.name.en})` : ''}
                  </span>
                </Space>
              )}
            />
          </Form.Item>
        </Form>
      </Modal>
    </Edit>
  );
}
