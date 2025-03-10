'use client';

import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import styles from './RankCard.module.css';
import Image from 'next/image';
import { supabase } from '../lib/supabaseClient';
import type { VoteData, VoteItem, LocalizedName } from '../../types/database.types';

type RankCardProps = {
  rank: number;
  name: string | { [key: string]: string };
  groupName: string | { [key: string]: string };
  votes: number;
  photoUrl?: string;
};

const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL as string;

export function RankCard({
  rank = 1,
  name = '테스트 이름',
  votes = 100,
  photoUrl,
  groupName = '테스트 그룹',
}: RankCardProps) {

  const voteRef = useRef(votes);
  const [voteData, setVoteData] = useState<{
    voteInfo: {
      id: string;
      vote_category: string;
      title: LocalizedName;
      start_at: string;
      stop_at: string;
    };
    topThree: VoteItem[];
  }>();

  // 이미지 크기 설정
  const sizeMap: Record<number, number> = {
    1: 100,
    2: 100,
    3: 100,
  };
  const photoSize = sizeMap[rank] || 90;

  // 투표수 변경 감지
  const [voteChanged, setVoteChanged] = useState(false);

  useEffect(() => {
    const fetchVotes = async () => {
      const { data, error } = await supabase
        .from('vote')
        .select(
          `
          id,
          vote_category,
          title,
          start_at,
          stop_at,
          vote_item(
            id,
            vote_total,
            artist(
              id,
              name,
              image,
              artist_group(
                id,
                name,
                image,
                created_at,
                updated_at,
                deleted_at
              ),
              created_at,
              updated_at,
              deleted_at
            ),
            created_at,
            updated_at,
            deleted_at
          )
        `,
        )
        // .eq('vote_category', 'birthday')
        .lte('start_at', 'now()')
        .gte('stop_at', 'now()')
        .order('vote_total', { ascending: false, foreignTable: 'vote_item' })
        .limit(1)
        .maybeSingle();

      if (error) {
        console.error('Error fetching votes:', error);
        return;
      }

      if (data) {
        setVoteData({
          voteInfo: {
            id: data.id as string,
            vote_category: data.vote_category as string,
            title: data.title as unknown as LocalizedName,
            start_at: data.start_at as string,
            stop_at: data.stop_at as string,
          },
          topThree: data.vote_item as unknown as VoteItem[],
        });
      }
    };

    fetchVotes();
    const interval = setInterval(fetchVotes, 1000);
    return () => clearInterval(interval);
  }, []);

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
          {votes}
        </motion.span>
      </div>

    </motion.div>
  );
}
