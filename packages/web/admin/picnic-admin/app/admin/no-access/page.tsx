'use client';

import React from 'react';
import { Typography, Result } from 'antd';

const { Title, Paragraph } = Typography;

export default function NoAccessPage() {
  return (
    <Result
      status='403'
      title='접근 권한 없음'
      subTitle='현재 계정으로는 접근 가능한 메뉴가 없습니다. 관리자에게 문의하세요.'
    />
  );
}
