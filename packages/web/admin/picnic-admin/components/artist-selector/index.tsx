import { useState, useEffect, useMemo } from 'react';
import { Select, Space, Modal, Button, message } from 'antd';
import { useList } from '@refinedev/core';
import { getImageUrl } from '@/lib/image';
import { VoteItem } from '@/types/vote';
import { Artist, ArtistGroup } from '@/types/artist';
import { PlusOutlined } from '@ant-design/icons';
import { COLORS } from '@/lib/theme';

interface ArtistSelectorProps {
  onArtistAdd: (newVoteItem: VoteItem) => void;
  existingArtistIds?: string[]; // 이미 선택된 아티스트 ID 목록
  buttonText?: string;
  modalTitle?: string;
}

const ArtistSelector: React.FC<ArtistSelectorProps> = ({
  onArtistAdd,
  existingArtistIds = [],
  buttonText = '아티스트 추가',
  modalTitle = '아티스트 추가',
}) => {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedArtist, setSelectedArtist] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [allArtists, setAllArtists] = useState<Artist[]>([]);

  // 아티스트 목록 가져오기
  const { data: artistsData, isLoading: artistsLoading } = useList({
    resource: 'artist',
    meta: {
      select:
        'id,name,image,birth_date,yy,mm,dd,artist_group(id,name,image,debut_yy,debut_mm,debut_dd)',
    },
    pagination: {
      pageSize: 10000,
    },
  });

  // 아티스트 데이터 설정
  useEffect(() => {
    if (artistsData?.data) {
      setAllArtists(artistsData.data as Artist[]);
    }
  }, [artistsData]);

  // 클라이언트 측 필터링된 아티스트
  const artists = useMemo(() => {
    if (!allArtists.length) {
      return [];
    }

    if (!searchQuery) {
      return allArtists;
    }

    const lowerCaseQuery = searchQuery.toLowerCase();
    return allArtists.filter((artist) => {
      const koName = artist.name?.ko?.toLowerCase() || '';
      const enName = artist.name?.en?.toLowerCase() || '';
      const groupName = artist.artist_group?.name?.ko?.toLowerCase() || '';
      return (
        koName.includes(lowerCaseQuery) ||
        enName.includes(lowerCaseQuery) ||
        groupName.includes(lowerCaseQuery)
      );
    });
  }, [allArtists, searchQuery]);

  // 아티스트 선택 변경 핸들러
  const handleArtistSelect = (value: string) => {
    setSelectedArtist(value);
  };

  // 검색어 변경 핸들러
  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setIsSearching(!!value);
  };

  // 모달 표시
  const showModal = () => {
    setIsModalVisible(true);
    setSelectedArtist(null);
    setSearchQuery('');
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
    if (existingArtistIds.includes(selectedArtist)) {
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

    onArtistAdd(newVoteItem);
    setIsModalVisible(false);
    setSelectedArtist(null);
    messageApi.success('아티스트가 추가되었습니다');
  };

  return (
    <>
      {contextHolder}
      <Button
        type='primary'
        icon={<PlusOutlined />}
        onClick={showModal}
        style={{
          backgroundColor: COLORS.primary,
          borderColor: COLORS.primary,
        }}
      >
        {buttonText}
      </Button>

      <Modal
        title={modalTitle}
        open={isModalVisible}
        onOk={handleAddArtist}
        onCancel={handleCancel}
      >
        <div>
          <div style={{ marginBottom: '10px' }}>아티스트 선택:</div>
          <Select
            showSearch
            placeholder='아티스트 이름 검색...'
            onChange={handleArtistSelect}
            onSearch={handleSearch}
            value={selectedArtist}
            style={{ width: '100%' }}
            listHeight={300}
            loading={artistsLoading}
            notFoundContent={
              searchQuery
                ? artistsLoading
                  ? '검색 중...'
                  : '검색 결과가 없습니다'
                : '검색하려면 아티스트 이름을 입력해주세요'
            }
            options={artists.map((artist) => ({
              value: artist.id,
              label:
                `${artist.name?.ko || ''} ${
                  artist.name?.en ? `(${artist.name.en})` : ''
                }${
                  artist.artist_group?.name?.ko
                    ? ` - ${artist.artist_group.name.ko}`
                    : ''
                }`.trim() || '이름 없음',
            }))}
            filterOption={false}
          />
        </div>
      </Modal>
    </>
  );
};

export default ArtistSelector;
