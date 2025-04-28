import { notFound } from 'next/navigation';
import VotePageClient from '@/app/[lang]/(main)/vote/VotePageClient';

export async function generateMetadata() {
  return {
    title: 'Vote',
    description: 'Vote page',
  };
}

export default function VotePage() {
  return <VotePageClient />;
}
