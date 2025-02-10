'use client';

import { useEffect, useState, useRef } from 'react';
import { supabase } from '@/lib/supabaseClient';
import { RankCard } from '@/components/RankCard';
import type { VoteData, VoteItem } from '@/types/database.types';
import styles from './page.module.css';
import { motion } from 'framer-motion';
import QRCode from 'react-qr-code';
import Image from 'next/image';

export default function HomePage() {
  const [voteData, setVoteData] = useState<VoteData>();
  const [version, setVersion] = useState<string | null>(null);
  const prevVotes = useRef<number[]>([]);

  useEffect(() => {
    if (voteData !== undefined) {
      const currentVotes = voteData.topThree?.map((item) => item.vote_total);
      prevVotes.current = currentVotes || [];
    }
  }, [voteData]);

  // 1초 폴링 & 버전 체크는 기존 코드 동일 ---------------------------
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
        .eq('vote_category', 'birthday')
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
            id: data.id,
            vote_category: data.vote_category,
            title: data.title,
            start_at: data.start_at,
            stop_at: data.stop_at,
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
    async function checkVersion() {
      try {
        const res = await fetch('/api/version');
        const json = await res.json();
        if (version && version !== json.version) {
          window.location.reload();
        } else {
          setVersion(json.version);
        }
      } catch (err) {
        console.error('버전 체크 실패:', err);
      }
    }

    checkVersion();
    const versionInterval = setInterval(checkVersion, 30000);
    return () => clearInterval(versionInterval);
  }, [version]);

  // --------------------- 여기서부터 레이아웃 코드 ----------------------
  return (
    <div className={styles.container}>
      <div className={styles.content}>
        {/* 왼쪽: 투표 현황 */}
        <div className={styles.rankingSection}>
          <div className={styles.rankingList}>
            {/* 1등 */}
            {voteData?.topThree?.[0] && (
              <div className={styles.rankItem}>
                <div className={styles.rankImage}>
                  <Image
                    src='/images/1st.svg'
                    alt='1st'
                    width={48}
                    height={48}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[0].id}
                    rank={1}
                    name={voteData?.topThree[0].artist?.name['en'] || ''}
                    votes={voteData?.topThree[0].vote_total}
                    logoUrl={voteData?.topThree[0].artist?.artist_group?.image}
                    photoUrl={voteData?.topThree[0].artist?.image}
                  />
                  <motion.div
                    className={styles.voteCount}
                    initial={{ scale: 1 }}
                    animate={{
                      scale:
                        voteData?.topThree[0].vote_total !==
                        prevVotes.current[0]
                          ? 1.3
                          : 1,
                    }}
                    transition={{ duration: 0.2 }}
                  >
                    {voteData?.topThree[0].vote_total.toLocaleString()}
                  </motion.div>
                </div>
              </div>
            )}

            {/* 2등 */}
            {voteData?.topThree?.[1] && (
              <div className={styles.rankItem}>
                <div className={styles.rankImage}>
                  <Image
                    src='/images/2nd.svg'
                    alt='2nd'
                    width={48}
                    height={48}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[1].id}
                    rank={2}
                    name={voteData?.topThree[1].artist?.name['en'] || ''}
                    votes={voteData?.topThree[1].vote_total}
                    logoUrl={voteData?.topThree[1].artist?.artist_group?.image}
                    photoUrl={voteData?.topThree[1].artist?.image}
                  />
                  <motion.div className={styles.voteCount}>
                    {voteData?.topThree[1].vote_total.toLocaleString()}
                  </motion.div>
                </div>
                {/* 2, 3등에는 이름 표시 없음 */}
              </div>
            )}

            {/* 3등 */}
            {voteData?.topThree?.[2] && (
              <div className={styles.rankItem}>
                <div className={styles.rankImage}>
                  <Image
                    src='/images/3rd.svg'
                    alt='3rd'
                    width={48}
                    height={48}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[2].id}
                    rank={3}
                    name={voteData?.topThree[2].artist?.name['en'] || ''}
                    votes={voteData?.topThree[2].vote_total}
                    logoUrl={voteData?.topThree[2].artist?.artist_group?.image}
                    photoUrl={voteData?.topThree[2].artist?.image}
                  />
                  <motion.div className={styles.voteCount}>
                    {voteData?.topThree[2].vote_total.toLocaleString()}
                  </motion.div>
                </div>
                {/* 2, 3등에는 이름 표시 없음 */}
              </div>
            )}
          </div>

          {/* 타이틀 */}
          <div className={styles.title}>
            {/* 하단 타이틀 영역을 가로 배치로 수정 */}
            <div className={styles.titleBottom}>
              {/* QR 코드 */}
              <div className={styles.titleQrCode}>
                <QRCode
                  value={`https://applink.picnic.fan/vote/detail/${voteData?.voteInfo?.id}`}
                  size={110}
                />
              </div>
              {/* Realtime 이미지 */}
              <div>
                <Image
                  src='/images/realtime.svg'
                  alt='Realtime'
                  width={116}
                  height={50}
                />
              </div>
              {/* Logo 이미지 */}
              <div>
                <Image
                  src='/images/logo.svg'
                  alt='Logo'
                  width={410}
                  height={90}
                />
              </div>
            </div>
          </div>
        </div>

        {/* 오른쪽: 광고 영역 */}
        <div className={styles.adSection}>
          <video className={styles.adVideo} autoPlay loop muted playsInline>
            <source src='/480_768.mp4' type='video/mp4' />
          </video>
        </div>
      </div>
    </div>
  );
}
