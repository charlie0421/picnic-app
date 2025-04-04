'use client';

import { DateField, List, useTable } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { Table, Image, Row, Col, Input } from 'antd';
import { getImageUrl } from '@/utils/image';
import dayjs from 'dayjs';
import { useState, useEffect } from 'react';
import { supabaseBrowserClient } from '@utils/supabase/client';

export default function ArtistGroupList() {
  // 페이지 이동을 위한 hook 추가
  const { show } = useNavigation();
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [artistGroups, setArtistGroups] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [inputValue, setInputValue] = useState<string>('');

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
    setSearchTerm(value.trim());
  };

  // 검색어 초기화 핸들러
  const handleClear = () => {
    setInputValue('');
    setSearchTerm('');
  };

  // 입력 핸들러
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
    if (!e.target.value) {
      handleClear();
    }
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
      <Row gutter={[16, 16]} style={{ marginBottom: '16px' }} align='middle'>
        <Col>
          <Input.Search
            placeholder='아티스트 그룹 이름 검색 (모든 언어)'
            value={inputValue}
            onChange={handleInputChange}
            onSearch={handleSearch}
            style={{ width: 300 }}
            allowClear
          />
        </Col>
      </Row>
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
          render={(value: Record<string, string>) => {
            if (!value) return '-';
            return (
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  wordBreak: 'break-word',
                }}
              >
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇰🇷</span>
                  <span>{value.ko || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇺🇸</span>
                  <span>{value.en || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇯🇵</span>
                  <span>{value.ja || '-'}</span>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ fontWeight: 'bold', flexShrink: 0 }}>🇨🇳</span>
                  <span>{value.zh || '-'}</span>
                </div>
              </div>
            );
          }}
        />
        <Table.Column
          dataIndex='image'
          title={'이미지'}
          width={130}
          render={(value: string) =>
            value ? (
              <Image
                src={getImageUrl(value)}
                alt='아티스트 그룹 이미지'
                width={100}
                height={100}
                style={{ objectFit: 'cover', borderRadius: '4px' }}
                preview={{
                  mask: '확대',
                }}
              />
            ) : (
              '-'
            )
          }
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
