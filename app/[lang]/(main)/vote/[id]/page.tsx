import {Suspense} from 'react';
import {Metadata} from 'next';
import {getVoteById} from '@/lib/data-fetching/vote-service';
import { VoteDetail } from '@/components/shared';
import { VoteDetailSkeleton } from '@/components/server';

// 동적 서버 사용을 위한 설정
export const dynamic = 'force-dynamic';

// 메타데이터 동적 생성
export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const resolvedParams = await params;
  const vote = await getVoteById(resolvedParams.id);

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

type VoteDetailPageProps = {
  params: Promise<{
    id: string;
  }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
};

export default async function VoteDetailPage(props: VoteDetailPageProps) {
  const [params] = await Promise.all([
    props.params,
    props.searchParams,
  ]);

  return (
    <Suspense fallback={<VoteDetailSkeleton />}>
      <VoteDetail id={params.id} />
    </Suspense>
  );
}
