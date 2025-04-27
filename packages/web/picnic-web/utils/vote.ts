import { VoteItem } from '@/types/interfaces';

export function getTopThreeInOrder(items: VoteItem[]): (VoteItem & { rank: number })[] {
  const sorted = [...items].sort((a, b) => (b.voteTotal || 0) - (a.voteTotal || 0)).slice(0, 3);
  const withRank = sorted.map((item, idx) => ({ ...item, rank: idx + 1 }));
  const rank1 = withRank.find(item => item.rank === 1) || withRank[0];
  const rank2 = withRank.find(item => item.rank === 2) || withRank[1];
  const rank3 = withRank.find(item => item.rank === 3) || withRank[2];
  return [rank2, rank1, rank3].filter(Boolean);
} 