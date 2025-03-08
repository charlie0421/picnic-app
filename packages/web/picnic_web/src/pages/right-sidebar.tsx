import React from 'react';
import RightSidebar from '../components/RightSidebar';

import styles from './right-sidebar.module.css';


export default function RightSidebarPage() {
  return (
    <div className={styles.adSection}>
    <video className={styles.adVideo} autoPlay loop muted playsInline>
      <source src='/videos/picnic.mp4' type='video/mp4' />
    </video>
  </div>
);
}
