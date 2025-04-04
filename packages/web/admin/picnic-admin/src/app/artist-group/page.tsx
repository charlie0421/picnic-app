'use client';

import { DateField, List, useTable } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table } from 'antd';
import dayjs from 'dayjs';
import { useState, useEffect } from 'react';
import { supabaseBrowserClient } from '@utils/supabase/client';
import SearchBar from '@/components/common/SearchBar';
import MultiLanguageDisplay from '@/components/common/MultiLanguageDisplay';
import TableImage from '@/components/common/TableImage';

export default function ArtistGroupList() {
  // 페이지 이동을 위한 hook 추가
  const { show } = useNavigation();
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [artistGroups, setArtistGroups] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  // 아티스트 그룹 데이터 가져오기
  useEffect(() => {
    const fetchArtistGroups = async () => {
      setLoading(true);

      try {
        let query = supabaseBrowserClient
          .from('artist_group')
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
          console.error('Error fetching artist groups:', error);
          setArtistGroups([]);
        } else {
          setArtistGroups(data || []);
        }
      } catch (error) {
        console.error('Error fetching artist groups:', error);
        setArtistGroups([]);
      } finally {
        setLoading(false);
      }
    };

    fetchArtistGroups();
  }, [searchTerm]);

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  // 테이블 속성 생성
  const tableProps = {
    dataSource: artistGroups,
    loading,
    pagination: {
      showSizeChanger: true,
      showTotal: (total: number) => `${total} 아이템`,
    },
  };

  return (
    <List>
      <SearchBar
        placeholder='아티스트 그룹 이름 검색 (모든 언어)'
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
                show('artist-group', record.id);
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
              alt='아티스트 그룹 이미지'
              width={100}
              height={100}
            />
          )}
        />
        <Table.Column
          title={'데뷔일'}
          render={(_, record: any) => {
            if (!record.debut_date) return '-';
            return dayjs(record.debut_date).format('YYYY년 MM월 DD일');
          }}
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
