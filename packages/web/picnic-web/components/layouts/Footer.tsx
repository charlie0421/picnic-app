import React from 'react';
import { useLanguageStore } from '@/stores/languageStore';

const Footer: React.FC = () => {
  const { currentLanguage } = useLanguageStore();

  const content = {
    ko: {
      company:
        '상호명: 주식회사 아이콘캐스팅 | 사업자등록번호: 715-88-02791 | 대표자명: 황재근',
      address:
        '사업장주소지: 경기도 고양시 일산동구 태극로 60, 1503호(장항동,빛마루)',
      contact:
        '전화번호: 070-8058-9950 | 통신판매업번호: 제2024-성남수정-0657호',
      copyright: '© 2024 IconCasting Inc. All rights reserved.',
    },
    en: {
      company:
        'Company: IconCasting Inc. | Business Registration No: 715-88-02791 | CEO: Jaegeun Hwang',
      address:
        'Address: 1503, 60 Taeguk-ro, Ilsandong-gu, Goyang-si, Gyeonggi-do, Korea',
      contact:
        'Phone: 070-8058-9950 | E-commerce Registration No: 2024-Seongnam-Sujeong-0657',
      copyright: '© 2024 IconCasting Inc. All rights reserved.',
    },
  };

  const currentContent = currentLanguage === 'ko' ? content.ko : content.en;

  return (
    <footer className='w-full py-4 px-10 text-center text-gray-500 text-xs'>
      <p className='space-y-2'>
        <span className='block'>{currentContent.company}</span>
        <span className='block'>{currentContent.address}</span>
        <span className='block'>{currentContent.contact}</span>
        <span className='block mt-4'>{currentContent.copyright}</span>
      </p>
    </footer>
  );
};

export default Footer;
