'use client';

import { Image, Descriptions, Space, Typography } from 'antd';
import { Banner } from '@/lib/types/banner';
import { getCdnImageUrl } from '@/lib/image';
import { DateField, TextField } from '@refinedev/antd';

const { Text } = Typography;

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
      span: 3,
      children: (
        <Space direction='vertical' size={16}>
          {['ko', 'en', 'ja', 'zh'].map((lang) => (
            <div key={lang}>
              <Text
                type='secondary'
                style={{ marginBottom: '8px', display: 'block' }}
              >
                {lang === 'ko' && '한국어'}
                {lang === 'en' && '영어'}
                {lang === 'ja' && '일본어'}
                {lang === 'zh' && '중국어'}
              </Text>
              <Image
                src={getCdnImageUrl(
                  record?.image?.[lang as keyof typeof record.image],
                )}
                alt={`배너 이미지 (${lang})`}
                width={300}
                style={{ borderRadius: '8px' }}
              />
            </div>
          ))}
        </Space>
      ),
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
      key: 'order',
      label: '순서',
      children: <TextField value={record?.order} />,
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
