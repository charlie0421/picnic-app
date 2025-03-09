'use client';

import * as React from 'react';
import styles from './right-sidebar.module.css';

export default function RightSidebar() {
  return (
    <div className={styles.container}>
      <div className={styles.videoContainer}>
        <video 
          className={styles.video}
          autoPlay
          loop
          muted
          playsInline
        >
      <source src='/videos/picnic.mp4' type='video/mp4' />
      브라우저가 비디오 태그를 지원하지 않습니다.
        </video>
      </div>
    </div>
  );
} 