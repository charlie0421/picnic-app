import React, { useState, useEffect, useRef } from 'react';
import { RankCard } from '../components/RankCard';
import { supabase } from '../lib/supabaseClient';
import { VoteItem, VoteData, LocalizedName } from '../../types/database.types';
import styles from './left-sidebar.module.css';
import Image from 'next/image';
import QRCode from 'react-qr-code';

interface BranchSDK {
  init: (key: string) => void;
  link: (
    options: {
      data: {
        $canonical_url: string;
        $desktop_url: string;
        $og_title: string;
        $og_description: string;
      };
    },
    callback: (err: Error | null, link?: string) => void,
  ) => void;
}

export default function LeftSidebarPage() {

  const [voteData, setVoteData] = useState<VoteData>();
  const [shortUrl, setShortUrl] = useState<string>('');
  const lastVoteIdRef = useRef<string>('');
  const currentHashRef = useRef<string>('dev');
  const prevVotes = useRef<number[]>([]);
  const [branchInstance, setBranchInstance] = useState<BranchSDK | null>(null);

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


  return (
    <div style={{ height: '100vh', overflow: 'auto' }}>
        <div className={styles.rankingSection}>
          <div className={styles.rankingList}>
            {/* 1등 */}
            {voteData?.topThree?.[0] && (
              <div className={styles.rankItem}>
                <div className={styles.rankImage}>
                  <Image
                    src='/images/1st.svg'
                    alt='1st'
                    width={60}
                    height={50}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[0].id}
                    rank={1}
                    name={voteData?.topThree[0].artist?.name['en'] || ''}
                    votes={voteData?.topThree[0].vote_total}
                    photoUrl={voteData?.topThree[0].artist?.image}
                    groupName={
                      voteData?.topThree[0].artist?.artist_group?.name['en'] ||
                      ''
                    }
                  />
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
                    width={66}
                    height={40}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[1].id}
                    rank={2}
                    name={voteData?.topThree[1].artist?.name['en'] || ''}
                    votes={voteData?.topThree[1].vote_total}
                    photoUrl={voteData?.topThree[1].artist?.image}
                    groupName={
                      voteData?.topThree[1].artist?.artist_group?.name['en'] ||
                      ''
                    }
                  />
                </div>
              </div>
            )}

            {/* 3등 */}
            {voteData?.topThree?.[2] && (
              <div className={styles.rankItem}>
                <div className={styles.rankImage}>
                  <Image
                    src='/images/3rd.svg'
                    alt='3rd'
                    width={45}
                    height={30}
                  />
                </div>
                <div className={styles.rankPillar}>
                  <RankCard
                    key={voteData?.topThree[2].id}
                    rank={3}
                    name={voteData?.topThree[2].artist?.name['en'] || ''}
                    votes={voteData?.topThree[2].vote_total}
                    photoUrl={voteData?.topThree[2].artist?.image}
                    groupName={
                      voteData?.topThree[2].artist?.artist_group?.name['en'] ||
                      ''
                    }
                  />
                </div>
              </div>
            )}
          </div>

          {/* 타이틀 */}
          <div className={styles.titleBottom}>
            {/* QR 코드 */}
            <div className={styles.titleQrCode}>
              <QRCode
                value={
                  // shortUrl가 존재하면 shortUrl, 아니면 기존 URL 사용
                  shortUrl ||
                  `https://applink.picnic.fan/vote/detail/${voteData?.voteInfo?.id}`
                }
                size={60}
              />
            </div>
          </div>
        </div>
    </div>
  );
}
