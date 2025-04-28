import { Vote } from '@/types/interfaces';
import { getServerVoteData } from '@/utils/api/serverQueries';

export async function getVoteDetail(id: string): Promise<Vote> {
  try {
    console.log('Fetching vote detail for id:', id);
    const { vote, voteItems, rewards } = await getServerVoteData(Number(id));

    if (!vote) {
      console.error('No data found for vote id:', id);
      throw new Error('Vote not found');
    }

    const voteData = {
      ...vote,
      voteItems,
      rewards
    };

    console.log('Successfully fetched vote detail:', voteData);
    return voteData;
  } catch (error) {
    console.error('Error in getVoteDetail:', error);
    throw error;
  }
} 