'use client';

import { DateField, List, useTable } from '@refinedev/antd';
import { useMany, useNavigation } from '@refinedev/core';
import { Space, Table, Row, Col } from 'antd';
import { Artist } from '@/types/artist';
import { useState, useEffect } from 'react';
import { supabaseBrowserClient } from '@utils/supabase/client';
import SearchBar from '@/components/common/SearchBar';
import MultiLanguageDisplay from '@/components/common/MultiLanguageDisplay';
import TableImage from '@/components/common/TableImage';

export default function ArtistList() {
  // 페이지 이동을 위한 hook 추가
  const { show } = useNavigation();
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [artists, setArtists] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  // 아티스트 데이터 가져오기
  useEffect(() => {
    const fetchArtists = async () => {
      setLoading(true);

      try {
        let query = supabaseBrowserClient
          .from('artist')
          .select('*')
          .order('id', { ascending: false });

        // 검색어가 있는 경우에만 필터 적용
        if (searchTerm) {
          query = query.or(
            `name->>ko.ilike.%${searchTerm}%,` +
              `name->>en.ilike.%${searchTerm}%,` +
              `name->>ja.ilike.%${searchTerm}%,` +
              `name->>zh.ilike.%${searchTerm}%`,
          );
        }

        const { data, error } = await query;

        if (error) {
          console.error('Error fetching artists:', error);
          setArtists([]);
        } else {
          setArtists(data || []);
        }
      } catch (error) {
        console.error('Error fetching artists:', error);
        setArtists([]);
      } finally {
        setLoading(false);
      }
    };

    fetchArtists();
  }, [searchTerm]);

  // 아티스트 그룹 정보 가져오기
  const { data: groupsData, isLoading: groupsIsLoading } = useMany({
    resource: 'artist_group',
    ids:
      (artists
        ?.map((item: any) => {
          const groupId = item?.group_id;
          return groupId ? String(groupId) : undefined;
        })
        .filter(Boolean) as string[]) ?? [],
    queryOptions: {
      enabled: !!artists.length,
    },
  });

  // 테이블 속성 생성
  const tableProps = {
    dataSource: artists,
    loading,
    pagination: {
      showSizeChanger: true,
      showTotal: (total: number) => `${total} 아이템`,
    },
  };

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <List>
      <SearchBar
        placeholder='아티스트 이름 검색 (모든 언어)'
        onSearch={handleSearch}
        width={300}
      />
      <Table
        {...tableProps}
        rowKey='id'
        scroll={{ x: 'max-content' }}
        onRow={(record: any) => {
          return {
            style: {
              cursor: 'pointer',
            },
            onClick: () => {
              if (record.id) {
                show('artist', record.id);
              }
            },
          };
        }}
      >
        <Table.Column dataIndex='id' title={'ID'} />
        <Table.Column
          dataIndex={['name']}
          title={'이름'}
          render={(value: Record<string, string>) => (
            <MultiLanguageDisplay value={value} />
          )}
        />
        <Table.Column
          dataIndex='image'
          title={'이미지'}
          width={130}
          render={(value: string) => (
            <TableImage
              src={value}
              alt='아티스트 이미지'
              width={100}
              height={100}
            />
          )}
        />
        <Table.Column dataIndex='gender' title={'성별'} />
        <Table.Column
          dataIndex={'group_id'}
          title={'그룹'}
          render={(value) =>
            groupsIsLoading ? (
              <>로딩 중...</>
            ) : (
              groupsData?.data?.find(
                (item) => Number(item.id) === Number(value),
              )?.name?.ko || '-'
            )
          }
        />
        <Table.Column
          dataIndex='birth_date'
          title={'생년월일'}
          render={(value: string) => value || '-'}
        />
        <Table.Column
          dataIndex={['created_at']}
          title={'생성일'}
          render={(value: any) => (
            <DateField value={value} format='YYYY-MM-DD' />
          )}
        />
      </Table>
    </List>
  );
}
