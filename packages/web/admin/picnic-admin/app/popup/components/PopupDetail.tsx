'use client';

import React from 'react';
import { Typography, theme } from 'antd';
import { DateField } from '@refinedev/antd';
import { Popup } from '@/lib/types/popup';
import { getCardStyle, getSectionStyle, getTitleStyle } from '@/lib/ui';
import { MultiLanguageDisplay, UUIDDisplay } from '@/components/ui';
import { getCdnImageUrl } from '@/lib/image';
import Image from 'next/image';
import type { PlatformEnum } from '@/lib/types/popup';

const { Title } = Typography;

interface PopupDetailProps {
  record?: Popup;
}

export const PopupDetail: React.FC<PopupDetailProps> = ({ record }) => {
  const { token } = theme.useToken();

  if (!record) return null;

  return (
    <div style={getCardStyle(token)}>
      <Title level={4} style={getTitleStyle(token)}>
        팝업 상세
      </Title>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <UUIDDisplay uuid={String(record.id)} label='팝업 ID' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>제목</Title>
        <MultiLanguageDisplay value={record.title} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>내용</Title>
        <MultiLanguageDisplay value={record.content} />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>시작 일시</Title>
        <DateField value={record.start_at} format='YYYY-MM-DD HH:mm:ss' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>종료 일시</Title>
        <DateField value={record.stop_at} format='YYYY-MM-DD HH:mm:ss' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>이미지(한국어)</Title>
        {record?.image?.ko && (
          <Image
            src={getCdnImageUrl(record?.image?.ko, 100)}
            width={100}
            height={100}
            alt='이미지'
          />
        )}
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>이미지(영어)</Title>
        {record?.image?.en && (
          <Image
            src={getCdnImageUrl(record?.image?.en, 100)}
            width={100}
            height={100}
            alt='이미지'
          />
        )}
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>이미지(일본어)</Title>
        {record?.image?.ja && (
          <Image
            src={getCdnImageUrl(record?.image?.ja, 100)}
            width={100}
            height={100}
            alt='이미지'
          />
        )}
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>이미지(중국어)</Title>
        {record?.image?.zh && (
          <Image
            src={getCdnImageUrl(record?.image?.zh, 100)}
            width={100}
            height={100}
            alt='이미지'
          />
        )}
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>작성일</Title>
        <DateField value={record.created_at} format='YYYY-MM-DD' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>수정일</Title>
        <DateField value={record.updated_at} format='YYYY-MM-DD' />
      </div>

      <div style={{ ...getSectionStyle(token), marginTop: '16px' }}>
        <Title level={5}>플랫폼</Title>
        {(() => {
          switch (record.platform) {
            case 'all':
              return '전체';
            case 'android':
              return 'Android';
            case 'ios':
              return 'iOS';
            case 'web':
              return 'Web';
            default:
              return record.platform;
          }
        })()}
      </div>
    </div>
  );
};

export default PopupDetail;
