'use client';

import { useEffect, useRef, useState } from 'react';
import { supabase } from '@/lib/supabaseClient';
import { RankCard } from '@/components/RankCard';
import type { VoteData, VoteItem } from '@/types/database.types';
import styles from './page.module.css';
import QRCode from 'react-qr-code';
import Image from 'next/image';

// Branch SDK에 대한 간단한 타입 정의 (필요에 따라 확장하세요)
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

export default function HomePage() {
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
    const checkVersion = async () => {
      try {
        console.log('Fetching version...');
        const response = await fetch('/api/version');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const { hash } = await response.json();

        console.log('currentHashRef', currentHashRef.current);
        console.log('hash', hash);

        if (currentHashRef.current === 'dev') {
          currentHashRef.current = hash;
        } else if (hash !== currentHashRef.current) {
          window.location.reload();
        }
      } catch (error) {
        console.error('버전 체크 중 오류 발생:', {
          message: (error as Error).message,
          stack: (error as Error).stack,
          url: '/api/version',
        });
      }
    };

    checkVersion();
    const versionInterval = setInterval(checkVersion, 60000);
    return () => clearInterval(versionInterval);
  }, []);

  // Branch SDK 초기화 (최초 한 번만 - 동적 import 사용)
  useEffect(() => {
    if (typeof window !== 'undefined') {
      (async () => {
        const branchModule = await import('branch-sdk');
        const branch = branchModule.default as BranchSDK;
        if (process.env.NEXT_PUBLIC_BRANCH_KEY) {
          branch.init(process.env.NEXT_PUBLIC_BRANCH_KEY);
          setBranchInstance(branch);
        } else {
          console.error('NEXT_PUBLIC_BRANCH_KEY가 정의되어 있지 않습니다.');
        }
      })();
    }
  }, []);

  // voteData 업데이트시 준비된 Branch 인스턴스를 통한 Short URL 생성
  useEffect(() => {
    if (voteData?.voteInfo?.id && branchInstance) {
      // 같은 vote id에 대해 중복 호출 방지
      if (lastVoteIdRef.current === voteData.voteInfo.id) return;
      lastVoteIdRef.current = voteData.voteInfo.id;
      branchInstance.link(
        {
          data: {
            $canonical_url: `https://applink.picnic.fan/vote/detail/${voteData.voteInfo?.id}`,
            $desktop_url: `https://applink.picnic.fan/vote/detail/${voteData.voteInfo?.id}`,
            $og_title: voteData.voteInfo?.title['en'] || '',
            $og_description: '투표 결과 확인하기',
          },
        },
        (err, link) => {
          if (err) {
            console.error('Branch short URL 생성 오류:', err);
          } else {
            setShortUrl(link || '');
            console.log('link', link);
          }
        },
      );
    }
  }, [voteData?.voteInfo?.id, voteData?.voteInfo?.title, branchInstance]);

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
                  {/* 2, 3등에는 이름 표시 없음 */}
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
                  {/* 2, 3등에는 이름 표시 없음 */}
                </div>
              </div>
            )}
          </div>

          {/* 타이틀 */}
          <div className={styles.titleBottom}>
            {/* 버전 정보 */}
            {/* <div className={styles.versionInfo}>
              v.{currentHash.slice(0, 7)}
            </div> */}
            {/* QR 코드 */}
            <div className={styles.titleQrCode}>
              <QRCode
                value={
                  // shortUrl가 존재하면 shortUrl, 아니면 기존 URL 사용
                  shortUrl ||
                  `https://applink.picnic.fan/vote/detail/${voteData?.voteInfo?.id}`
                }
                size={110}
              />
            </div>
            {/* Realtime 이미지 */}
            <div>
              <Image
                src='/images/realtime.svg'
                alt='Realtime'
                width={116}
                height={42}
              />
            </div>
            {/* 로고 */}
            <div>
              <Image
                src='/images/logo.svg'
                alt='Realtime'
                width={410}
                height={90} // height 추가 필요
              />
            </div>
          </div>
        </div>

        {/* 오른쪽: 광고 영역 */}
        <div className={styles.adSection}>
          <video className={styles.adVideo} autoPlay loop muted playsInline>
            <source src='/videos/picnic.mp4' type='video/mp4' />
          </video>
        </div>
      </div>
    </div>
  );
}
