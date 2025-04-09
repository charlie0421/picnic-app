'use client';

import { Image, Descriptions, Space } from 'antd';
import { Banner } from '@/lib/types/banner';
import { getCdnImageUrl } from '@/lib/image';
import { DateField, TextField } from '@refinedev/antd';

type BannerDetailProps = {
  record?: Banner;
  loading?: boolean;
};

export default function BannerDetail({ record, loading }: BannerDetailProps) {
  const descriptionItems = [
    {
      key: 'id',
      label: 'ID',
      children: <TextField value={record?.id} />,
    },
    {
      key: 'image',
      label: '이미지',
      children: [
        <Space key='image' direction='vertical' size={16}>
          <Image
            src={getCdnImageUrl(record?.image?.ko)}
            alt='배너 이미지 (한국어)'
            width={300}
            preview={false}
          />
          <Image
            src={getCdnImageUrl(record?.image?.en)}
            alt='배너 이미지 (영어)'
            width={300}
            preview={false}
          />
          <Image
            src={getCdnImageUrl(record?.image?.ja)}
            alt='배너 이미지 (일본어)'
            width={300}
            preview={false}
          />
          <Image
            src={getCdnImageUrl(record?.image?.zh)}
            alt='배너 이미지 (중국어)'
            width={300}
            preview={false}
          />
        </Space>,
      ],
    },
    {
      key: 'link',
      label: '링크',
      children: <TextField value={record?.link} />,
    },
    {
      key: 'start_at',
      label: '시작일',
      children: (
        <DateField value={record?.start_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      key: 'end_at',
      label: '종료일',
      children: (
        <DateField value={record?.end_at} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      key: 'location',
      label: '위치',
      children: <TextField value={record?.location} />,
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
    {
      key: 'order',
      label: '순서',
      children: <TextField value={record?.order} />,
    },
  ];

  return (
    <Descriptions
      bordered
      column={1}
      layout='vertical'
      items={descriptionItems}
    />
  );
}
