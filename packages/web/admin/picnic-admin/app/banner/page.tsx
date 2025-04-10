'use client';

import { List, CreateButton, useTable, DateField } from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Space, Table, Tag, Image, Input } from 'antd';
import { Banner } from '@/lib/types/banner';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { MultiLanguageDisplay } from '@/components/ui';
import { getCdnImageUrl } from '@/lib/image';
import { useState } from 'react';

export default function BannerList() {
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable<Banner>({
    resource: 'banner',
    syncWithLocation: true,
    filters: {
      mode: 'off',
    },
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
  });

  const getBannerStatus = (startAt: string, endAt: string | null) => {
    const now = new Date();
    const start = new Date(startAt);

    if (now < start) {
      return <Tag color='blue'>노출예정</Tag>;
    } else if (endAt && now > new Date(endAt)) {
      return <Tag color='red'>노출종료</Tag>;
    } else {
      return <Tag color='green'>노출중</Tag>;
    }
  };

  return (
    <AuthorizePage resource='banner' action='list'>
      <List
        breadcrumb={false}
        headerButtons={
          <Space>
            <CreateButton resource='banner' />
          </Space>
        }
        title={resource?.meta?.list?.label || ''}
      >
        <Table
          {...tableProps}
          rowKey='id'
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => show('banner', record.id),
          })}
          pagination={{
            ...tableProps.pagination,
            showSizeChanger: true,
            pageSizeOptions: ['10', '20', '50'],
            showTotal: (total) => `총 ${total}개 항목`,
          }}
        >
          <Table.Column dataIndex='id' title='ID' />
          <Table.Column
            dataIndex='title'
            title={'제목'}
            align='center'
            render={(value: any) => <MultiLanguageDisplay value={value} />}
          />
          <Table.Column
            dataIndex='image'
            title='이미지'
            align='center'
            render={(value: any) => (
              <Space direction='vertical'>
                <Space>
                  <Image
                    src={getCdnImageUrl(value.ko, 100)}
                    alt='배너 이미지 (한국어)'
                    width={100}
                    preview={false}
                  />
                  <Image
                    src={getCdnImageUrl(value.en, 100)}
                    alt='배너 이미지 (영어)'
                    width={100}
                    preview={false}
                  />
                </Space>
                <Space>
                  <Image
                    src={getCdnImageUrl(value.ja, 100)}
                    alt='배너 이미지 (일본어)'
                    width={100}
                    preview={false}
                  />
                  <Image
                    src={getCdnImageUrl(value.zh, 100)}
                    alt='배너 이미지 (중국어)'
                    width={100}
                    preview={false}
                  />
                </Space>
              </Space>
            )}
          />
          <Table.Column
            dataIndex={['start_at', 'end_at']}
            title='시작일/종료일'
            align='center'
            render={(value: any, record: Banner) => (
              <Space direction='vertical'>
                {record?.start_at &&
                  record?.end_at &&
                  getBannerStatus(
                    record.start_at.toString(),
                    record.end_at.toString(),
                  )}
                <DateField
                  value={record?.start_at?.toString()}
                  format='YYYY-MM-DD HH:mm:ss'
                />
                <DateField
                  value={record?.end_at?.toString()}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
            )}
          />
          <Table.Column dataIndex='location' title='위치' align='center' />
          <Table.Column dataIndex='order' title='순서' align='center' />
          <Table.Column
            dataIndex={['created_at', 'updated_at']}
            title='생성일/수정일'
            align='center'
            render={(value: any, record: Banner) => (
              <Space direction='vertical'>
                <DateField
                  value={record?.created_at?.toString()}
                  format='YYYY-MM-DD HH:mm:ss'
                />
                <DateField
                  value={record?.updated_at?.toString()}
                  format='YYYY-MM-DD HH:mm:ss'
                />
              </Space>
            )}
          />
        </Table>
      </List>
    </AuthorizePage>
  );
}
