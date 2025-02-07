'use client';

import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import styles from './RankCard.module.css';
import QRCode from 'react-qr-code';
import Image from 'next/image';

const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL as string;

type RankCardProps = {
  rank: number;
  name: string | { [key: string]: string };
  votes: number;
  logoUrl?: string;
  photoUrl?: string;
};

export function RankCard({
  rank,
  name,
  votes,
  logoUrl,
  photoUrl,
}: RankCardProps) {
  const voteRef = useRef<number>(votes);

  // ===============================
  // 3) 이미지 크기 설정 (rank)
  // ===============================
  const sizeMap: Record<number, number> = {
    1: 280,
    2: 120,
    3: 90,
  };
  const photoSize = sizeMap[rank] || 90;

  // ===============================
  // 4) 투표수 변경 감지
  // ===============================
  const [voteChanged, setVoteChanged] = useState(false);

  useEffect(() => {
    if (voteRef.current !== votes) {
      setVoteChanged(true);
      const timer = setTimeout(() => setVoteChanged(false), 300);
      return () => clearTimeout(timer);
    }
    voteRef.current = votes;
  }, [votes]);

  const displayName =
    typeof name === 'object' ? name.ko || Object.values(name)[0] : name;

  return (
    <motion.div
      className={styles.card}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
    >
      <div className={styles.imageContainer}>
        {photoUrl ? (
          <Image
            src={`${cdnUrl}/${photoUrl}?w=${photoSize}`}
            alt={displayName}
            width={photoSize}
            height={photoSize}
            className={styles.image}
          />
        ) : (
          <div className={styles.noImage}>
            <span className={styles.noImageText}>No Image</span>
          </div>
        )}
        <div className={styles.logoContainer}>
          {logoUrl && (
            <Image
              src={`${cdnUrl}/${logoUrl}`}
              alt={`${displayName} Logo`}
              width={48}
              height={48}
            />
          )}
        </div>
      </div>

      {rank === 1 && (
        <div className={styles.verticalName}>
          <motion.span
            initial={{ scale: 1 }}
            animate={{ scale: voteChanged ? 1.3 : 1 }}
            transition={{ duration: 0.2 }}
          >
            {displayName}
          </motion.span>
        </div>
      )}

      <div className={styles.qrCode}>
        <QRCode
          value={`https://www.picnic.fan/vote/detail/${rank}`}
          size={96}
        />
      </div>
    </motion.div>
  );
}
