'use client';

import {
  List,
  useTable,
  DateField,
  CreateButton,
} from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Table, Space, Input, Image, Tooltip } from 'antd';
import { useState } from 'react';
import { Reward, defaultLocalizations } from './types';
import { getCdnImageUrl } from '@/lib/image';

export default function RewardList() {
  const [searchTerm, setSearchTerm] = useState<string>('');
  const { show, edit } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<Reward>({
    resource: 'reward',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
    meta: {
      search: searchTerm
        ? { query: searchTerm, fields: ['title'] }
        : undefined,
    },
  });

  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  // 다국어 제목 표시 함수
  const renderTitle = (record: Reward) => {
    // 사용 가능한 언어 순서로 제목 찾기 (한국어 우선)
    const title = record.title?.ko || record.title?.en || record.title?.ja || record.title?.zh || '-';
    
    // 다른 언어 버전이 있는 경우 툴팁으로 보여주기
    const otherTitles = defaultLocalizations
      .filter(locale => record.title?.[locale] && locale !== 'ko')
      .map(locale => {
        const label = locale === 'en' ? '영어' : locale === 'ja' ? '일본어' : '중국어';
        return `${label}: ${record.title?.[locale]}`;
      });
    
    if (otherTitles.length > 0) {
      return (
        <Tooltip title={<div>{otherTitles.map(t => <div key={t}>{t}</div>)}</div>}>
          <span>{title}</span>
        </Tooltip>
      );
    }
    
    return title;
  };

  return (
    <List
      headerButtons={<CreateButton />}
      title={resource?.meta?.list?.label}
    >
      <div style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder="리워드 검색"
          onSearch={handleSearch}
          style={{ width: 300 }}
          allowClear
        />
      </div>
      <Table
        {...tableProps}
        rowKey="id"
        onRow={(record) => ({
          style: {
            cursor: 'pointer',
          },
          onClick: () => show('reward', record.id),
        })}
      >
        <Table.Column
          title="ID"
          dataIndex="id"
          key="id"
          sorter
        />
        <Table.Column
          title="썸네일"
          dataIndex="thumbnail"
          key="thumbnail"
          render={(value) => value ? <Image src={getCdnImageUrl(value, 80)} alt="thumbnail" width={80} height={80} /> : '-'}
        />
        <Table.Column
          title="제목"
          dataIndex={['title', 'ko']}
          key="title"
          sorter
          render={(_, record: Reward) => renderTitle(record)}
        />
        <Table.Column
          title="순서"
          dataIndex="order"
          key="order"
          sorter
          render={(value) => value ?? '-'}
        />
        <Table.Column
          title="생성일"
          dataIndex="created_at"
          key="created_at"
          sorter
          render={(value) => <DateField value={value} format="YYYY-MM-DD HH:mm:ss" />}
        />
        <Table.Column
          title="수정일"
          dataIndex="updated_at"
          key="updated_at"
          sorter
          render={(value) => <DateField value={value} format="YYYY-MM-DD HH:mm:ss" />}
        />
      </Table>
    </List>
  );
} 