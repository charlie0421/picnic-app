'use client';

import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import styles from './RankCard.module.css';
import Image from 'next/image';

type RankCardProps = {
  rank: number;
  name: string | { [key: string]: string };
  groupName: string | { [key: string]: string };
  votes: number;
  photoUrl?: string;
};

const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL as string;

export function RankCard({
  rank,
  name,
  votes,
  photoUrl,
  groupName,
}: RankCardProps) {
  const voteRef = useRef<number>(votes);

  // 이미지 크기 설정
  const sizeMap: Record<number, number> = {
    1: 280,
    2: 120,
    3: 90,
  };
  const photoSize = sizeMap[rank] || 90;

  // 투표수 변경 감지
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
    typeof name === 'object' ? name.en || Object.values(name)[0] : name;

  return (
    <motion.div
      className={`${styles.card} ${styles.rankItem}`}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
    >
      <div className={styles.imageContainer}>
        {photoUrl ? (
          <div className={styles.image}>
            <Image
              src={`${cdnUrl}/${photoUrl}?w=${photoSize * 2}&q=90`}
              alt={displayName}
              fill
              sizes={`${photoSize}px`}
              style={{ objectFit: 'cover' }}
            />
          </div>
        ) : (
          <div className={styles.noImage}>
            <span className={styles.noImageText}>No Image</span>
          </div>
        )}
        <div
          className={`${styles.logoContainer} ${
            styles[`logoContainer${rank}`]
          }`}
        >
          <div className={`${styles.groupName} ${styles[`groupName${rank}`]}`}>
            {typeof groupName === 'object'
              ? groupName.en || Object.values(groupName)[0]
              : groupName}
          </div>
        </div>
      </div>

      <div className={`${styles.voteCountCard} ${styles[`voteCount${rank}`]}`}>
        <motion.span
          initial={{ scale: 1 }}
          animate={{ scale: voteChanged ? 1.3 : 1 }}
          transition={{ duration: 0.2 }}
        >
          {votes.toLocaleString()}
        </motion.span>
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
    </motion.div>
  );
}
