'use client';

import AdSense from './AdSense';

interface BannerAdProps {
  position: 'top' | 'bottom' | 'sidebar';
  className?: string;
}

const BannerAd: React.FC<BannerAdProps> = ({ position, className = '' }) => {
  // 포지션별 광고 슬롯 ID 설정
  let slotId = '';
  let style = {};

  switch (position) {
    case 'top':
      slotId = 'YOUR_TOP_BANNER_SLOT_ID'; // 실제 애드센스 슬롯 ID로 교체하세요
      style = { display: 'block', width: '728px', height: '90px', margin: '0 auto' };
      break;
    case 'bottom':
      slotId = 'YOUR_BOTTOM_BANNER_SLOT_ID'; // 실제 애드센스 슬롯 ID로 교체하세요
      style = { display: 'block', width: '728px', height: '90px', margin: '0 auto' };
      break;
    case 'sidebar':
      slotId = 'YOUR_SIDEBAR_BANNER_SLOT_ID'; // 실제 애드센스 슬롯 ID로 교체하세요
      style = { display: 'block', width: '300px', height: '600px' };
      break;
    default:
      slotId = 'YOUR_DEFAULT_BANNER_SLOT_ID'; // 실제 애드센스 슬롯 ID로 교체하세요
      style = { display: 'block', width: '300px', height: '250px' };
  }

  return (
    <div className={`banner-ad ${position}-banner ${className}`}>
      <AdSense
        client="ca-pub-YOUR_PUBLISHER_ID" // 실제 애드센스 퍼블리셔 ID로 교체하세요
        slot={slotId}
        style={style}
        format="auto"
        responsive="true"
      />
    </div>
  );
};

export default BannerAd; 