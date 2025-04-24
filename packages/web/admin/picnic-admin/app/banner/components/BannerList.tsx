'use client';

import { List, CreateButton, useTable, DateField } from '@refinedev/antd';
import { useNavigation, useResource } from '@refinedev/core';
import { Space, Tag, Image, Select } from 'antd';
import { useState, useEffect } from 'react';
import { useSearchParams, usePathname, useRouter } from 'next/navigation';
import { Banner } from '@/lib/types/banner';
import { getCdnImageUrl } from '@/lib/image';
import { BANNER_LOCATIONS } from '@/lib/banner';
import { DataTable } from '../../components/common/DataTable';

// 배너 상태 상수 정의
const BANNER_STATUS = {
  ALL: 'all',
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  ENDED: 'ended',
};

type BannerStatus = (typeof BANNER_STATUS)[keyof typeof BANNER_STATUS];

export default function BannerList() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const { show } = useNavigation();
  const { resource } = useResource();

  // URL에서 status 파라미터 가져오기
  const urlStatus = searchParams.get('status') as BannerStatus | null;
  const initialStatus = Object.values(BANNER_STATUS).includes(
    urlStatus as BannerStatus,
  )
    ? (urlStatus as BannerStatus)
    : BANNER_STATUS.ALL;

  const [statusFilter, setStatusFilter] = useState<BannerStatus>(initialStatus);
  const [filteredData, setFilteredData] = useState<Banner[]>([]);

  const { tableProps } = useTable<Banner>({
    resource: 'banner',
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
      select: '*',
    },
  });

  // URL 파라미터 업데이트
  const updateUrlParams = (status: BannerStatus) => {
    const params = new URLSearchParams(searchParams.toString());

    if (status === BANNER_STATUS.ALL) {
      params.delete('status');
    } else {
      params.set('status', status);
    }

    router.push(`${pathname}?${params.toString()}`);
  };

  // 데이터가 로드된 후 필터링 적용
  useEffect(() => {
    if (tableProps.dataSource && tableProps.dataSource.length > 0) {
      const now = new Date();

      if (statusFilter === BANNER_STATUS.ALL) {
        setFilteredData([...tableProps.dataSource]);
        return;
      }

      const filtered = tableProps.dataSource.filter((banner) => {
        const startAt = banner.start_at ? new Date(banner.start_at) : null;
        const endAt = banner.end_at ? new Date(banner.end_at) : null;

        if (statusFilter === BANNER_STATUS.UPCOMING) {
          return startAt && now < startAt;
        } else if (statusFilter === BANNER_STATUS.ONGOING) {
          return startAt && (!endAt || (now >= startAt && now <= endAt));
        } else if (statusFilter === BANNER_STATUS.ENDED) {
          return endAt && now > endAt;
        }
        return false;
      });

      setFilteredData([...filtered]);
    }
  }, [tableProps.dataSource, statusFilter]);

  // 컴포넌트 마운트 시 URL에서 상태 복원
  useEffect(() => {
    if (
      urlStatus &&
      Object.values(BANNER_STATUS).includes(urlStatus as BannerStatus)
    ) {
      setStatusFilter(urlStatus as BannerStatus);
    }
  }, [urlStatus]);

  const handleStatusChange = (value: BannerStatus) => {
    const newStatus = value || BANNER_STATUS.ALL;
    setStatusFilter(newStatus);
    updateUrlParams(newStatus);
  };

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
    <List breadcrumb={false} title={resource?.meta?.list?.label || ''}>
      <Space style={{ marginBottom: 16 }}>
        <Select
          style={{ width: 160, maxWidth: '100%' }}
          placeholder='노출 상태'
          value={statusFilter}
          onChange={handleStatusChange}
          options={[
            { label: '전체', value: BANNER_STATUS.ALL },
            { label: '노출중', value: BANNER_STATUS.ONGOING },
            { label: '노출예정', value: BANNER_STATUS.UPCOMING },
            { label: '노출종료', value: BANNER_STATUS.ENDED },
          ]}
        />
      </Space>
      <DataTable
        resource='banner'
        columns={[
          {
            dataIndex: 'id',
            title: 'ID',
            width: 80,
          },
          {
            dataIndex: 'image',
            title: '이미지',
            align: 'center',
            responsive: ['md'],
            render: (value: any) => (
              <Space direction='vertical' size='small'>
                <Space size='small'>
                  <Image
                    src={getCdnImageUrl(value.ko, 80)}
                    alt='배너 이미지 (한국어)'
                    width={80}
                    preview={false}
                  />
                  <Image
                    src={getCdnImageUrl(value.en, 80)}
                    alt='배너 이미지 (영어)'
                    width={80}
                    preview={false}
                  />
                </Space>
                <Space size='small'>
                  <Image
                    src={getCdnImageUrl(value.ja, 80)}
                    alt='배너 이미지 (일본어)'
                    width={80}
                    preview={false}
                  />
                  <Image
                    src={getCdnImageUrl(value.zh, 80)}
                    alt='배너 이미지 (중국어)'
                    width={80}
                    preview={false}
                  />
                </Space>
              </Space>
            ),
          },
          {
            dataIndex: ['start_at', 'end_at'],
            title: '시작일/종료일',
            align: 'center',
            width: 160,
            render: (value: any, record: Banner) => (
              <Space direction='vertical' size='small'>
                {record?.start_at &&
                  record?.end_at &&
                  getBannerStatus(
                    record.start_at.toString(),
                    record.end_at.toString(),
                  )}
                <DateField
                  value={record?.start_at?.toString()}
                  format='YYYY-MM-DD'
                />
                <DateField
                  value={record?.end_at?.toString()}
                  format='YYYY-MM-DD'
                />
              </Space>
            ),
          },
          {
            dataIndex: 'location',
            title: '위치',
            align: 'center',
            width: 100,
            render: (value: string) => {
              const locationObj = BANNER_LOCATIONS?.find(
                (loc) => loc.value === value,
              );
              return locationObj ? locationObj.label : value || '-';
            },
          },
          {
            dataIndex: 'order',
            title: '순서',
            align: 'center',
            width: 80,
          },
          {
            dataIndex: ['created_at', 'updated_at'],
            title: '생성일/수정일',
            align: 'center',
            width: 140,
            responsive: ['lg'],
            render: (value: any, record: Banner) => (
              <Space direction='vertical' size='small'>
                <DateField
                  value={record?.created_at?.toString()}
                  format='YYYY-MM-DD'
                />
                <DateField
                  value={record?.updated_at?.toString()}
                  format='YYYY-MM-DD'
                />
              </Space>
            ),
          },
        ]}
        sorters={{
          initial: [
            {
              field: 'created_at',
              order: 'desc',
            },
          ],
        }}
      />
    </List>
  );
}
