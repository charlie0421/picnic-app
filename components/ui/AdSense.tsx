'use client';

import {useEffect} from 'react';

interface AdSenseProps {
  client: string;
  slot: string;
  style?: React.CSSProperties;
  format?: 'auto' | 'rectangle' | 'horizontal' | 'vertical';
  responsive?: 'true' | 'false';
}

const AdSense: React.FC<AdSenseProps> = ({
  client,
  slot,
  style = { display: 'block' },
  format = 'auto',
  responsive = 'true'
}) => {
  useEffect(() => {
    // 애드센스 스크립트가 이미 로드되었는지 확인
    const hasAdScript = document.querySelector('script[src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"]');

    if (!hasAdScript) {
      // 애드센스 스크립트 로드
      const adScript = document.createElement('script');
      adScript.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${client}`;
      adScript.async = true;
      adScript.crossOrigin = 'anonymous';
      document.head.appendChild(adScript);
    }

    // 광고 로드
    try {
      (window as any).adsbygoogle = (window as any).adsbygoogle || [];
      (window as any).adsbygoogle.push({});
    } catch (error) {
      console.error('AdSense 오류:', error);
    }
  }, [client]);

  return (
    <ins
      className="adsbygoogle"
      style={style}
      data-ad-client={client}
      data-ad-slot={slot}
      data-ad-format={format}
      data-full-width-responsive={responsive}
    />
  );
};

export default AdSense;
