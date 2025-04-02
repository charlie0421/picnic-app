'use client';

import { Create, useForm, getValueFromEvent } from '@refinedev/antd';
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
} from 'antd';
import {
  DeleteOutlined,
  PlusOutlined,
  UserOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { useEffect, useState } from 'react';
import { useNavigation, useList, useSelect } from '@refinedev/core';
import { getImageUrl } from '@/utils/image';
import { VOTE_CATEGORIES, type VoteRecord } from '@/utils/vote';
import dayjs from 'dayjs';
import { COLORS } from '@/utils/theme';

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
  birth_date?: string;
  yy?: number;
  mm?: number;
  dd?: number;
  artist_group?: {
    id: number;
    name?: {
      ko?: string;
      en?: string;
      ja?: string;
      zh?: string;
    };
    image?: string;
    debut_yy?: number;
    debut_mm?: number;
    debut_dd?: number;
  };
}

interface VoteItem {
  id?: string;
  artist_id: string;
  vote_total?: number;
  artist?: Artist;
  temp_id?: number;
  deleted?: boolean;
}

export default function VoteCreate() {
  const { push } = useNavigation();
  const [artists, setArtists] = useState<Artist[]>([]);
  const [selectedArtist, setSelectedArtist] = useState<string | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const { token } = theme.useToken();

  // 선택된 투표 항목들 관리
  const [voteItems, setVoteItems] = useState<VoteItem[]>([]);

  // 폼 정의
  const { formProps, saveButtonProps } = useForm<VoteRecord>({
    redirect: 'show',
    warnWhenUnsavedChanges: true,
  });

  // 아티스트 목록 가져오기
  const { data: artistsData, isLoading: artistsLoading } = useList({
    resource: 'artist',
    meta: {
      select:
        'id,name,image,birth_date,yy,mm,dd,artist_group(id,name,image,debut_yy,debut_mm,debut_dd)',
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
        setVoteItems(voteItems.filter((item) => item.temp_id !== voteItemId));
        messageApi.success('투표 항목이 삭제되었습니다');
      },
    });
  };

  // 폼 제출 핸들러 오버라이드
  const handleFormSubmit = async (values: any) => {
    // 원본 formProps.onFinish 호출 전에 vote_item 데이터 추가
    const updatedValues = {
      ...values,
      vote_item: voteItems.map((item) => ({
        artist_id: item.artist_id,
      })),
    };

    await formProps.onFinish?.(updatedValues);
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
                    // 이미지 요소 숨기기
                    e.currentTarget.style.display = 'none';

                    // 이미지 요소의 부모 요소에 있는 백업 플레이스홀더 표시
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
                    width: '30px',
                    height: '30px',
                    backgroundColor: '#f5f5f5',
                    borderRadius: '4px',
                    display: 'none',
                    alignItems: 'center',
                    justifyContent: 'center',
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
            <span style={{ textAlign: 'left' }}>
              {artistGroup.name?.ko || '-'}
              {artistGroup.name?.en && (
                <span
                  style={{
                    marginLeft: '4px',
                    color: '#8c8c8c',
                    fontWeight: 'normal',
                  }}
                >
                  ({artistGroup.name.en})
                </span>
              )}
            </span>
          </div>
        ) : (
          '-'
        ),
    },
    {
      title: '생일 🎂',
      dataIndex: ['artist'],
      key: 'birth_date',
      align: 'center' as const,
      render: (artist: Artist) => {
        if (artist.birth_date) {
          return dayjs(artist.birth_date).format('YYYY-MM-DD');
        } else if (artist.yy) {
          let birthDate = `${artist.yy}`;
          if (artist.mm) {
            birthDate += `.${artist.mm.toString().padStart(2, '0')}`;
            if (artist.dd) {
              birthDate += `.${artist.dd.toString().padStart(2, '0')}`;
            }
          }
          return birthDate;
        }
        return '-';
      },
    },
    {
      title: '데뷔일 🎤',
      dataIndex: ['artist', 'artist_group'],
      key: 'debut_date',
      align: 'center' as const,
      render: (artistGroup: Artist['artist_group']) => {
        if (!artistGroup?.debut_yy) return '-';

        let debutDate = `${artistGroup.debut_yy}`;
        if (artistGroup.debut_mm) {
          debutDate += `.${artistGroup.debut_mm.toString().padStart(2, '0')}`;
          if (artistGroup.debut_dd) {
            debutDate += `.${artistGroup.debut_dd.toString().padStart(2, '0')}`;
          }
        }

        return debutDate;
      },
    },
    {
      title: '액션',
      key: 'action',
      align: 'center' as const,
      render: (_: any, record: VoteItem) => (
        <Button
          danger
          icon={<DeleteOutlined />}
          onClick={() => handleRemoveArtist(record.temp_id as number, true)}
        >
          삭제
        </Button>
      ),
    },
  ];

  return (
    <Create
      saveButtonProps={{
        ...saveButtonProps,
        onClick: () => {
          formProps.form?.submit();
        },
        style: {
          backgroundColor: COLORS.primary,
          borderColor: COLORS.primary,
        },
      }}
      headerButtons={[]}
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
        <Form.Item
          label='제목 (일본어)'
          name={['title', 'ja']}
          rules={[
            {
              required: true,
              message: '일본어 제목을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>
        <Form.Item
          label='제목 (중국어)'
          name={['title', 'zh']}
          rules={[
            {
              required: true,
              message: '중국어 제목을 입력해주세요',
            },
          ]}
        >
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
                style={{
                  backgroundColor: COLORS.primary,
                  borderColor: COLORS.primary,
                }}
              >
                아티스트 추가
              </Button>
            </div>
            <Table
              dataSource={voteItems}
              columns={columns}
              rowKey={(record) => record.temp_id?.toString() || ''}
              pagination={false}
              size='small'
              bordered
              style={{ maxWidth: '100%', overflowX: 'auto' }}
              scroll={{ x: 1000 }}
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
              placeholder='아티스트 이름 검색...'
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
                      onError={(e) => {
                        e.currentTarget.style.display = 'none';
                      }}
                    />
                  )}
                  <span>{option.data.name?.ko || ''}</span>
                  <span>
                    {option.data.name?.en ? `(${option.data.name.en})` : ''}
                  </span>
                  {option.data.artist_group?.name?.ko && (
                    <span style={{ color: '#8c8c8c' }}>
                      - {option.data.artist_group.name.ko}
                    </span>
                  )}
                </Space>
              )}
            />
          </Form.Item>
        </Form>
      </Modal>
    </Create>
  );
}
