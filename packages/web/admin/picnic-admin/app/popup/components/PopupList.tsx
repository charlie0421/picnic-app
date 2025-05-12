'use client';

import React from 'react';
import { Space, Tag, Image } from 'antd';
import { useNavigation, CrudFilters } from '@refinedev/core';
import { EditButton, DeleteButton, DateField } from '@refinedev/antd';
import { Popup } from '@/lib/types/popup';
import { DataTable } from '../../components/common/DataTable';
import { MultiLanguageDisplay } from '@/components/ui';
import { getCdnImageUrl } from '@/lib/image';
import type { PlatformEnum } from '@/lib/types/popup';

export const PopupList: React.FC = () => {
  const { show } = useNavigation();

  const getPopupStatus = (startAt: string, stopAt: string) => {
    const now = new Date();
    const start = new Date(startAt);
    const end = stopAt ? new Date(stopAt) : null;

    if (now < start) {
      return <Tag color='blue'>노출예정</Tag>;
    } else if (end && now > end) {
      return <Tag color='red'>노출종료</Tag>;
    } else {
      return <Tag color='green'>노출중</Tag>;
    }
  };

  const columns = [
    { title: 'id', dataIndex: 'id', key: 'id', sorter: true },
    {
      title: '이미지',
      dataIndex: 'image',
      key: 'image',
      align: 'center' as const,
      render: (value: any) => {
        let imgObj: any;
        if (!value) {
          return '-';
        }
        if (typeof value === 'string') {
          try {
            imgObj = JSON.parse(value);
          } catch {
            return '-';
          }
        } else if (typeof value === 'object') {
          imgObj = value;
        } else {
          return '-';
        }
        return (
          <Space direction='vertical' size='small'>
            <Space size='small'>
              {imgObj.ko && (
                <Image
                  src={getCdnImageUrl(imgObj.ko, 80)}
                  alt='이미지(한국어)'
                  width={80}
                  preview={false}
                />
              )}
              {imgObj.en && (
                <Image
                  src={getCdnImageUrl(imgObj.en, 80)}
                  alt='이미지(영어)'
                  width={80}
                  preview={false}
                />
              )}
            </Space>
            <Space size='small'>
              {imgObj.ja && (
                <Image
                  src={getCdnImageUrl(imgObj.ja, 80)}
                  alt='이미지(일본어)'
                  width={80}
                  preview={false}
                />
              )}
              {imgObj.zh && (
                <Image
                  src={getCdnImageUrl(imgObj.zh, 80)}
                  alt='이미지(중국어)'
                  width={80}
                  preview={false}
                />
              )}
            </Space>
            <Space size='small'>
              {imgObj.id && (
                <Image
                  src={getCdnImageUrl(imgObj.id, 80)}
                  alt='이미지(인도네시아어)'
                  width={80}
                  preview={false}
                />
              )}
            </Space>
          </Space>
        );
      },
    },
    {
      title: '제목',
      dataIndex: 'title',
      key: 'title',
      sorter: true,
      render: (value: any) => <MultiLanguageDisplay value={value} />,
    },
    {
      title: '시작 일시',
      dataIndex: 'start_at',
      key: 'start_at',
      sorter: true,
      render: (value: string) => (
        <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      title: '종료 일시',
      dataIndex: 'stop_at',
      key: 'stop_at',
      sorter: true,
      render: (value: string) => (
        <DateField value={value} format='YYYY-MM-DD HH:mm:ss' />
      ),
    },
    {
      title: '상태',
      key: 'status',
      render: (_: any, record: Popup) =>
        getPopupStatus(record.start_at, record.stop_at),
    },
    {
      title: '작성일',
      dataIndex: 'created_at',
      key: 'created_at',
      sorter: true,
      render: (value: string) => (
        <DateField value={value} format='YYYY-MM-DD' />
      ),
    },
    {
      title: '플랫폼',
      dataIndex: 'platform',
      key: 'platform',
      render: (value: PlatformEnum) => {
        switch (value) {
          case 'all':
            return '전체';
          case 'android':
            return 'Android';
          case 'ios':
            return 'iOS';
          case 'web':
            return 'Web';
          default:
            return value;
        }
      },
    },
  ];

  return (
    <DataTable<Popup>
      resource='popup'
      columns={columns}
      onRow={(record) => ({
        onClick: () => show('popup', record.id),
        style: { cursor: 'pointer' },
      })}
      sorters={{
        initial: [
          {
            field: 'id',
            order: 'desc',
          },
        ],
      }}
    />
  );
};

export default PopupList;
