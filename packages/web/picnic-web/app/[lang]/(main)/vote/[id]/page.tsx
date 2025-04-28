import { Suspense } from 'react';
import { getServerVoteData } from '@/utils/api/serverQueries';
import VoteDetailContent from '@/components/features/vote/VoteDetailContent';
import VoteDetailSkeleton from '@/components/features/vote/VoteDetailSkeleton';
import { Metadata } from 'next';
import { Vote } from '@/types/interfaces';

// 메타데이터 동적 생성
export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const { vote } = await getServerVoteData(Number(params.id));

  if (!vote) {
    return {
      title: '투표 - 정보 없음',
      description: '해당 투표를 찾을 수 없습니다.',
    };
  }

  let title: string;
  if (typeof vote.title === 'string') {
    title = vote.title;
  } else if (vote.title && typeof vote.title === 'object') {
    const titleObj = vote.title as { ko?: string; en?: string };
    title = titleObj.ko || titleObj.en || '투표';
  } else {
    title = '투표';
  }

  return {
    title: `${title} - 피크닉 투표`,
    description:
      vote.voteContent || '피크닉에서 좋아하는 아티스트에게 투표해보세요!',
    openGraph: {
      title: `${title} - 피크닉 투표`,
      description:
        vote.voteContent || '피크닉에서 좋아하는 아티스트에게 투표해보세요!',
      images: vote.mainImage
        ? [`https://cdn.picnic.fan/${vote.mainImage}`]
        : undefined,
    },
  };
}

// 자주 방문하는 투표 페이지의 정적 경로 생성
export async function generateStaticParams() {
  // 인기 있는 투표 ID만 미리 생성 (최대 10개)
  // 실제 구현에서는 DB에서 가장 인기 있는 투표 ID를 가져오는 로직으로 대체
  return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((id) => ({
    id: id.toString(),
  }));
}

interface VoteDetailPageProps {
  params: {
    id: string;
  };
}

export default async function VoteDetailPage({ params }: VoteDetailPageProps) {
  const initialData = await getServerVoteData(Number(params.id));

  return (
    <Suspense fallback={<VoteDetailSkeleton />}>
      <VoteDetailContent id={params.id} initialData={initialData} />
    </Suspense>
  );
}
