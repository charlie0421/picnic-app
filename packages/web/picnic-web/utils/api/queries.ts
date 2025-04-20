import { supabase } from './supabase';
import { Banner, Reward, Vote } from '@/types/interfaces';

// 투표 데이터 가져오기
export const getVotes = async (sortBy: 'votes' | 'recent' = 'votes'): Promise<Vote[]> => {
  try {
    const now = new Date();
    const currentTime = now.toISOString();

    const { data: voteData, error: voteError } = await supabase
      .from('vote')
      .select(`
        *,
        vote_item (
          *,
          artist (
            *
          )
        )
      `)
      .is('deleted_at', null)
      .lte('start_at', currentTime)
      .gte('stop_at', currentTime)
      .order('created_at', { ascending: false });

    if (voteError) throw voteError;
    if (!voteData || voteData.length === 0) return [];

    return voteData.map(vote => ({
      ...vote,
      deletedAt: vote.deleted_at,
      startAt: vote.start_at,
      stopAt: vote.stop_at,
      createdAt: vote.created_at,
      updatedAt: vote.updated_at,
      mainImage: vote.main_image,
      resultImage: vote.result_image,
      waitImage: vote.wait_image,
      voteCategory: vote.vote_category,
      voteContent: vote.vote_content,
      voteSubCategory: vote.vote_sub_category,
      visibleAt: vote.visible_at,
      voteItems: vote.vote_item,
      title: vote.title?.ko || vote.title || '제목 없음'
    }));
  } catch (error) {
    console.error('투표 데이터를 가져오는 중 오류가 발생했습니다:', error);
    return [];
  }
};

// 리워드 데이터 가져오기
export const getRewards = async (): Promise<Reward[]> => {
  try {
    const { data: rewardData, error: rewardError } = await supabase
      .from('reward')
      .select('*')
      .is('deleted_at', null)
      .order('order', { ascending: true })
      .limit(4);

    if (rewardError) throw rewardError;
    if (!rewardData || rewardData.length === 0) return [];

    return rewardData.map(reward => ({
      ...reward,
      deletedAt: reward.deleted_at,
      createdAt: reward.created_at,
      updatedAt: reward.updated_at,
      locationImages: reward.location_images,
      overviewImages: reward.overview_images,
      sizeGuide: reward.size_guide,
      sizeGuideImages: reward.size_guide_images
    }));
  } catch (error) {
    console.error('리워드 데이터를 가져오는 중 오류가 발생했습니다:', error);
    return [];
  }
};

// 배너 데이터 가져오기
export const getBanners = async (): Promise<Banner[]> => {
  try {
    const now = new Date();
    const currentTime = now.toISOString();

    const { data: bannerData, error: bannerError } = await supabase
      .from('banner')
      .select('*')
      .is('deleted_at', null)
      .order('order', { ascending: true })
      .lte('start_at', currentTime)
      .limit(2);

    if (bannerError) throw bannerError;
    if (!bannerData || bannerData.length === 0) return [];

    return bannerData.map(banner => ({
      ...banner,
      deletedAt: banner.deleted_at,
      createdAt: banner.created_at,
      updatedAt: banner.updated_at,
      startAt: banner.start_at,
      endAt: banner.end_at,
      celebId: banner.celeb_id
    }));
  } catch (error) {
    console.error('배너 데이터를 가져오는 중 오류가 발생했습니다:', error);
    return [];
  }
}; 