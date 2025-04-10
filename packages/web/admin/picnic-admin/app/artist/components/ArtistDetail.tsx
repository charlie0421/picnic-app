'use client';

import { Image, Descriptions, Space, Typography, Tag } from 'antd';
import { Artist } from '@/lib/types/artist';
import { getCdnImageUrl } from '@/lib/image';
import { DateField, TextField } from '@refinedev/antd';
import { MultiLanguageDisplay } from '@/components/ui';
import { useMany } from '@refinedev/core';

const { Text } = Typography;

type ArtistDetailProps = {
  record?: Artist;
  loading?: boolean;
};

export default function ArtistDetail({ record, loading }: ArtistDetailProps) {
  // 아티스트 그룹 정보 가져오기
  const { data: groupData } = useMany({
    resource: 'artist_group',
    ids: record?.artist_group_id ? [record.artist_group_id] : [],
    queryOptions: {
      enabled: !!record?.artist_group_id,
    },
  });

  const group = groupData?.data?.[0];

  const descriptionItems = [
    {
      key: 'id',
      label: 'ID',
      children: <TextField value={record?.id} />,
    },
    {
      key: 'name',
      label: '이름',
      children: <MultiLanguageDisplay value={record?.name} />,
    },
    {
      key: 'image',
      label: '이미지',
      children: record?.image ? (
        <Image
          src={getCdnImageUrl(record.image)}
          alt='아티스트 이미지'
          width={300}
          style={{ borderRadius: '8px' }}
        />
      ) : (
        '-'
      ),
    },
    {
      key: 'gender',
      label: '성별',
      children: (
        <Tag color={record?.gender === 'male' ? 'blue' : 'pink'}>
          {record?.gender === 'male'
            ? '남성'
            : record?.gender === 'female'
            ? '여성'
            : record?.gender}
        </Tag>
      ),
    },
    {
      key: 'artist_group',
      label: '소속 그룹',
      children: group ? (
        <Space direction='vertical' size='small'>
          {group.image && (
            <Image
              src={getCdnImageUrl(group.image)}
              alt='그룹 이미지'
              width={200}
              style={{ borderRadius: '8px' }}
            />
          )}
          <MultiLanguageDisplay value={group.name} />
        </Space>
      ) : (
        '-'
      ),
    },
    {
      key: 'birth_date',
      label: '생년월일',
      children: <DateField value={record?.birth_date} format='YYYY-MM-DD' />,
    },
    {
      key: 'debut_date',
      label: '데뷔일',
      children: <DateField value={record?.debut_date} format='YYYY-MM-DD' />,
    },
    {
      key: 'created_at',
      label: '생성일',
      children: (
        <DateField value={record?.created_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      key: 'updated_at',
      label: '수정일',
      children: (
        <DateField value={record?.updated_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
  ];

  return (
    <Descriptions
      bordered
      column={1}
      layout='vertical'
      items={descriptionItems}
      size='small'
    />
  );
}
